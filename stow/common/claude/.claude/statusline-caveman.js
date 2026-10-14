#!/usr/bin/env node
// Claude Code statusLine — caveman segment, scoped to the current session.
//
// Managed by the dotfiles `claude` package. Invoked by statusline-command.sh,
// which reads the Claude Code status line JSON from stdin exactly once and pipes
// that stored payload here. This script must never read the original stream
// itself and must never be the reason the status line fails: every failure path
// prints nothing and exits 0.
//
// Why this exists: caveman's own statusline script renders
// ~/.claude/.caveman-statusline-suffix, which is the sum of every session ever
// recorded on this machine, across every project. Shown inside a project-scoped
// status line that is exactly the wrong number. See
// docs/prd/0021-caveman-session-scoped-savings.md.
//
// What it renders instead:
//   caveman:full ⛏ 68.3k session          active mode + actual session output
//   caveman:off ⛏ 0 session               caveman installed but disabled
//   caveman:ultra ⛏ 12.5k session         any other active mode
//
// We show actual measured output tokens for this session, not an estimated
// saving. Caveman has no observed non-caveman counterfactual for a session, so
// any fixed-ratio "saved" figure would be a guess dressed up as a measurement.
//
// Future: if Caveman ever exposes measured counterfactual savings (for example
// A/B identical runs or provider-reported baseline-vs-caveman usage), reintroduce
// an exact savings figure here instead of raw output tokens. Until then, output
// tokens are honest and comparable across modes. See ADR 0057 and the upstream
// discussion in the caveman repo about retiring numeric statusline savings.

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

// 256-colour 172 (orange) — matches caveman's own badge and the rtk segment.
const COLOR = '\u001b[38;5;172m';
const RESET = '\u001b[0m';
const PICK = '⛏'; // U+26CF pick, escaped so this file stays pure ASCII

// caveman 2.x attributes tokens per message, so the session cache has to carry
// one record per assistant turn. Past this count we stop caching them rather
// than let a single session's cache file grow without bound; the next render
// then takes the cold path, which is slower but still correct.
const MAX_CACHED_MESSAGES = 20000;

function claudeDir() {
  return process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
}

function cacheRoot() {
  const base = process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache');
  return path.join(base, 'claude-statusline', 'caveman');
}

// Locate caveman's hooks directory. Never hardcoded: Claude Code installs the
// plugin under marketplaces/ (canonical) or cache/<name>/<name>/<hash>/ (a
// versioned checkout whose hash changes per release). Hash directories sort by
// hex rather than by age, so the cache fallback picks the newest by mtime — the
// same rule statusline-command.sh already applies to caveman-statusline.sh.
function findHooksDir() {
  const override = process.env.CAVEMAN_HOOKS_DIR;
  if (override && fs.existsSync(path.join(override, 'caveman-stats.js'))) return override;

  const plugins = path.join(claudeDir(), 'plugins');
  const canonical = path.join(plugins, 'marketplaces', 'caveman', 'src', 'hooks');
  if (fs.existsSync(path.join(canonical, 'caveman-stats.js'))) return canonical;

  const cache = path.join(plugins, 'cache', 'caveman');
  let best = null;
  try {
    for (const outer of fs.readdirSync(cache)) {
      for (const version of fs.readdirSync(path.join(cache, outer))) {
        const dir = path.join(cache, outer, version, 'src', 'hooks');
        let st;
        try { st = fs.statSync(path.join(dir, 'caveman-stats.js')); } catch { continue; }
        if (!best || st.mtimeMs > best.mtime) best = { dir, mtime: st.mtimeMs };
      }
    }
  } catch { /* no cache checkout */ }
  return best ? best.dir : null;
}

// ---------------------------------------------------------------------------
// Mode reading
// ---------------------------------------------------------------------------

// Prefer caveman's own readFlag so we reuse its symlink refusal, 64-byte cap and
// mode whitelist. Degrade to a direct read only when the plugin is not installed.
function readMode() {
  const flagPath = path.join(claudeDir(), '.caveman-active');

  const hooks = findHooksDir();
  if (hooks) {
    try {
      const cfg = require(path.join(hooks, 'caveman-config.js'));
      if (typeof cfg.readFlag === 'function') {
        const mode = cfg.readFlag(flagPath);
        if (mode) return mode;
      }
    } catch { /* fall through to direct read */ }
  }

  try {
    const st = fs.lstatSync(flagPath);
    if (!st.isSymbolicLink() && st.isFile()) {
      const raw = fs.readFileSync(flagPath, 'utf8').trim().toLowerCase();
      if (raw.length > 0 && raw.length <= 64 && /^[a-z0-9_-]+$/.test(raw)) return raw;
    }
  } catch { /* missing or unreadable flag */ }

  return 'off';
}

// ---------------------------------------------------------------------------
// Session totals
// ---------------------------------------------------------------------------

// Accumulate assistant-message usage from raw JSONL text. This mirrors caveman's
// parseSession line-for-line, and exists only so the warm path can parse the
// appended tail instead of the whole file. The cold path calls caveman's own
// parseSession directly, and tests/statusline-caveman.test.js asserts the two
// agree over a real transcript — so this stays a performance detail, not a fork
// of the parser.
//
// `messages` mirrors the per-turn array caveman 2.x's parseSession returns; it
// is what attributeByMode slices by mode. Built unconditionally so the cache
// shape does not depend on which caveman is installed at write time.
function accumulate(raw, acc) {
  if (!Array.isArray(acc.messages)) acc.messages = [];
  for (const line of raw.split('\n')) {
    if (!line.trim()) continue;
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    // `JSON.parse("null")` succeeds and returns null, so the null check has to
    // be separate from the catch. Caveman's parseSession omits it and throws on
    // such a line; sessionTotals guards its call for the same reason.
    if (!entry || entry.type !== 'assistant' || !entry.message) continue;
    const usage = entry.message.usage;
    if (!usage) continue;
    acc.outputTokens += usage.output_tokens || 0;
    acc.cacheReadTokens += usage.cache_read_input_tokens || 0;
    acc.turns++;
    if (!acc.model && entry.message.model) acc.model = entry.message.model;
    const ts = entry.timestamp ? Date.parse(entry.timestamp) : NaN;
    acc.messages.push({
      ts: Number.isFinite(ts) ? ts : null,
      outputTokens: usage.output_tokens || 0,
      cacheReadTokens: usage.cache_read_input_tokens || 0,
    });
  }
  return acc;
}

// Byte offset of the last newline, i.e. the end of the last complete line. A
// transcript being appended to can be read mid-line; everything after this point
// is re-read on the next render rather than parsed as a truncated record.
function lastCompleteOffset(buf, base) {
  const nl = buf.lastIndexOf(0x0a);
  return nl === -1 ? base : base + nl + 1;
}

function readSessionCache(file) {
  try {
    const c = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (!c || typeof c !== 'object') return null;
    if (!Number.isFinite(c.offset) || c.offset < 0) return null;
    if (!Number.isFinite(c.outputTokens) || !Number.isFinite(c.turns)) return null;
    // A cache written before per-message records existed, or one whose messages
    // were dropped for exceeding MAX_CACHED_MESSAGES, cannot be resumed without
    // losing the attribution input. Treat it as cold.
    if (!Array.isArray(c.messages)) return null;
    return c;
  } catch { return null; }
}

function writeJsonAtomic(file, value) {
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
    const tmp = `${file}.${process.pid}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(value), { mode: 0o600 });
    fs.renameSync(tmp, file);
  } catch { /* cache is best-effort */ }
}

function fallbackParseSession(transcript) {
  try {
    const buf = fs.readFileSync(transcript);
    return accumulate(buf.toString('utf8'), {
      outputTokens: 0, cacheReadTokens: 0, turns: 0, model: null, messages: [],
    });
  } catch { return null; }
}

// Parse the current session's transcript, reusing the cached prefix when the
// file has only grown. Falls back to a full parse via caveman's own parseSession
// whenever the cache is cold, invalid, or the file is shorter than the cached
// offset (rewritten, rotated, or a different file at the same path).
function sessionTotals(transcript, sessionId, parseSession) {
  let size;
  try { size = fs.statSync(transcript).size; } catch { return null; }

  const cacheFile = path.join(cacheRoot(), 'sessions', `${sessionId}.json`);
  const cached = readSessionCache(cacheFile);

  let acc;
  if (cached && cached.offset <= size) {
    acc = {
      outputTokens: cached.outputTokens,
      cacheReadTokens: cached.cacheReadTokens || 0,
      turns: cached.turns,
      model: cached.model || null,
      messages: cached.messages,
    };
    if (cached.offset < size) {
      let buf;
      let fd;
      try {
        fd = fs.openSync(transcript, 'r');
        const len = size - cached.offset;
        buf = Buffer.alloc(len);
        fs.readSync(fd, buf, 0, len, cached.offset);
      } catch { return null; } finally {
        if (fd !== undefined) { try { fs.closeSync(fd); } catch { /* ignore */ } }
      }
      const end = lastCompleteOffset(buf, cached.offset);
      if (end > cached.offset) {
        accumulate(buf.subarray(0, end - cached.offset).toString('utf8'), acc);
      }
      acc.offset = end;
    } else {
      acc.offset = cached.offset;
    }
  } else {
    // Cold path: caveman's own parser when available, otherwise a local parse.
    let parsed;
    if (typeof parseSession === 'function') {
      try { parsed = parseSession(transcript); } catch { parsed = null; }
    }
    if (!parsed) parsed = fallbackParseSession(transcript);
    if (!parsed) return null;
    acc = { ...parsed };
    let buf;
    try { buf = fs.readFileSync(transcript); } catch { return null; }
    // caveman 1.x parseSession has no `messages`; rebuild it here so later
    // code gets the same shape regardless of installed version.
    if (!Array.isArray(acc.messages)) {
      const rebuilt = accumulate(buf.toString('utf8'), {
        outputTokens: 0, cacheReadTokens: 0, turns: 0, model: null, messages: [],
      });
      acc.messages = rebuilt.messages;
    }
    acc.offset = lastCompleteOffset(buf, 0);
  }

  writeJsonAtomic(cacheFile, {
    offset: acc.offset,
    outputTokens: acc.outputTokens,
    cacheReadTokens: acc.cacheReadTokens,
    turns: acc.turns,
    model: acc.model,
    // Omitted past the cap — readSessionCache then rejects the entry and the
    // next render reparses in full rather than resuming with partial messages.
    messages: acc.messages.length <= MAX_CACHED_MESSAGES ? acc.messages : undefined,
  });
  return acc;
}

// ---------------------------------------------------------------------------
// Render
// ---------------------------------------------------------------------------

function humanizeTokensFallback(n) {
  if (!Number.isFinite(n) || n < 0) n = 0;
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 10_000) return `${Math.round(n / 1_000)}k`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
  return String(n);
}

function render({ mode, outputTokens, humanizeTokens }) {
  const fmt = typeof humanizeTokens === 'function' ? humanizeTokens : humanizeTokensFallback;
  return `${COLOR}caveman:${mode} ${PICK} ${fmt(outputTokens)} session${RESET}`;
}

function readStdin() {
  try { return fs.readFileSync(0, 'utf8'); } catch { return ''; }
}

function main() {
  const mode = readMode();

  let payload;
  try { payload = JSON.parse(readStdin()); } catch { payload = null; }

  let outputTokens = 0;
  if (payload && typeof payload === 'object') {
    const sessionId = typeof payload.session_id === 'string' ? payload.session_id : null;
    const transcript = typeof payload.transcript_path === 'string' ? payload.transcript_path : null;
    if (transcript && sessionId) {
      const hooks = findHooksDir();
      let parseSession;
      if (hooks) {
        try { parseSession = require(path.join(hooks, 'caveman-stats.js')).parseSession; } catch { /* ignore */ }
      }
      const totals = sessionTotals(transcript, sessionId, parseSession || fallbackParseSession);
      if (totals) outputTokens = totals.outputTokens || 0;
    }
  }

  const hooks = findHooksDir();
  let humanizeTokens;
  if (hooks) {
    try { humanizeTokens = require(path.join(hooks, 'caveman-stats.js')).humanizeTokens; } catch { /* ignore */ }
  }

  process.stdout.write(render({ mode, outputTokens, humanizeTokens }));
}

if (require.main === module) {
  try { main(); } catch { /* the status line must never fail because of this segment */ }
}

module.exports = {
  accumulate, lastCompleteOffset,
  sessionTotals, render, readMode, cacheRoot, findHooksDir,
  fallbackParseSession, humanizeTokensFallback, MAX_CACHED_MESSAGES,
};
