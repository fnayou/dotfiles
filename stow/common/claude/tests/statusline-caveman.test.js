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
      { ts: Date.parse('2026-01-01T00:00:00.000Z'), outputTokens: 10, cacheReadTokens: 0 },
      { ts: null, outputTokens: 5, cacheReadTokens: 0 },
      { ts: null, outputTokens: 1, cacheReadTokens: 0 },
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

      // caveman 2.x only: the per-message array feeds attributeByMode. The
      // installed caveman may omit cacheReadTokens for records without cache
      // reads, while our accumulate always includes it as 0. What matters for
      // output-token accounting is that outputTokens and turns reconcile.
      if (Array.isArray(truth.messages)) {
        assert.equal(warm.messages.length, truth.messages.length, 'per-message record count diverged');
        assert.equal(
          warm.messages.reduce((s, m) => s + m.outputTokens, 0),
          truth.messages.reduce((s, m) => s + m.outputTokens, 0),
          'per-message output tokens diverged',
        );
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

  test('local fallback parser works when caveman is not installed', () => {
    withCache((seg, cacheDir) => {
      const dir = fs.mkdtempSync(path.join(cacheDir, 'tx-'));
      const file = transcript(dir, [{ out: 100 }, { out: 250 }]);
      const sid = 'sess-fallback';
      const out = seg.sessionTotals(file, sid, null);
      assert.equal(out.outputTokens, 350);
      assert.equal(out.turns, 2);
    });
  });
});

describe('render', () => {
  const h = n => (n >= 1e3 ? (n / 1e3).toFixed(1) + 'k' : String(n));

  test('renders mode and session output tokens', () => {
    const out = require(SEGMENT).render({ mode: 'full', outputTokens: 7400, humanizeTokens: h });
    assert.match(out, /caveman:full \u{26cf} 7\.4k session/u);
  });

  test('renders off mode with zero tokens', () => {
    const out = require(SEGMENT).render({ mode: 'off', outputTokens: 0, humanizeTokens: h });
    assert.match(out, /caveman:off \u{26cf} 0 session/u);
  });

  test('renders any active mode in lowercase', () => {
    const out = require(SEGMENT).render({ mode: 'ultra', outputTokens: 12500, humanizeTokens: h });
    assert.match(out, /caveman:ultra \u{26cf} 12\.5k session/u);
  });

  test('uses the fallback formatter when caveman humanizeTokens is absent', () => {
    const out = require(SEGMENT).render({ mode: 'full', outputTokens: 1250000 });
    assert.match(out, /caveman:full \u{26cf} 1\.3M session/u);
  });

  test('output is wrapped in the orange colour and always reset', () => {
    const out = require(SEGMENT).render({ mode: 'full', outputTokens: 100, humanizeTokens: h });
    assert.ok(out.startsWith('\u001b[38;5;172m'), 'missing colour prefix');
    assert.ok(out.endsWith('\u001b[0m'), 'missing reset');
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
