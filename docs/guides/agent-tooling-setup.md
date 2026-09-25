# Agent Tooling Setup Guide

This guide covers three third-party additions to the AI coding agents on this machine — `rtk`,
`caveman`, and Matt Pocock's skills — and how each is activated in **Claude Code**, **opencode**, and
**Codex CLI**. It is written for a human user, not for implementation agents.

None of these is a Stow package. They write into directories this repository deliberately does not
manage. See
[ADR-0080](../decisions/0080-agent-token-tooling-and-shared-skills-directory.md) for why, and
[`packages/Brewfile`](../../packages/Brewfile) for the one piece that is package-managed.

---

## 1. What each tool is

| Tool | Does what | License | Package-managed |
|---|---|---|---|
| [`rtk`](https://github.com/rtk-ai/rtk) | Rewrites common dev commands (`git status`, `cargo build`, …) so the agent reads filtered output instead of raw output | Apache-2.0 | Yes — Homebrew core, AUR |
| [`caveman`](https://github.com/JuliusBrussee/caveman) | Compresses agent prose; adds skills, commands, and sub-agent presets | MIT + **BSL-1.1** (see §6) | No — own installer |
| [`mattpocock/skills`](https://github.com/mattpocock/skills) | 38 engineering skills (`/grill-with-docs`, `/tdd`, `/triage`, …) | MIT | No — `npx skills` |

`rtk` and `caveman` both feed the Claude Code status line shipped by the `claude` package. Those two
segments stay blank until the tools are installed, then light up with no dotfiles change. See
[`stow/common/claude/README.md`](../../stow/common/claude/README.md).

> **⚠️ Two unrelated projects are named `rtk`.** This guide means
> [`rtk-ai/rtk`](https://github.com/rtk-ai/rtk) (Rust Token Killer). The other,
> `reachingforthejack/rtk` (Rust Type Kit), is a different tool. `rtk gain` is the discriminator —
> only the Token Killer implements it. Always verify after installing.

---

## 2. Install `rtk`

```bash
# macOS (and Homebrew on Linux)
brew install rtk

# Arch / EndeavourOS — not in the official repos; AUR carries it
yay -S rtk-bin          # or: yay -S rtk   (source build)
```

```bash
# Debian — no apt package. Homebrew on Linux, or with a Rust toolchain:
brew install rtk
# or
cargo install --git https://github.com/rtk-ai/rtk
```

Verify it is the correct `rtk` before going further:

```bash
rtk --version
rtk gain        # must print a savings dashboard, not "command not found"
```

Some `rtk` filters shell out to `ripgrep`, already in the Brewfile.

Installing the binary activates nothing. Activation is §3.

---

## 3. Activate `rtk` in each agent

Each command is global (`-g`) and writes outside this repository. Run them one at a time and read
the output — each prints exactly which files it touched.

⚠️  MANUAL STEP — patches `~/.claude/settings.json` (keeps a `.bak`), adds `~/.claude/RTK.md` and a `@RTK.md` reference in `~/.claude/CLAUDE.md`

```bash
rtk init -g
```

It prompts before patching `settings.json`. Add `--auto-patch` to skip the prompt, or `--no-patch` to
print the manual instructions instead. Use `--hook-only` to skip `RTK.md` entirely and keep zero
tokens in context.

⚠️  MANUAL STEP — writes `~/.codex/hooks.json`, `~/.codex/RTK.md`, `~/.codex/AGENTS.md`

```bash
rtk init -g --codex
```

⚠️  MANUAL STEP — writes `~/.config/opencode/plugins/rtk.ts`

```bash
rtk init -g --opencode
```

Then **restart each agent** — hooks and plugins are read once at session start.

Two things worth knowing:

- The Codex integration writes `~/.codex/hooks.json`, **not** `config.toml`. The repository-managed
  `~/.codex/config.toml` is untouched, so ADR-0067's boundary needs no special handling here.
- The hook only intercepts shell/Bash tool calls. Claude Code's built-in `Read`, `Grep`, and `Glob`
  bypass it.

Check what is registered at any time:

```bash
rtk init --show
```

---

## 4. Install and activate `caveman`

caveman's installer auto-detects agents and runs each one's native install path.

> **Run it from a scratch directory, never from a repository.** `--all` and `--with-init` write
> per-repo rule files (`AGENTS.md`, `.opencode/AGENTS.md`, `.cursor/rules/`, …) into the **current
> working directory**. Run from this repository they would add untracked vendor files to it. Use
> `--only <agent>` instead, from `/tmp` or similar.

Preview first — `--dry-run` writes nothing:

```bash
cd /tmp
npx -y github:JuliusBrussee/caveman -- --dry-run --only opencode --only codex
```

⚠️  MANUAL STEP — review the dry-run output first; writes into `~/.config/opencode/` and `~/.agents/skills/`

```bash
cd /tmp
npx -y github:JuliusBrussee/caveman -- --only opencode --only codex --non-interactive
```

### Claude Code — one extra check afterwards

Claude Code installs as a plugin:

⚠️  MANUAL STEP — installs a plugin, hooks, **and caveman's own status line**

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

caveman's Claude Code path also patches `~/.claude/settings.json` to install **its own status line**.
This repository owns that segment on purpose —
[ADR-0056](../decisions/0056-caveman-segment-lives-in-dotfiles-not-in-the-plugin.md) explains why
caveman's own script reports a machine-wide lifetime total inside a project-scoped line.

The hooks are wanted; they write the mode flag and per-session files the repo segment reads. The
status line takeover is not. **After every caveman install or update**, confirm `statusLine` still
points at the repo script:

```bash
jq '.statusLine' ~/.claude/settings.json
```

Expected, exactly:

```json
{
  "type": "command",
  "command": "bash \"$HOME/.claude/statusline-command.sh\""
}
```

If caveman replaced it, restore that value. Note the plugin's update command needs the full name —
`claude plugin update caveman` fails:

```bash
claude plugin update caveman@caveman
```

### Activate a mode

caveman is installed but idle until a mode is set. In Claude Code, `/caveman` (or `/caveman lite` /
`ultra`). In Codex, `/caveman` per session. In opencode the plugin and ruleset are always on.

```bash
cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"   # expected: full
```

The mode flag is **global** — one file for the whole machine, so two concurrent Claude Code windows
cannot run different modes. That is upstream behaviour; see
[ADR-0060](../decisions/0060-caveman-global-mode-flag-limitation-accepted.md).

### Known issue — the caveman status line badge is dark on caveman 2.7.0

**caveman 2.7.0 removed `deriveSavings`** from `src/hooks/caveman-stats.js`. It is not renamed; it is
absent from `src/` entirely. The `claude` package's segment is built on it (ADR-0057, ADR-0066), so the
badge renders nothing on this version. `parseSession`, `readModeLog` and `attributeByMode` all survive;
`parseSession`'s output shape also changed enough to break the warm incremental path.

Upstream changed measurement models — from *estimating* tokens saved per mode to *measuring* byte
reduction over compressed pairs:

```js
findCompressedPairs(dirs)   // scans *.original.md / compressed file pairs
summarizeCompressed(pairs)  // → { count, totalOriginal, totalCompressed, bytesReduced }
```

Bytes, not tokens, so this is a rework of the segment rather than a patch.

Nothing is broken for daily use: the segment degrades as designed — renders nothing, exit 0, no
stderr, rest of the status line intact, `rtk` segment unaffected. The cost is only the missing badge.

Two consequences for the test suite on a machine where caveman **is** installed:

```bash
task test:statusline    # 2 failures: parseSession warm path, deriveSavings compatibility
task check:statusline   # fails: no session figure, no [CAVEMAN:OFF]
```

CI stays green because it runs without caveman, where those assertions skip. The failing guard is named
*"the installed caveman, whichever it is, still yields a figure"* — it exists for exactly this class of
upstream break, and it worked.

---

## 5. Install the Matt Pocock skills

Upstream offers two routes and warns that taking **both** leaves every skill installed twice. This
machine uses the `skills.sh` installer for all three agents, because it is one mechanism for all of
them — the Claude Code plugin covers only Claude Code. The tradeoff is that updates are manual.

⚠️  MANUAL STEP — writes 38 skill directories into `~/.agents/skills/`

```bash
npx skills@latest add mattpocock/skills -g -a claude-code -a codex -a opencode -s '*'
```

`-a` does **not** accept a comma-separated list. `-a codex,opencode` is parsed as one agent named
`codex,opencode` and rejected as invalid. Repeat the flag instead.

### Where they land, and why there is no per-agent copy

The installer writes **one** canonical copy per skill to `~/.agents/skills/<name>/SKILL.md` — a
shared, vendor-neutral location that Codex CLI and opencode both read natively. There is no
`~/.codex/skills/` copy and none is needed.

```bash
npx skills@latest ls -g          # lists each skill and the agents that see it
ls -1 ~/.agents/skills | wc -l   # 58 = 38 Pocock + 20 caveman
```

For `claude-code` the installer copies into `~/.claude/skills/` as well. Because opencode reads both
that directory and `~/.agents/skills/`, it then sees the same 38 twice — resolution is by skill name,
so this is redundancy, not breakage (verified: opencode's skill count did not rise by 38).

### Name collisions shadow the installed skill

Skill names are a flat namespace shared with the host's built-ins, and the host wins.
`code-review` collides with Claude Code's own `/code-review` command, so **Matt's `code-review` is
unreachable by name** — `/code-review` runs the built-in. His is a two-axis review (repo standards
plus originating spec, in parallel sub-agents), which is not what the built-in does, so the
substitution is silent and easy to miss.

Check what actually loaded, rather than assuming all 38 are reachable:

```bash
ls -1 ~/.claude/skills            # what is installed
```

Then compare against the skills the agent reports available in a fresh session. Anything installed but
absent there lost a collision. Rename the directory (and its `name:` in `SKILL.md`) to recover it —
`pocock-code-review`, say. This repository's own `review-change` skill is a third thing again.

### Per-repository setup

Once per repository, run `/setup-matt-pocock-skills` inside the agent. It asks which issue tracker to
use, which triage labels you apply, and where to save generated docs.

### Updating

```bash
npx skills update
```

This re-pulls upstream without review. **The update is the same trust decision as the install,
repeated** — these skills run with full agent permissions.

---

## 6. caveman's license is not uniformly open source

caveman is split-licensed, and it matters if anything caveman-derived is ever redistributed:

| Part | License |
|---|---|
| `skills/`, SDKs, CLI funnel, shared contracts | MIT |
| `engine/`, `proxy/`, `rewriter/`, `browse/`, `mcp/`, `shrink/`, cavemem Go core | **BSL-1.1** |

BSL-1.1's Additional Use Grant permits first-party self-hosted production use, and requires a
commercial license for third-party hosted, managed, or embedded services. Personal use on a
workstation is inside the grant. Upstream's `LICENSING.md` is the per-directory source of truth.

---

## 7. What is now injected into every session

These files add instructions to every agent session on this machine and **none is in version
control**. If an agent behaves oddly in a way that survives reverting this repository, look here
first:

| File | Agent | Written by |
|---|---|---|
| `~/.claude/RTK.md` + `settings.json` hook | Claude Code | `rtk init -g` |
| `~/.codex/AGENTS.md`, `~/.codex/RTK.md`, `~/.codex/hooks.json` | Codex CLI | `rtk init -g --codex` |
| `~/.config/opencode/AGENTS.md` | opencode | caveman (Tier-3 ruleset) |
| `~/.config/opencode/plugins/` | opencode | both (`rtk.ts`, `caveman/`) |
| `~/.agents/skills/` (58 dirs) | all three | caveman + `skills.sh` |

---

## 8. Validation

```bash
rtk --version && rtk gain           # correct rtk installed and tracking
rtk init --show                     # which agent hooks are registered
jq '.statusLine' ~/.claude/settings.json   # still the repo script (§4)
ls -1 ~/.agents/skills | wc -l      # 58
npx skills@latest ls -g             # skills and the agents that see them
```

In a fresh session of each agent, ask it to list its available skills. Codex and opencode should both
report the caveman and Pocock skills.

The status line's `rtk` segment stays hidden until `rtk` has recorded at least one run for the current
directory — it is scoped with `rtk gain --project`, not a lifetime total.

---

## 9. Rollback

Each tool uninstalls itself. Take them one at a time.

⚠️  MANUAL STEP — removes the hook, `RTK.md`, and the `settings.json` entry

```bash
rtk init -g --uninstall
brew uninstall rtk
```

⚠️  MANUAL STEP — removes everything caveman installed, for every detected agent

```bash
cd /tmp
npx -y github:JuliusBrussee/caveman -- --uninstall
```

⚠️  MANUAL STEP — removes the skills from `~/.agents/skills/`

```bash
npx skills@latest remove -g -s '*'
```

Removing all three leaves the `claude` package's status line intact — both segments are guarded and
render nothing when their tool is absent. Restore `~/.claude/settings.json` from the `.bak` that
`rtk init` created if its hook entry needs reverting by hand.
