#!/usr/bin/env node
// Tests for the status line's caveman segment.
//
//   node --test stow/common/claude/tests/statusline-caveman.test.js
//   task test:statusline
//
// Every test redirects XDG_CACHE_HOME into a temp dir, so nothing here touches
// the real status line cache, the real caveman state files, or $HOME. Tests that
// need caveman's own modules skip themselves when the plugin is not installed,
// so the suite passes on a machine without it (including CI).

'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const SEGMENT = path.join(__dirname, '..', '.claude', 'statusline-caveman.js');
const SCRIPT = path.join(__dirname, '..', '.claude', 'statusline-command.sh');

// Each test gets its own cache root; require() the segment fresh so cacheRoot()
// picks up the redirected XDG_CACHE_HOME.
function withCache(fn) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'sl-caveman-'));
  const prev = process.env.XDG_CACHE_HOME;
  process.env.XDG_CACHE_HOME = dir;
  delete require.cache[require.resolve(SEGMENT)];
  try {
    return fn(require(SEGMENT), dir);
  } finally {
    if (prev === undefined) delete process.env.XDG_CACHE_HOME;
    else process.env.XDG_CACHE_HOME = prev;
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function caveman() {
  const seg = require(SEGMENT);
  const hooks = seg.findHooksDir();
  if (!hooks) return null;
  try { return require(path.join(hooks, 'caveman-stats.js')); } catch { return null; }
}

// Timestamps are real: caveman 2.x slices a session by them to attribute tokens
// to the mode that was active at the time, so a transcript without them would
// exercise only the degraded path.
const T0 = Date.parse('2026-01-01T00:00:00.000Z');

function transcript(dir, turns) {
  const file = path.join(dir, 'session.jsonl');
  const lines = turns.map((t, i) => JSON.stringify({
    type: 'assistant',
    timestamp: new Date(t.ts != null ? t.ts : T0 + i * 60000).toISOString(),
    message: { model: t.model || 'claude-opus-5', usage: { output_tokens: t.out, cache_read_input_tokens: 0 } },
  }));
  // Interleave non-assistant noise — the parser must ignore it.
  lines.splice(1, 0, JSON.stringify({ type: 'user', message: { content: 'hi' } }));
  fs.writeFileSync(file, lines.join('\n') + '\n');
  return file;
}

describe('accumulate', () => {
  test('sums assistant output tokens and ignores everything else', () => {
    const seg = require(SEGMENT);
    const raw = [
      JSON.stringify({ type: 'assistant', message: { model: 'm', usage: { output_tokens: 10 } } }),
      JSON.stringify({ type: 'user', message: { content: 'x' } }),
      JSON.stringify({ type: 'assistant', message: { usage: { output_tokens: 5 } } }),
      JSON.stringify({ type: 'assistant' }),
      'not json at all',
      '',
    ].join('\n');
    const acc = seg.accumulate(raw, { outputTokens: 0, cacheReadTokens: 0, turns: 0, model: null });
    assert.equal(acc.outputTokens, 15);
    assert.equal(acc.turns, 2);
    assert.equal(acc.model, 'm');
  });

  test('malformed lines never throw', () => {
    const seg = require(SEGMENT);
    const acc = seg.accumulate('{\n{"type":\nnull\n[]\n', { outputTokens: 0, cacheReadTokens: 0, turns: 0, model: null });
    assert.equal(acc.outputTokens, 0);
    assert.equal(acc.turns, 0);
    assert.deepEqual(acc.messages, []);
  });

  test('records one dated message per turn for mode attribution', () => {
    const seg = require(SEGMENT);
    const raw = [
      JSON.stringify({ type: 'assistant', timestamp: '2026-01-01T00:00:00.000Z', message: { usage: { output_tokens: 10 } } }),
      JSON.stringify({ type: 'user', message: { content: 'x' } }),
      JSON.stringify({ type: 'assistant', message: { usage: { output_tokens: 5 } } }),
      JSON.stringify({ type: 'assistant', timestamp: 'not a date', message: { usage: { output_tokens: 1 } } }),
    ].join('\n');
    const acc = seg.accumulate(raw, { outputTokens: 0, cacheReadTokens: 0, turns: 0, model: null });
    assert.deepEqual(acc.messages, [
      { ts: Date.parse('2026-01-01T00:00:00.000Z'), outputTokens: 10 },
      { ts: null, outputTokens: 5 },
      { ts: null, outputTokens: 1 },
    ]);
    // The per-message tokens must reconcile with the total, or attribution
    // would credit a different number than the badge reports.
    assert.equal(acc.messages.reduce((s, m) => s + m.outputTokens, 0), acc.outputTokens);
  });
});

describe('incremental parse equivalence', () => {
  // The load-bearing claim of the cache: the warm tail path must produce exactly
  // what caveman's own parseSession produces over the whole file. If caveman
  // changes its parser, this fails and we find out from a test rather than from
  // a wrong number on screen.
  test('warm path matches caveman parseSession', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');

    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }, { out: 250 }]);
      const sid = 'sess-equiv';

      const cold = seg.sessionTotals(file, sid, cav.parseSession);
      assert.equal(cold.outputTokens, 350);

      // Append two more turns; the warm path reads only the new bytes.
      fs.appendFileSync(file, [
        JSON.stringify({ type: 'assistant', message: { model: 'claude-opus-5', usage: { output_tokens: 7 } } }),
        JSON.stringify({ type: 'assistant', message: { model: 'claude-opus-5', usage: { output_tokens: 3 } } }),
      ].join('\n') + '\n');

      const warm = seg.sessionTotals(file, sid, cav.parseSession);
      const truth = cav.parseSession(file);
      assert.equal(warm.outputTokens, truth.outputTokens, 'output tokens diverged');
      assert.equal(warm.turns, truth.turns, 'turn count diverged');
      assert.equal(warm.model, truth.model, 'model diverged');
      assert.equal(warm.outputTokens, 360);

      // caveman 2.x only: the per-message array feeds attributeByMode, so it has
      // to match upstream exactly, not merely sum to the same total.
      if (Array.isArray(truth.messages)) {
        assert.deepEqual(warm.messages, truth.messages, 'per-message records diverged');
      }
    });
  });

  test('per-message records survive the warm path and reconcile', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');

    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }, { out: 250 }]);
      const sid = 'sess-messages';

      const cold = seg.sessionTotals(file, sid, cav.parseSession);
      assert.equal(cold.messages.length, 2);

      fs.appendFileSync(file, JSON.stringify({
        type: 'assistant',
        timestamp: '2026-01-01T01:00:00.000Z',
        message: { model: 'claude-opus-5', usage: { output_tokens: 40 } },
      }) + '\n');

      const warm = seg.sessionTotals(file, sid, cav.parseSession);
      assert.equal(warm.messages.length, 3, 'warm path lost or duplicated messages');
      assert.equal(warm.messages.reduce((s, m) => s + m.outputTokens, 0), warm.outputTokens);
      assert.equal(warm.messages[2].ts, Date.parse('2026-01-01T01:00:00.000Z'));
    });
  });

  test('a cache without per-message records is treated as cold', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');

    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }, { out: 250 }]);
      const sid = 'sess-legacy-cache';
      seg.sessionTotals(file, sid, cav.parseSession);

      // A cache file written by the pre-shim version of this script.
      const cacheFile = path.join(seg.cacheRoot(), 'sessions', `${sid}.json`);
      const legacy = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
      delete legacy.messages;
      fs.writeFileSync(cacheFile, JSON.stringify(legacy));

      const out = seg.sessionTotals(file, sid, cav.parseSession);
      assert.equal(out.outputTokens, 350, 'totals must survive the reparse');
      assert.equal(out.messages.length, 2, 'messages must be rebuilt, not left empty');
    });
  });

  test('a truncated trailing line is not double counted', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');

    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }]);
      const sid = 'sess-partial';
      seg.sessionTotals(file, sid, cav.parseSession);

      // Simulate reading while Claude Code is mid-write: a record without its
      // terminating newline. It must be ignored now and counted exactly once
      // after the newline lands.
      fs.appendFileSync(file, JSON.stringify({
        type: 'assistant', message: { model: 'claude-opus-5', usage: { output_tokens: 42 } },
      }));
      assert.equal(seg.sessionTotals(file, sid, cav.parseSession).outputTokens, 100);

      fs.appendFileSync(file, '\n');
      assert.equal(seg.sessionTotals(file, sid, cav.parseSession).outputTokens, 142);
      assert.equal(seg.sessionTotals(file, sid, cav.parseSession).outputTokens, 142);
    });
  });

  test('a shorter file forces a full reparse', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');

    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }, { out: 250 }]);
      const sid = 'sess-shrink';
      assert.equal(seg.sessionTotals(file, sid, cav.parseSession).outputTokens, 350);

      // Same path, different, shorter content — a rotated or replaced transcript.
      fs.writeFileSync(file, JSON.stringify({
        type: 'assistant', message: { model: 'claude-opus-5', usage: { output_tokens: 9 } },
      }) + '\n');
      assert.equal(seg.sessionTotals(file, sid, cav.parseSession).outputTokens, 9);
    });
  });

  test('a missing transcript yields null, not a throw', () => {
    withCache((seg) => {
      assert.equal(seg.sessionTotals('/nonexistent/nope.jsonl', 'sid', () => null), null);
    });
  });

  test('a corrupt cache file falls back to a full parse', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');

    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }]);
      const sid = 'sess-corrupt';
      seg.sessionTotals(file, sid, cav.parseSession);

      const cacheFile = path.join(seg.cacheRoot(), 'sessions', `${sid}.json`);
      fs.writeFileSync(cacheFile, 'this is not json {{{');
      assert.equal(seg.sessionTotals(file, sid, cav.parseSession).outputTokens, 100);
    });
  });
});

describe('deriveSavings compatibility', () => {
  const seg = () => require(SEGMENT);
  const COMPRESSION = { full: 0.65 };
  const saved = (tokens) => Math.round(tokens / (1 - COMPRESSION.full)) - tokens;

  // Faithful stand-ins for the two upstream contracts, copied from caveman's
  // own implementations. Stubs rather than the installed plugin, because only
  // one version can be installed at a time and both paths must stay covered.
  function v1Caveman() {
    return {
      deriveSavings({ outputTokens, mode, model }) {
        const ratio = COMPRESSION[mode];
        if (ratio == null) return { estSavedTokens: 0, estSavedUsd: 0 };
        return { estSavedTokens: Math.round(outputTokens / (1 - ratio)) - outputTokens, estSavedUsd: 0, model };
      },
    };
  }

  function v2Caveman({ modeLog = [], attributionCalls = [] } = {}) {
    return {
      // Note the shape: v1 arguments produce 0 here, silently. That is the
      // regression this suite exists to catch.
      deriveSavings({ byMode }) {
        let estSavedTokens = 0;
        for (const [key, tokens] of Object.entries(byMode || {})) {
          const ratio = COMPRESSION[key];
          if (ratio == null || tokens <= 0) continue;
          estSavedTokens += Math.round(tokens / (1 - ratio)) - tokens;
        }
        return { estSavedTokens, estSavedUsd: 0 };
      },
      readModeLog: () => modeLog,
      attributeByMode(args) {
        attributionCalls.push(args);
        const events = args.modeLog || [];
        if (events.length === 0) {
          return { byMode: { [args.mode || 'none']: args.outputTokens || 0 }, unknownTokens: 0, basis: 'whole-session' };
        }
        // Upstream credits the span before the first transition to that
        // transition's `prev`, not to the mode active now.
        const prefixMode = events[0].prev;
        const byMode = {};
        for (const m of args.messages || []) {
          let active;
          for (const ev of events) { if (ev.ts <= m.ts) active = ev; else break; }
          const key = (active ? active.mode : prefixMode) || 'none';
          byMode[key] = (byMode[key] || 0) + m.outputTokens;
        }
        return { byMode, unknownTokens: 0, basis: 'log' };
      },
      attributionCalls,
    };
  }

  const totals = {
    outputTokens: 1000, cacheReadTokens: 0, turns: 2, model: 'claude-opus-5',
    messages: [{ ts: 1000, outputTokens: 400 }, { ts: 2000, outputTokens: 600 }],
  };

  test('caveman 1.x is driven through its flat-mode signature', () => {
    const out = seg().deriveSessionSavings({ cav: v1Caveman(), mode: 'full', totals, modeLogPath: '/nope' });
    assert.equal(out, saved(1000));
  });

  test('caveman 2.x is driven through byMode, not the 1.x signature', () => {
    const cav = v2Caveman();
    const out = seg().deriveSessionSavings({ cav, mode: 'full', totals, modeLogPath: '/nope' });
    // The load-bearing assertion: a nonzero figure proves the v1 call shape was
    // not used, because v2's deriveSavings returns 0 for it.
    assert.equal(out, saved(1000));
    assert.equal(cav.attributionCalls.length, 1, 'attributeByMode was not consulted');
  });

  test('a mid-session mode switch is credited per mode, not wholesale', () => {
    // First turn ran under a mode with no benchmark data, second under full.
    const cav = v2Caveman({ modeLog: [{ ts: 1500, mode: 'full', prev: 'ultra' }] });
    const out = seg().deriveSessionSavings({
      cav, mode: 'full', totals, modeLogPath: '/nope',
    });
    assert.equal(out, saved(600), 'tokens from before the switch must not earn full-mode credit');
    assert.notEqual(out, saved(1000), 'whole session was credited to the current mode');
  });

  test('the mode log path and flag mtime reach caveman 2.x', () => {
    const cav = v2Caveman();
    seg().deriveSessionSavings({
      cav, mode: 'full', totals, modeLogPath: '/some/.caveman-mode-log.jsonl', flagMtimeMs: 4242,
    });
    assert.equal(cav.attributionCalls[0].flagMtimeMs, 4242);
    assert.equal(cav.attributionCalls[0].outputTokens, 1000);
  });

  test('a mode without benchmark data yields nothing under either version', () => {
    for (const cav of [v1Caveman(), v2Caveman()]) {
      assert.equal(seg().deriveSessionSavings({ cav, mode: 'ultra', totals, modeLogPath: '/nope' }), 0);
    }
  });

  test('a throwing or absent seam degrades to zero, never a wrong number', () => {
    const s = seg();
    const boom = () => { throw new Error('upstream moved'); };
    assert.equal(s.deriveSessionSavings({ cav: null, mode: 'full', totals }), 0);
    assert.equal(s.deriveSessionSavings({ cav: {}, mode: 'full', totals }), 0);
    assert.equal(s.deriveSessionSavings({
      cav: { deriveSavings: boom }, mode: 'full', totals, modeLogPath: '/nope',
    }), 0);
    assert.equal(s.deriveSessionSavings({
      cav: { deriveSavings: () => ({ estSavedTokens: 5 }), readModeLog: () => [], attributeByMode: boom },
      mode: 'full', totals, modeLogPath: '/nope',
    }), 0);
    assert.equal(s.deriveSessionSavings({
      cav: { ...v2Caveman(), readModeLog: boom }, mode: 'full', totals, modeLogPath: '/nope',
    }), saved(1000), 'an unreadable mode log must still attribute by the live flag');
  });

  test('nonsense return values are rejected', () => {
    const s = seg();
    for (const value of [{ estSavedTokens: NaN }, { estSavedTokens: -5 }, { estSavedTokens: '900' }, null]) {
      assert.equal(s.deriveSessionSavings({
        cav: { deriveSavings: () => value }, mode: 'full', totals, modeLogPath: '/nope',
      }), 0, `expected 0 for ${JSON.stringify(value)}`);
    }
  });

  test('the installed caveman, whichever it is, still yields a figure', (t) => {
    const cav = caveman();
    if (!cav) return t.skip('caveman plugin not installed');
    const claude = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
    const out = seg().deriveSessionSavings({
      cav, mode: 'full', totals,
      modeLogPath: path.join(claude, require(SEGMENT).MODE_LOG_BASENAME),
      flagMtimeMs: null,
    });
    assert.ok(out > 0, 'installed caveman produced no savings for a full-mode session');
  });
});

describe('project identity', () => {
  const seg = () => require(SEGMENT);

  test('normalizes ssh and https remotes to one identity', () => {
    const s = seg();
    assert.equal(s.normalizeRemote('git@github.com:fnayou/dotfiles.git'), 'github.com/fnayou/dotfiles');
    assert.equal(s.normalizeRemote('https://github.com/fnayou/dotfiles.git'), 'github.com/fnayou/dotfiles');
    assert.equal(s.normalizeRemote('https://github.com/fnayou/dotfiles'), 'github.com/fnayou/dotfiles');
    assert.equal(s.normalizeRemote('ssh://git@gitlab.com:22/group/sub/proj.git'), 'gitlab.com/group/sub/proj');
    assert.equal(s.normalizeRemote('https://GitHub.com/Fnayou/DotFiles.git'), 'github.com/fnayou/dotfiles');
  });

  test('rejects junk remotes', () => {
    const s = seg();
    for (const junk of ['', null, undefined, 'not a url', 42, {}]) {
      assert.equal(s.normalizeRemote(junk), null, `expected null for ${JSON.stringify(junk)}`);
    }
  });

  test('prefers workspace.repo from the payload', () => {
    const s = seg();
    assert.equal(
      s.projectIdentity({ workspace: { repo: { host: 'GitHub.com', owner: 'fnayou', name: 'dotfiles' }, current_dir: '/tmp' } }),
      'github.com/fnayou/dotfiles',
    );
  });

  test('falls back to a canonical path outside a git repo', () => {
    const s = seg();
    const dir = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'norepo-')));
    try {
      const id = s.projectIdentity({ workspace: { current_dir: dir, project_dir: dir } });
      assert.equal(id, `path:${dir}`);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });

  test('falls back to project_dir when current_dir is gone', () => {
    const s = seg();
    const dir = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'gone-')));
    try {
      const id = s.projectIdentity({ workspace: { current_dir: '/nonexistent/deleted', project_dir: dir } });
      assert.equal(id, `path:${dir}`);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });

  test('returns null when nothing identifies the project', () => {
    assert.equal(seg().projectIdentity({}), null);
  });
});

describe('repository ledger', () => {
  test('one file per session, so a session never counts twice', () => {
    withCache((seg) => {
      assert.equal(seg.updateLedger('path:/p/a', 's1', 100), 100);
      assert.equal(seg.updateLedger('path:/p/a', 's1', 250), 250, 'rewrite must replace, not add');
      assert.equal(seg.updateLedger('path:/p/a', 's1', 250), 250, 'idempotent re-render');
    });
  });

  test('sessions in one repository aggregate', () => {
    withCache((seg) => {
      seg.updateLedger('path:/p/a', 's1', 100);
      seg.updateLedger('path:/p/a', 's2', 400);
      assert.equal(seg.updateLedger('path:/p/a', 's3', 25), 525);
    });
  });

  test('repositories are isolated from each other', () => {
    withCache((seg) => {
      seg.updateLedger('path:/repo/a', 'sa', 1000);
      assert.equal(seg.updateLedger('path:/repo/b', 'sb', 7), 7, 'repo B must not see repo A');
      assert.equal(seg.updateLedger('path:/repo/a', 'sa', 1000), 1000);
    });
  });

  test('a malformed ledger entry is skipped, the rest still sum', () => {
    withCache((seg) => {
      seg.updateLedger('path:/p/c', 'good1', 100);
      seg.updateLedger('path:/p/c', 'good2', 50);
      const crypto = require('crypto');
      const hash = crypto.createHash('sha1').update('path:/p/c').digest('hex').slice(0, 16);
      const dir = path.join(seg.cacheRoot(), 'repos', hash);
      fs.writeFileSync(path.join(dir, 'broken.json'), '{{{ not json');
      fs.writeFileSync(path.join(dir, 'null.json'), 'null');
      fs.writeFileSync(path.join(dir, 'nonnumeric.json'), JSON.stringify({ est_saved_tokens: 'lots' }));
      fs.writeFileSync(path.join(dir, 'ignored.txt'), 'whatever');
      assert.equal(seg.updateLedger('path:/p/c', 'good1', 100), 150);
    });
  });

  test('no identity means no repository figure', () => {
    withCache((seg) => {
      assert.equal(seg.updateLedger(null, 's1', 100), null);
      assert.equal(seg.updateLedger('path:/p/d', null, 100), null);
    });
  });

  test('entries past the retention window are pruned', () => {
    withCache((seg) => {
      seg.updateLedger('path:/p/e', 'fresh', 10);
      const crypto = require('crypto');
      const hash = crypto.createHash('sha1').update('path:/p/e').digest('hex').slice(0, 16);
      const dir = path.join(seg.cacheRoot(), 'repos', hash);
      const stale = path.join(dir, 'ancient.json');
      fs.writeFileSync(stale, JSON.stringify({
        ts: Date.now() - 400 * 24 * 60 * 60 * 1000, session_id: 'ancient', est_saved_tokens: 999999,
      }));
      assert.equal(seg.updateLedger('path:/p/e', 'fresh', 10), 10);
      assert.equal(fs.existsSync(stale), false, 'stale entry should have been pruned');
    });
  });
});

describe('render', () => {
  const h = n => (n >= 1e3 ? (n / 1e3).toFixed(1) + 'k' : String(n));

  test('session only when the repository adds nothing', () => {
    const out = require(SEGMENT).render({ mode: 'full', sessionSaved: 7400, repoSaved: 7400, humanizeTokens: h });
    assert.match(out, /\[CAVEMAN\] \u{26cf} 7\.4k/u);
    assert.doesNotMatch(out, /repo|sess/);
  });

  test('both figures when the repository has more', () => {
    const out = require(SEGMENT).render({ mode: 'full', sessionSaved: 7400, repoSaved: 42100, humanizeTokens: h });
    assert.match(out, /7\.4k sess/);
    assert.match(out, /42\.1k repo/);
  });

  test('a mode without benchmark data renders a bare badge', () => {
    const out = require(SEGMENT).render({ mode: 'ultra', sessionSaved: 0, repoSaved: 0, humanizeTokens: h });
    assert.match(out, /\[CAVEMAN:ULTRA\]/);
    assert.doesNotMatch(out, /\u{26cf}/u);
  });

  test('output is wrapped in the orange colour and always reset', () => {
    const out = require(SEGMENT).render({ mode: 'full', sessionSaved: 100, repoSaved: 0, humanizeTokens: h });
    assert.ok(out.startsWith('[38;5;172m'), 'missing colour prefix');
    assert.ok(out.endsWith('[0m'), 'missing reset');
  });
});

describe('end to end', () => {
  // The subprocess gets its own XDG_CACHE_HOME too, so driving the real script
  // never writes into the user's actual status line cache.
  function run(payload, env = {}) {
    const cache = fs.mkdtempSync(path.join(os.tmpdir(), 'sl-e2e-'));
    try {
      return execFileSync('bash', [SCRIPT], {
        input: JSON.stringify(payload),
        encoding: 'utf8',
        env: { ...process.env, XDG_CACHE_HOME: cache, ...env },
        timeout: 20000,
      });
    } finally {
      fs.rmSync(cache, { recursive: true, force: true });
    }
  }

  const base = {
    session_id: 'e2e-session',
    model: { display_name: 'Opus 5' },
    workspace: { current_dir: os.tmpdir(), project_dir: os.tmpdir() },
  };

  test('the status line still renders when the transcript is missing', () => {
    const out = run({ ...base, transcript_path: '/nonexistent/none.jsonl' });
    assert.match(out, /Opus 5/, 'unrelated segments must survive');
  });

  test('the status line still renders when the transcript is malformed', () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bad-tx-'));
    const file = path.join(dir, 'bad.jsonl');
    fs.writeFileSync(file, 'not json\n{{{\n\0\n');
    try {
      const out = run({ ...base, transcript_path: file });
      assert.match(out, /Opus 5/);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });

  test('the status line survives a payload with no caveman fields at all', () => {
    const out = run({ model: { display_name: 'Opus 5' }, workspace: { current_dir: os.tmpdir() } });
    assert.match(out, /Opus 5/);
  });

  test('the machine-wide lifetime suffix is never rendered', () => {
    // The whole point of this change. caveman's suffix file holds a global
    // total; if it ever reappears in the output we have regressed.
    const claude = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
    let suffix = '';
    try { suffix = fs.readFileSync(path.join(claude, '.caveman-statusline-suffix'), 'utf8').trim(); } catch { /* absent */ }
    if (!suffix) return; // nothing recorded on this machine; nothing to regress against
    const figure = suffix.replace(/[^\d.kmKM]/g, '');
    if (!figure) return;
    const out = run({ ...base, transcript_path: '/nonexistent/none.jsonl' });
    assert.ok(!out.includes(figure), `status line leaked the machine-wide total ${figure}`);
  });
});
