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
//   [CAVEMAN] ⛏ 68.3k                    session only
//   [CAVEMAN] ⛏ 68.3k sess · 844.7k repo   session + repository
//   [CAVEMAN:ULTRA]                       mode without benchmark data
//   [CAVEMAN:OFF]                         installed, no mode active
//   (nothing)                             not installed, or anything went wrong
//
// Token estimation is caveman's, reused verbatim via its exported deriveSavings.
// We never re-implement the algorithm; see ADR 0057.
//
// deriveSavings changed shape in caveman 2.0. v1 took a single mode for the
// whole session; v2 takes tokens already bucketed per mode, because a session
// can switch modes partway through and crediting all of it to the current flag
// invents savings. Both shapes are supported — see deriveSessionSavings.

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

// 256-colour 172 (orange) — matches caveman's own badge and the rtk segment.
const COLOR = '\u001b[38;5;172m';
const RESET = '\u001b[0m';
const PICK = '⛏'; // U+26CF pick, escaped so this file stays pure ASCII

// Ledger entries older than this are pruned opportunistically, so a long-lived
// cache cannot grow without bound.
const LEDGER_MAX_AGE_MS = 90 * 24 * 60 * 60 * 1000;

// caveman 2.x attributes tokens per message, so the session cache has to carry
// one record per assistant turn. Past this count we stop caching them rather
// than let a single session's cache file grow without bound; the next render
// then takes the cold path, which is slower but still correct.
const MAX_CACHED_MESSAGES = 20000;

// Where caveman 2.x records mode transitions. Read from caveman's own
// MODE_LOG_BASENAME when it exports one; this is only the fallback.
const MODE_LOG_BASENAME = '.caveman-mode-log.jsonl';

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
// Session totals
// ---------------------------------------------------------------------------

// Accumulate assistant-message usage from raw JSONL text. This mirrors caveman's
// parseSession line-for-line, and exists only so the warm path can parse the
// appended tail instead of the whole file. The cold path calls caveman's
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
    // Cold path: caveman's own parser, verbatim. Guarded because it dereferences
    // every parsed line without a null check and so throws on a transcript
    // containing a bare `null` record.
    let parsed;
    try { parsed = parseSession(transcript); } catch { parsed = null; }
    if (!parsed) return null;
    acc = { ...parsed };
    let buf;
    try { buf = fs.readFileSync(transcript); } catch { return null; }
    // caveman 1.x parseSession has no `messages`; rebuild it here so the v2
    // attribution path gets the same input regardless of installed version.
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
// Savings
// ---------------------------------------------------------------------------

// Call caveman's deriveSavings through whichever contract the installed copy
// exposes, and return estimated saved tokens (0 when there is nothing to claim).
//
// Detection is by capability, not by version string: caveman ships no version to
// the hooks, and `typeof deriveSavings === 'function'` is true for both shapes —
// so passing v1 arguments to v2 silently yields 0 rather than throwing. That
// silent zero is exactly the failure this function exists to prevent, which is
// why the probe keys on attributeByMode/readModeLog, added alongside the new
// signature in caveman 2.0.
function deriveSessionSavings({ cav, mode, totals, modeLogPath, flagMtimeMs }) {
  if (!cav || typeof cav.deriveSavings !== 'function') return 0;

  const positive = (result) => {
    const n = result && result.estSavedTokens;
    return Number.isFinite(n) && n > 0 ? n : 0;
  };

  const v2 = typeof cav.attributeByMode === 'function' && typeof cav.readModeLog === 'function';

  try {
    if (v2) {
      // Tokens are credited to the mode that was active when each message was
      // written, so a session that switched modes partway does not report the
      // current mode's ratio over its whole history.
      let modeLog = [];
      try { modeLog = cav.readModeLog(modeLogPath) || []; } catch { modeLog = []; }
      const attribution = cav.attributeByMode({
        messages: totals.messages || [],
        modeLog,
        mode,
        flagMtimeMs,
        outputTokens: totals.outputTokens,
      });
      const byMode = (attribution && attribution.byMode) || {};
      return positive(cav.deriveSavings({ byMode, model: totals.model }));
    }
    return positive(cav.deriveSavings({
      outputTokens: totals.outputTokens, mode, model: totals.model,
    }));
  } catch {
    return 0; // a moved seam renders a bare badge, never a wrong number
  }
}

// ---------------------------------------------------------------------------
// Project identity
// ---------------------------------------------------------------------------

function canonical(dir) {
  if (!dir) return null;
  try { return fs.realpathSync(dir); } catch { /* deleted or moved */ }
  try { return path.resolve(dir); } catch { return null; }
}

// git@host:owner/name.git and https://host/owner/name.git both normalise to
// host/owner/name, so a repository has one identity regardless of clone URL.
function normalizeRemote(url) {
  if (typeof url !== 'string' || !url) return null;
  let m = /^[a-z+]+:\/\/(?:[^@/]*@)?([^/:]+)(?::\d+)?\/(.+?)(?:\.git)?\/?$/i.exec(url.trim());
  if (!m) m = /^(?:[^@]+@)?([^:/]+):(.+?)(?:\.git)?\/?$/.exec(url.trim());
  if (!m) return null;
  const host = m[1].toLowerCase();
  const repoPath = m[2].replace(/^\/+/, '').toLowerCase();
  if (!host || !repoPath) return null;
  return `${host}/${repoPath}`;
}

function git(cwd, args) {
  try {
    return execFileSync('git', ['-C', cwd, ...args], {
      encoding: 'utf8', timeout: 1500, stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch { return null; }
}

// Identity resolution, in preference order. Remote-derived identity wins so two
// clones or two worktrees of one repository aggregate together — which is what
// "savings for this repository" should mean. It is never required: the path
// chain keeps the feature working outside git and in remote-less repositories.
function projectIdentity(payload) {
  const ws = payload.workspace || {};
  const cwd = ws.current_dir || payload.cwd || null;

  const repo = ws.repo;
  if (repo && repo.host && repo.owner && repo.name) {
    return `${repo.host}/${repo.owner}/${repo.name}`.toLowerCase();
  }

  if (cwd) {
    const remote = normalizeRemote(git(cwd, ['remote', 'get-url', 'origin']));
    if (remote) return remote;

    const top = git(cwd, ['rev-parse', '--show-toplevel']);
    const topReal = canonical(top);
    if (topReal) return `path:${topReal}`;
  }

  const project = canonical(ws.project_dir);
  if (project) return `path:${project}`;

  const current = canonical(cwd);
  if (current) return `path:${current}`;

  return null;
}

// ---------------------------------------------------------------------------
// Repository ledger
// ---------------------------------------------------------------------------

// One file per session, rewritten in place. Double-counting is structurally
// impossible: a session owns exactly one file, so there is no snapshot-versus-
// final ambiguity and no latest-per-session reduction to get wrong. See ADR 0058.
function updateLedger(identity, sessionId, estSavedTokens) {
  if (!identity || !sessionId) return null;
  const hash = crypto.createHash('sha1').update(identity).digest('hex').slice(0, 16);
  const dir = path.join(cacheRoot(), 'repos', hash);
  const self = path.join(dir, `${sessionId}.json`);

  // Skip the write when nothing changed — most renders do not move the number.
  const prev = (() => {
    try { return JSON.parse(fs.readFileSync(self, 'utf8')); } catch { return null; }
  })();
  if (!prev || prev.est_saved_tokens !== estSavedTokens) {
    writeJsonAtomic(self, {
      ts: Date.now(),
      session_id: sessionId,
      project: identity,
      est_saved_tokens: estSavedTokens,
    });
  }

  let total = 0;
  const cutoff = Date.now() - LEDGER_MAX_AGE_MS;
  let names;
  try { names = fs.readdirSync(dir); } catch { return null; }
  for (const name of names) {
    if (!name.endsWith('.json')) continue;
    const file = path.join(dir, name);
    let entry;
    try { entry = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { continue; }
    if (!entry || typeof entry !== 'object') continue;
    const ts = Number(entry.ts);
    if (Number.isFinite(ts) && ts < cutoff && name !== `${sessionId}.json`) {
      try { fs.unlinkSync(file); } catch { /* best-effort prune */ }
      continue;
    }
    const saved = Number(entry.est_saved_tokens);
    if (Number.isFinite(saved) && saved > 0) total += saved;
  }
  return total;
}

// ---------------------------------------------------------------------------
// Render
// ---------------------------------------------------------------------------

function badge(mode) {
  if (mode === 'full') return '[CAVEMAN]';
  return `[CAVEMAN:${mode.toUpperCase()}]`;
}

function render({ mode, sessionSaved, repoSaved, humanizeTokens }) {
  let out = badge(mode);
  if (sessionSaved > 0) {
    if (repoSaved > sessionSaved) {
      out += ` ${PICK} ${humanizeTokens(sessionSaved)} sess · ${humanizeTokens(repoSaved)} repo`;
    } else {
      out += ` ${PICK} ${humanizeTokens(sessionSaved)}`;
    }
  }
  return COLOR + out + RESET;
}

function readStdin() {
  try { return fs.readFileSync(0, 'utf8'); } catch { return ''; }
}

function main() {
  const hooks = findHooksDir();
  if (!hooks) return; // caveman not installed — render nothing, as before

  // Whole modules, not destructured functions: deriveSessionSavings probes for
  // members that only exist in caveman 2.x, so it needs the namespace.
  let cfg, cav;
  try {
    cfg = require(path.join(hooks, 'caveman-config.js'));
    cav = require(path.join(hooks, 'caveman-stats.js'));
  } catch { return; }
  const { readFlag } = cfg;
  const { parseSession, deriveSavings, humanizeTokens } = cav;
  if (typeof readFlag !== 'function' || typeof parseSession !== 'function' ||
      typeof deriveSavings !== 'function' || typeof humanizeTokens !== 'function') {
    return; // upstream moved the seam — degrade to silence, never to a wrong number
  }

  // readFlag enforces caveman's own symlink refusal, 64-byte cap and mode
  // whitelist. Never re-implement that check; never echo the raw file.
  const flagPath = path.join(claudeDir(), '.caveman-active');
  const mode = readFlag(flagPath);
  if (!mode || mode === 'off') {
    process.stdout.write(`${COLOR}[CAVEMAN:OFF]${RESET}`);
    return;
  }

  let payload;
  try { payload = JSON.parse(readStdin()); } catch { payload = null; }
  if (!payload || typeof payload !== 'object') {
    process.stdout.write(`${COLOR}${badge(mode)}${RESET}`);
    return;
  }

  const sessionId = typeof payload.session_id === 'string' ? payload.session_id : null;
  const transcript = typeof payload.transcript_path === 'string' ? payload.transcript_path : null;

  let sessionSaved = 0;
  if (transcript && sessionId) {
    const totals = sessionTotals(transcript, sessionId, parseSession);
    if (totals && totals.turns > 0) {
      // caveman 2.x dates mode changes against the flag file's mtime when it has
      // no transition log to work from, so this has to be the real flag's mtime.
      let flagMtimeMs = null;
      try { flagMtimeMs = fs.statSync(flagPath).mtimeMs; } catch { /* flag gone */ }

      // deriveSavings has benchmark data for 'full' only; every other mode
      // legitimately yields 0 and renders as a bare badge.
      sessionSaved = deriveSessionSavings({
        cav, mode, totals, flagMtimeMs,
        modeLogPath: path.join(claudeDir(), cfg.MODE_LOG_BASENAME || MODE_LOG_BASENAME),
      });
    }
  }

  let repoSaved = 0;
  if (sessionSaved > 0) {
    const total = updateLedger(projectIdentity(payload), sessionId, sessionSaved);
    if (Number.isFinite(total) && total > 0) repoSaved = total;
  }

  process.stdout.write(render({ mode, sessionSaved, repoSaved, humanizeTokens }));
}

if (require.main === module) {
  try { main(); } catch { /* the status line must never fail because of this segment */ }
}

module.exports = {
  accumulate, lastCompleteOffset, normalizeRemote, projectIdentity,
  updateLedger, sessionTotals, render, badge, cacheRoot, findHooksDir,
  deriveSessionSavings, MAX_CACHED_MESSAGES, MODE_LOG_BASENAME,
};
