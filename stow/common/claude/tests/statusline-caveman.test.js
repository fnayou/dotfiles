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

function transcript(dir, turns) {
  const file = path.join(dir, 'session.jsonl');
  const lines = turns.map(t => JSON.stringify({
    type: 'assistant',
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
