# Decision: Agent Token Tooling Installed Per-Tool, Skills Through the Shared `~/.agents` Directory

**Number:** 0080
**Date:** 2026-09-25
**Status:** Accepted
**PRD:** N/A — operator-requested machine provisioning, no repository feature
**Architecture:** N/A
**Related:** 0056 (caveman segment lives in dotfiles), 0066 (caveman seam by capability),
0067 (Codex config boundary), 0045 (flat Brewfile)

## Context

Three agent CLIs are installed on this machine — Claude Code, opencode, and Codex CLI. The operator
asked for three third-party additions, active in all three:

- [`rtk`](https://github.com/rtk-ai/rtk) (Rust Token Killer) — rewrites common dev commands so an
  agent reads filtered output instead of raw output.
- [`caveman`](https://github.com/JuliusBrussee/caveman) — a skill and proxy that compresses agent
  prose.
- [`mattpocock/skills`](https://github.com/mattpocock/skills) — 38 engineering skills, wanted
  globally for future projects.

This repository already assumed the first two existed: the `claude` package's status line renders an
`rtk` savings segment and a caveman badge, and ADRs 0056–0060 and 0066 describe the caveman seam in
detail. What was missing was the tools themselves and a record of how they get installed.

Four properties of this repository constrain how that is done:

1. `~/.claude/settings.json` is **deliberately unmanaged** (see the `claude` package README), but it
   holds the `statusLine` key pointing at the repo-owned `statusline-command.sh`.
2. `~/.codex/config.toml` **is** a per-file symlink into the repository, so anything writing to it
   writes into the repository (ADR 0067).
3. Installers that offer "set up per-repo rule files in `$PWD`" will write into whatever directory
   they are run from — including this one.
4. None of these three tools is a Stow package, and none should become one: their state lives in
   directories the repository has explicitly chosen not to manage.

## Decision

### 1. `rtk` comes from Homebrew core, not from a piped installer

```bash
brew install rtk
```

It is in Homebrew core (Apache-2.0), so the `curl … | sh` bootstrap and `cargo install` paths that
upstream documents first are unnecessary. The Brewfile, the Arch list (AUR `rtk-bin`), and the Debian
list (out-of-band; no apt package) each carry it with the same warning:

> **Two unrelated projects are named `rtk`.** This is `rtk-ai/rtk`. The other is
> `reachingforthejack/rtk` (Rust Type Kit), a different tool entirely. `rtk gain` is the
> discriminator — only the Token Killer implements it.

Installation is separated from activation in all three package lists, because installing the binary
does nothing on its own.

### 2. Activation is per-agent and explicit

| Agent | Command | What it writes |
|---|---|---|
| Claude Code | `rtk init -g` | `~/.claude/RTK.md`, a `@RTK.md` reference in `~/.claude/CLAUDE.md`, and a `PreToolUse` entry patched into `~/.claude/settings.json` (keeps a `.bak`) |
| Codex CLI | `rtk init -g --codex` | `~/.codex/hooks.json`, `~/.codex/RTK.md`, `~/.codex/AGENTS.md` |
| opencode | `rtk init -g --opencode` | `~/.config/opencode/plugins/rtk.ts` |

**The Codex integration does not touch `config.toml`.** It registers its hook in a separate
`~/.codex/hooks.json`, so the repository-managed config is unaffected and ADR 0067's boundary holds
without special handling. This was verified, not assumed.

### 3. caveman is installed one agent at a time, never with `--all` or `--with-init`

```bash
npx -y github:JuliusBrussee/caveman -- --only opencode --only codex
```

`--all` and `--with-init` write per-repo rule files (`AGENTS.md`, `.opencode/AGENTS.md`,
`.cursor/rules/`, …) into the **current working directory**. Run from this repository they would add
untracked vendor files to it. The installer is therefore always run from a scratch directory, with
`--only` naming each agent.

**Claude Code is installed separately and its `statusLine` re-verified afterwards.** caveman's Claude
Code path installs hooks *and* its own status line, and patches `~/.claude/settings.json` to point at
it. ADR 0056 already decided that this repository owns that segment, precisely because caveman's own
script reports a machine-wide lifetime total inside a project-scoped status line. The hooks are
wanted (they write the mode flag and per-session files the segment reads); the status line takeover is
not. After any caveman install or update, `settings.json` must still read:

```json
"statusLine": { "type": "command", "command": "bash \"$HOME/.claude/statusline-command.sh\"" }
```

### 4. caveman's split license is accepted for first-party use

caveman is not uniformly open source. `skills/`, the SDKs, and the CLI funnel are MIT; the
compression engine and the Go binaries that embed it (`engine/`, `proxy/`, `rewriter/`, `browse/`,
`mcp/`, `shrink/`) are **Business Source License 1.1**. BSL-1.1's Additional Use Grant permits
first-party self-hosted production use and requires a commercial license for third-party hosted,
managed, or embedded services. Personal use on a workstation is inside the grant. This is recorded
so a future decision to redistribute or host anything caveman-derived starts from the real license.

### 5. Matt Pocock's skills are installed with `skills.sh`, not the Claude Code plugin

```bash
npx skills@latest add mattpocock/skills -g -a claude-code -a codex -a opencode -s '*'
```

Upstream offers two routes and warns that taking both leaves every skill installed twice. The plugin
route is Claude-Code-only, managed, and auto-updating; the `skills.sh` route writes editable files and
covers every agent. The installer route was chosen because it is **one mechanism for all three
agents**, which the plugin cannot be.

The consequence is accepted deliberately: **updates are manual**, via `npx skills update`.

Note `-a` does not accept a comma-separated list. `-a codex,opencode` is parsed as a single agent
named `codex,opencode` and rejected as invalid. The flag must be repeated.

### 6. `~/.agents/skills/` is the installation target, and that is the point

`skills.sh` does not copy into each agent's own directory. It writes one canonical copy to
`~/.agents/skills/<name>/SKILL.md` and relies on agents reading that shared, vendor-neutral location.
Verified on this machine rather than taken on trust:

- **Codex CLI** enumerates the Pocock and caveman skills alongside its own system skills.
- **opencode** documents `~/.agents/skills/` among its global skill roots and reports them loaded.

So a single install covers Codex and opencode with no per-agent duplication. For `claude-code` the
installer additionally copies into `~/.claude/skills/`, which opencode also reads; resolution is by
skill name, so this is redundancy rather than breakage — opencode's reported skill count did not rise
by 38 afterwards.

**Skill names are a flat namespace shared with the host's built-ins, and the host wins.** Installing
38 third-party skills into it means some become unreachable. `code-review` collides with Claude Code's
own `/code-review`; the built-in is what runs, and the upstream skill — a two-axis standards-plus-spec
review, which the built-in is not — is silently shadowed. Accepted rather than worked around, because
renaming upstream skills locally forfeits `npx skills update`. The guide documents how to spot it and
how to rename deliberately if a shadowed skill is wanted.

### 7. None of this becomes a Stow package, and the status blocks do not change

These tools own directories this repository deliberately does not manage: `~/.claude/settings.json`
and hooks, `~/.codex/hooks.json`, `~/.config/opencode/`, and `~/.agents/skills/`. Their content is
machine state and vendor-owned files, not portable configuration.

The `AGENTS.md` §2 and `CLAUDE.md` status blocks are therefore **unchanged**. Per
ADR 0048 and `.claude/rules/status-sync.md`, those blocks track Stow packages added, removed, or
first stowed. This change adds no package and stows nothing.

## Consequences

- A new machine reaches the same state with `brew bundle`, three `rtk init` commands, one caveman
  installer run, and one `skills` command — all recorded in `docs/guides/agent-tooling-setup.md`.
- The status line's two optional segments (`rtk` savings, caveman badge) light up with no dotfiles
  change, as the `claude` package README already promised.
- **Three external files now inject instructions into every session** on this machine:
  `~/.codex/AGENTS.md` and `~/.codex/RTK.md` (Codex), `~/.config/opencode/AGENTS.md` (caveman's
  Tier-3 ruleset, opencode), and `~/.claude/RTK.md` (Claude Code). None is in version control. A
  confusing agent behaviour that survives a repository revert should be looked for there first.
- Skills run with full agent permissions. 58 skill directories from two third-party repositories are
  now globally readable by every agent on this machine. `npx skills update` re-pulls upstream changes
  without review — the update is the same trust decision as the install, repeated.
- caveman's opencode install adds `"plugin": ["./plugins/caveman/plugin.js"]` to
  `~/.config/opencode/opencode.jsonc` even though `~/.config/opencode/plugins/` is already
  auto-loaded at startup. It is left as the vendor installer wrote it.

## Alternatives rejected

- **`curl … | sh` for rtk.** Homebrew core carries it. A piped installer is a worse default when a
  reviewed formula exists, and it would not appear in `packages/`.
- **The Claude Code plugin for the Pocock skills, plus `skills.sh` for the other two.** Keeps
  Claude Code auto-updating, but splits one concern across two mechanisms with different update
  models and trust boundaries. Rejected for uniformity; the operator chose this explicitly.
- **Both Pocock routes.** Upstream's own warning: every skill twice.
- **Running caveman's installer with `--all` from the repository root.** Convenient, and it writes
  vendor rule files into this repository. Rejected outright.
- **Letting caveman own the Claude Code status line.** Directly reverses ADR 0056, and reintroduces
  the machine-wide lifetime total in a project-scoped line that ADR 0056 exists to remove.
- **Adding a `stow/common/` package for any of this.** Would put credentials-adjacent runtime state
  and vendor-installed files under version control, which §9 and the `claude` package's scope rules
  both forbid.
