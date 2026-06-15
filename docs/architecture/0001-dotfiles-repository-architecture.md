# Architecture: Dotfiles Repository

**Number:** 0001
**Status:** Approved
**Date:** 2026-06-15
**PRD:** none — based on direct user requirements (no PRD written yet)

---

## Context

The Claude Code operating layer is in place. Dotfiles implementation has not started.
The repository must support macOS (primary) and EndeavourOS / Arch Linux (secondary, planned from the start).
GNU Stow will be used for symlink management with a package-based layout.
No home directory modifications are permitted until the user explicitly approves a stow operation.
No real dotfiles are to be inspected, copied, or replaced.

All open questions from the initial draft have been resolved by the user. This document now reflects those decisions and is approved for planning.

---

## Proposed Structure

```
dotfiles/
├── .claude/                    # Claude Code operating layer (exists)
│   ├── agents/
│   ├── rules/
│   └── skills/
├── docs/                       # Project documentation (exists)
│   ├── architecture/
│   ├── decisions/
│   ├── plans/
│   ├── prd/
│   ├── reviews/
│   └── claude/
├── packages/                   # Non-stow package manifests (future)
│   └── macos/
│       ├── Brewfile.core       # (future) Essential CLI tools
│       ├── Brewfile.cli        # (future) Developer CLI tools
│       ├── Brewfile.dev        # (future) Development environments
│       ├── Brewfile.gui        # (future) GUI applications
│       └── Brewfile.optional   # (future) Optional / personal tools
├── stow/                       # GNU Stow packages (not yet created)
│   ├── common/                 # Works on both macOS and Arch unchanged
│   │   ├── git/                # (future) .gitconfig.example, .gitignore_global.example
│   │   ├── zsh/                # (future) .zshenv — XDG, portable PATH
│   │   └── nvim/               # (future, not initial) Neovim config
│   ├── macos/                  # macOS-specific only
│   │   ├── zsh/                # (future) .zshrc for macOS
│   │   └── karabiner/          # (future) Key remapping
│   └── arch/                   # EndeavourOS / Arch only
│       ├── zsh/                # (future) .zshrc for Arch
│       └── pacman/             # (future) pacman hooks, mirrorlist
├── scripts/                    # Helper scripts — informational, never auto-executed
│   ├── detect-os.sh
│   ├── bootstrap.sh
│   ├── macos/
│   │   └── brew-install.sh
│   └── arch/
│       └── pacman-install.sh
├── test/                       # Test harness (not yet created)
│   ├── docker/                 # Docker-based Linux test environments (future)
│   │   ├── arch/               # (future) Dockerfile for Arch / EndeavourOS simulation
│   │   │   └── Dockerfile
│   │   ├── debian/             # (future) Dockerfile for Debian-based testing
│   │   │   └── Dockerfile
│   │   └── README.md
│   └── fixtures/               # Fake home directory for safe, isolated testing
│       └── home/               # (future) Fake $HOME used by Docker containers
│           └── README.md
├── Taskfile.yml                # Task runner (go-task)
├── .gitignore
├── README.md
├── AGENTS.md
└── CLAUDE.md
```

---

## Design Decisions

### Decision 1: Platform-first Stow layout

**Option A: Platform-first** — `stow/<platform>/<package>/`

```
stow/
├── common/git/
├── macos/zsh/
└── arch/zsh/
```

- Pro: Stow invocation is simple and unambiguous per platform.
- Pro: Clear visual boundary — everything under `arch/` is Arch-only.
- Con: Same logical package (e.g., `zsh`) split across directories.

**Option B: Package-first** — `stow/<package>/<platform>/`

```
stow/
├── zsh/
│   ├── common/
│   ├── macos/
│   └── arch/
```

- Pro: All zsh config lives together.
- Con: Stow cannot target sub-directories directly — requires wrapper scripts.
- Con: More complex invocation; harder to audit what links per platform.

**Decision: Option A — platform-first. Approved.**
Simpler stow commands. Explicit platform separation reduces risk of stowing wrong config on wrong OS.

---

### Decision 2: Task runner

**Option A: Makefile** — zero dependencies, but fragile quoting, no built-in descriptions.

**Option B: go-task (Taskfile.yml)** — YAML, readable, cross-platform, `task --list` discovery.

**Option C: Shell scripts only** — no unified entry point.

**Decision: go-task (Taskfile.yml). Approved.**
User already uses Taskfile in other projects. Tasks are safe-by-default and discoverable.
`just` noted as a possible future evaluation — not added now to avoid complexity.

Installation:
```bash
# macOS
brew install go-task

# Arch / EndeavourOS
sudo pacman -S go-task
```

---

### Decision 3: Sensitive config handling

**Option A: Commit real config with secrets stripped** — complete picture, high vigilance required.

**Option B: .example files only** — zero leak risk; user populates locally before stowing.

**Decision: Option B — .example files for all config that could contain sensitive values. Approved.**

Applies to:
- `gitconfig` — email, signing key, identity
- `gitignore_global` — safe to commit directly (no sensitive values)
- Any file referencing API tokens, hostnames, or credentials

Non-sensitive configs (aliases, completions, editor options with no identity data) can be committed directly.

---

### Decision 4: Git config strategy

Existing Git setup (SSH signing, GitHub CLI) must not be broken or replaced.

**Decision: Start with .example files only. Approved.**

Initial scope:
- `stow/common/git/.gitconfig.example` — uses placeholder values for name, email, signing key
- `stow/common/git/.gitignore_global.example` — safe global gitignore patterns

Rules:
- Do not symlink or replace the existing `~/.gitconfig`.
- Do not force a signing strategy.
- Git signing status: **existing setup / future review** — no change until explicitly requested.

Future direction (not scoped now):
- Git `[include]` or `[includeIf]` for machine-specific identity (work vs. personal).
- Machine-specific overrides (email, signing key) remain outside this repository.
- No hardcoded real name, email, hostname, or signing key in committed files.

---

### Decision 5: SSH config

**Decision: SSH config is out of scope. Explicit non-goal. Approved.**

- SSH config is managed manually per host.
- No SSH package will be created.
- No `.ssh/config` template will be committed.
- No SSH private keys, hostnames, aliases, or sensitive SSH content will be committed.
- This decision is permanent unless explicitly revisited by the user.

---

### Decision 6: zsh configuration strategy

macOS ships zsh 5.x (Apple-provided). Arch ships a current zsh release. Startup behavior differs.

**Future architecture (not implemented yet):**

Three-layer split:

```
stow/common/zsh/
  .zshenv              # XDG vars, portable PATH prefix — safe and minimal

stow/macos/zsh/
  .zshrc               # macOS-specific: Homebrew, macOS PATH, Apple aliases

stow/arch/zsh/
  .zshrc               # Arch-specific: pacman helpers, AUR aliases, Arch PATH
```

Shared zsh logic (aliases, functions, prompt, shell options) will live at
`$XDG_CONFIG_HOME/zsh/shared.zsh` and be sourced by both platform `.zshrc` files.
This path must exist (via the `common/zsh` stow package) before any platform zsh package is stowed.

**Current status: deferred. No zsh files created or stowed yet.**
Existing macOS zsh config is not inspected, copied, or replaced.
If examples are needed before implementation, use `.example` files only.

---

### Decision 7: XDG Base Directory specification

**Option A: Strict XDG** — all config in `$XDG_CONFIG_HOME`. Clean, but many macOS tools ignore it.

**Option B: Mixed** — use XDG where tools support it; fall back to `$HOME/.*` otherwise.

**Decision: Option B — mixed, XDG where supported. Approved.**
Set `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME` in `.zshenv`. Use them where the tool supports it. Fall back to `$HOME/.*` for tools that ignore XDG (common on macOS).

---

### Decision 8: Common package definition

A package belongs in `stow/common/` **only if** all three hold:
1. Config file path is identical on macOS and Arch.
2. Config values work without modification on both platforms.
3. No platform-specific tool or behavior is referenced.

If any condition fails, it goes into the platform-specific directory.

---

### Decision 9: Homebrew management strategy

**Decision: Split Brewfiles by category under `packages/macos/`. Future scope only. Approved.**

```
packages/macos/
├── Brewfile.core       # Essential: git, zsh, go-task, stow, curl
├── Brewfile.cli        # Developer CLI: ripgrep, fd, bat, fzf, jq
├── Brewfile.dev        # Dev environments: node, python, rust toolchains
├── Brewfile.gui        # GUI casks: wezterm, raycast, etc.
└── Brewfile.optional   # Optional / personal tools
```

Rationale: easier to review, install incrementally, and keep optional tools separate.
No Brewfiles are created now. This is the planned structure for when Homebrew management is added.

---

### Decision 10: Secrets management

**Decision: Secrets are out of scope. `pass` noted as future candidate. Approved.**

- No secrets are stored in this repository.
- No password store is configured or committed.
- `pass` is the preferred future candidate if secrets tooling is added later.
- If added, only installation and usage documentation is committed — the actual password store remains outside this repository.

---

### Decision 11: Neovim / editor config

**Decision: Neovim is future scope. Not part of initial implementation. Approved.**

Context:
- User currently uses Vim regularly.
- User intends to learn Neovim.
- Architecture reserves `stow/common/nvim/` for a future package.
- No Neovim config is created, templated, or stowed now.

---

### Decision 12: Docker as optional test harness

**Decision: Docker accepted as future optional test harness. Not implemented now. Approved.**

Docker provides a safe, disposable, repeatable environment for validating repository logic without touching the real `$HOME` or requiring a physical Arch machine.

Scope of Docker testing (future):
- Validate GNU Stow package layout and dry-run commands.
- Validate Taskfile tasks.
- Validate shell scripts and OS detection logic.
- Validate Linux-specific assumptions (path structure, zsh loading, etc.).
- Validate that generated symlinks target a fake `$HOME` (`test/fixtures/home/`), not the real one.
- Validate that no secrets are accidentally included in committed files.
- Validate basic zsh file loading when zsh packages are added.

Out of scope for Docker testing:
- Real macOS behavior (Docker cannot replicate macOS).
- Homebrew behavior on a real Mac.
- macOS `defaults write` or system preferences.
- GUI application settings.
- SSH agent or Keychain integration.
- Real host-specific configuration.

Rules:
- Docker is **optional** — the repository works without it.
- Docker must not mount or modify the real `$HOME`.
- All Docker containers use `test/fixtures/home/` as the fake `$HOME`.
- Docker containers are disposable — no state persists between test runs.
- No Dockerfiles are created until Docker testing is explicitly planned and scoped.

---

## Initial Minimal Scope

The initial build produces **repository scaffolding only** — no stow packages are created yet.

| Item | Action | Notes |
|------|--------|-------|
| `.gitignore` | Create | Cover secrets, local overrides, SSH keys |
| `Taskfile.yml` | Create | Stub with stow tasks — no $HOME-modifying tasks auto-run |
| `stow/` directory structure | Create empty dirs | No package content yet |
| `packages/macos/` | Create empty dirs | No Brewfiles yet |
| `scripts/detect-os.sh` | Create | OS detection — informational only |
| `stow/common/git/.gitconfig.example` | Create | Placeholder values only |
| `stow/common/git/.gitignore_global.example` | Create | Safe global gitignore patterns |

**Not in initial scope:**
- Any `.zshrc`, `.zshenv`, or zsh package.
- Any real `~/.gitconfig` replacement or symlink.
- Any stow install operation.
- Any home directory modification.

---

## Out of Scope (explicit non-goals)

| Item | Status | Notes |
|------|--------|-------|
| SSH config | Permanent non-goal | Managed manually per host |
| zsh implementation | Deferred | Future scope; existing config untouched |
| Neovim config | Deferred | Future scope; reserved in structure |
| Homebrew Brewfiles | Deferred | Structure documented; files not created yet |
| Secrets management (`pass`) | Deferred | Future evaluation; no store in repo |
| macOS system preferences (`defaults write`) | Deferred | High-risk; future scope |
| Arch system config (`pacman.conf`, etc.) | Deferred | Future scope |
| Automated bootstrap / install scripts | Deferred | Scripts are informational only |
| Terminal emulator config | Deferred | Future scope |
| Window manager config (Hyprland, yabai) | Deferred | Future scope |
| Vim config | Out of scope | User manages Vim manually for now |
| Docker test harness | Deferred | Future optional — reserved in `test/`; no Dockerfiles yet |
| macOS testing in Docker | Permanent non-goal | Docker cannot replicate macOS behavior |

---

## Future Package Categories

Proposed structure (not scoped yet):

```
stow/
├── common/
│   ├── git/       zsh/   nvim/   tmux/   ripgrep/   fd/
├── macos/
│   ├── zsh/       karabiner/   hammerspoon/   raycast/
└── arch/
    ├── zsh/       pacman/   hyprland/   waybar/   rofi/
```

Suggested addition sequence (future planning, not yet scheduled):
1. `common/git` — example files first, then real config after review
2. `common/zsh` — `.zshenv` only (XDG + PATH)
3. `macos/zsh` — `.zshrc` for macOS
4. `arch/zsh` — `.zshrc` for Arch
5. `common/nvim` — when user is ready to adopt Neovim

---

## Scripts Layout

Scripts are **informational by default** — they print instructions and prompt for confirmation. No script auto-executes stow or modifies `$HOME`.

```
scripts/
├── detect-os.sh          # Prints "macos" or "arch", exits 1 on unknown OS
├── bootstrap.sh          # Prints setup steps per OS; does not execute them
├── macos/
│   └── brew-install.sh   # Prints brew install commands for review
└── arch/
    └── pacman-install.sh # Prints pacman/yay commands for review
```

Mandatory OS detection pattern for all scripts:

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="macos"
elif [[ -f /etc/arch-release ]]; then
  PLATFORM="arch"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi
```

---

## Taskfile Strategy

All stow operations are exposed through Taskfile tasks. No script auto-invokes stow.

Proposed tasks (Taskfile created in initial scaffold — tasks added incrementally):

```yaml
tasks:
  stow:dry-run:
    desc: "Dry-run stow for a package — PLATFORM and PACKAGE required"
    cmds:
      - stow --dir=stow --target="$HOME" --simulate {{.PLATFORM}}/{{.PACKAGE}}

  stow:install:
    desc: "Install stow package — run stow:dry-run first and review output"
    cmds:
      - stow --dir=stow --target="$HOME" {{.PLATFORM}}/{{.PACKAGE}}

  stow:uninstall:
    desc: "Unlink stow package"
    cmds:
      - stow --dir=stow --target="$HOME" --delete {{.PLATFORM}}/{{.PACKAGE}}

  check:
    desc: "Show repository status"
    cmds:
      - git status
      - git diff --staged

  lint:secrets:
    desc: "Scan staged files for potential secrets before commit"
    cmds:
      - git diff --staged
```

`just` is noted as a possible future evaluation — not added now.

---

## Testing Strategy

Docker provides an optional, safe test harness for validating repository logic on Linux without modifying the real `$HOME` or requiring a physical machine.

```
test/
├── docker/
│   ├── arch/
│   │   └── Dockerfile     # (future) Arch / EndeavourOS simulation
│   ├── debian/
│   │   └── Dockerfile     # (future) Debian-based environment
│   └── README.md
└── fixtures/
    └── home/
        └── README.md      # Fake $HOME used by all Docker test containers
```

Proposed future Taskfile tasks for Docker testing:

```yaml
tasks:
  test:docker:arch:
    desc: "Run stow tests in an Arch Linux container (fake HOME)"
    cmds:
      - docker build -t dotfiles-test-arch test/docker/arch/
      - docker run --rm -v "$(pwd)":/dotfiles dotfiles-test-arch

  test:docker:debian:
    desc: "Run stow tests in a Debian container (fake HOME)"
    cmds:
      - docker build -t dotfiles-test-debian test/docker/debian/
      - docker run --rm -v "$(pwd)":/dotfiles dotfiles-test-debian
```

Docker testing rules:
- Containers must use `test/fixtures/home/` as the fake `$HOME` — never the real `$HOME`.
- Containers are disposable — no persistent state between runs.
- Docker is optional — all repository operations work without it.
- No Dockerfiles are created until Docker testing is explicitly planned.

Docker does not replace testing on real macOS or real EndeavourOS. It supplements Linux validation only.

---

## Safety Strategy

1. **No auto-stow** — no script, hook, or task runs `stow` without explicit human invocation.
2. **Dry-run gate** — `stow:dry-run` must be reviewed before `stow:install`.
3. **`.example` files first** — sensitive config is `.example` only; user renames and fills locally.
4. **Conflict detection** — stow dry-run reports conflicts; never use `--adopt` to resolve.
5. **Scope discipline** — no file outside the repository is created, modified, or deleted without explicit per-session user approval.
6. **Existing config untouched** — real `~/.gitconfig`, `~/.zshrc`, and all current dotfiles are never inspected, copied, or replaced.

---

## Privacy Strategy

Never commit:
- API keys, tokens, access credentials.
- Passwords or passphrases.
- SSH private key content.
- Private hostnames, internal IPs, or internal service URLs.
- Work-specific secrets or environment variables.
- Real email addresses used as identity or credentials.
- Machine-specific paths exposing usernames (`/Users/fnayou/`, `/home/fnayou/`).

`.gitignore` covers common leak vectors:

```gitignore
# Local overrides — never commit
*.local
local.*
.env
.env.*

# SSH keys
id_rsa
id_ed25519
*.pem
*.key

# Secrets
*.secret
*.token
*.password
```

All example files use placeholders:
- `your-email@example.com`
- `YOUR_SIGNING_KEY`
- `YOUR_API_KEY`
- `hostname.example.com`

Future secrets tooling (`pass`) will live entirely outside this repository.

---

## Risks

| Risk | Likelihood | Severity | Mitigation |
|------|-----------|---------|------------|
| Stow conflict with existing dotfiles | High | Medium | Mandatory dry-run; stop on any conflict |
| Secret committed via accidental copy from $HOME | Medium | High | .example files only; pre-commit scan; `.gitignore` |
| Common package breaks on one platform | Medium | Medium | Test each package on both before marking stable |
| zsh version difference causes silent failure | Low | Medium | Document minimum zsh version per platform when zsh packages are added |
| go-task not installed on new machine | Medium | Low | Bootstrap script prints install command; Taskfile fails gracefully if missing |
| Hardcoded `$HOME` path in a config file | Low | Medium | Review all new config; use `$HOME` not absolute paths |
| Git example file committed with real identity | Low | High | Placeholder values enforced; pre-commit checklist |

---

## Open Questions

All questions from the initial draft have been resolved.

| # | Question | Decision |
|---|----------|---------|
| 1 | Neovim as primary editor? | Future scope — reserved in architecture, not implemented now |
| 2 | SSH config in repo? | Explicit non-goal — managed manually per host |
| 3 | Git signing strategy? | Existing setup preserved — future review only |
| 4 | Homebrew: single or split Brewfile? | Split by category under `packages/macos/` — future |
| 5 | Secrets tooling? | `pass` as future candidate — out of scope now |
| 6 | Shared zsh logic location? | `$XDG_CONFIG_HOME/zsh/shared.zsh` — accepted as future architecture |
| 7 | Taskfile vs. Make? | go-task confirmed; `just` future evaluation only |

No open questions remain. Architecture is approved for planning.

---

## Proposed ADRs to Create

| Number | Title | Status |
|--------|-------|--------|
| ADR-0001 | Platform-first Stow directory layout | Approved — ready to write |
| ADR-0002 | go-task as task runner | Approved — ready to write |
| ADR-0003 | .example files for sensitive config | Approved — ready to write |
| ADR-0004 | XDG mixed-mode adoption | Approved — ready to write |
| ADR-0005 | SSH config as explicit non-goal | Approved — ready to write |
| ADR-0006 | Git config start with templates only, existing setup preserved | Approved — ready to write |
| ADR-0007 | Homebrew: split Brewfiles by category (future) | Approved — ready to write |
| ADR-0008 | `pass` as future secrets management candidate | Pending — write when scoped |
| ADR-0009 | Docker as optional dotfiles test harness | Pending — write when Docker testing is planned |

---

## Extensibility

- New packages: add directory under `stow/common/`, `stow/macos/`, or `stow/arch/`.
- New platforms: add top-level directory under `stow/` (e.g., `stow/ubuntu/`).
- New Taskfile tasks: add to `Taskfile.yml` without structural change.
- New scripts: add under `scripts/<platform>/` following the OS-detection pattern.
- New doc categories: add directory under `docs/` and register in `AGENTS.md` section 7 and `documentation.md`.
- Homebrew: add new `Brewfile.<category>` under `packages/macos/` as tools are adopted.
- Docker testing: add `Dockerfile` under `test/docker/<distro>/` per supported Linux environment; add fixtures under `test/fixtures/home/` as package tests are written.

---

## Recommended Next Step

Architecture approved. ADRs 0001–0007 written. Scaffold plan (`docs/plans/0001-initial-repository-scaffold.md`) written and approved.

**Immediate: user approves scaffold plan, Builder implements tasks 1–8.**

Tasks 1–8 of the scaffold plan:
- `.gitignore`
- `Taskfile.yml` stub
- `stow/` directory structure
- `packages/macos/` directory
- `scripts/detect-os.sh`
- `stow/common/git/.gitconfig.example`
- `stow/common/git/.gitignore_global.example`

Recommended: Path A first (ADRs are fast to write), then Path B (scaffold plan), then build.
