# Doctor — Machine Health Check

`task doctor` answers one question: **is this machine set up the way the repository intends?**

It is read-only. It installs, stows, links, moves, and deletes nothing, writes nothing inside `$HOME`,
and needs no network. Safe to run at any time, including when you already suspect something is broken.

```bash
task doctor
```

Name every offending file rather than counting them:

```bash
task doctor:verbose
```

## Why this exists

Every managed layer is guarded:

```zsh
command -v herdr >/dev/null 2>&1 || return
[[ -r "$HOME/.config/zsh/speedtest.zsh" ]] && source ...
```

That is what lets a half-adopted machine still start a clean shell. The price is that a broken setup
looks *identical* to a correct one: a missing tool, an unlinked file, or a mis-ordered `PATH` produces
a shell that starts perfectly and quietly lacks a feature. **"My shell works" proves nothing.**
`doctor` asserts the positive instead. See ADR-0063.

## Output legend

| | Meaning |
|---|---|
| `PASS` | Verified correct |
| `FAIL` | Contradicts the repository's intent — sets exit code 1 |
| `WARN` | Works, but not as intended, or a known trap is present |
| `SKIP` | Not applicable here (tool absent, package not stowed) |
| `INFO` | Context, no judgement |

A missing **optional** tool is `INFO`, never `FAIL` — layers no-op by design, so absence is a
legitimate state, not a fault.

## What it checks

1. **Environment** — OS (macOS / Arch / Debian), repository location, git checkout.
2. **Core tooling** — `git`, `stow`, `task`, `zsh`.
3. **Stow linkage** — every managed file exists in `$HOME` as a symlink pointing back into *this*
   repository. Catches the re-stow drift described below, and links owned by a different checkout.
4. **Directory folding** — `~/.config/<pkg>` must be a real directory, not a symlink (ADR-0024).
5. **Zsh activation** — `~/.zshrc` is a real, unmanaged file (ADR-0027) and carries the managed block.
6. **PATH placement** — statically flags `PATH` / `brew shellenv` in `local.zsh` (ADR-0062). Reports
   **line numbers only** — `local.zsh` is private and its contents are never printed.
7. **Live shell probe** — the decisive test; see below.
8. **Optional tooling** — which guarded layers are active and which are inert.
9. **Git configuration** — the managed include is wired into the global config.
10. **Version** — current `HEAD` against the newest **local** tag. Offline: run `git fetch --tags`
    yourself to compare against origin.

## The live shell probe

The part that catches what nothing else can. It starts one `zsh` with a deliberately minimal `PATH` —
reproducing a terminal launched from a desktop session, rather than one that inherited an
already-configured environment — and reads back what actually registered:

```
PASS: herdr completion registers in a fresh shell
PASS: task completion registers in a fresh shell
PASS: zoxide active (single chpwd hook, cd overridden)
```

`HISTFILE` is redirected into a temp directory for the probe, so your real shell history is untouched.

If a tool is installed but its completion does not register, that is the ADR-0062 trap:

```
FAIL: herdr is installed but its completion does NOT register in a fresh shell
      → this is the ADR-0062 trap: herdr is not on PATH yet when its layer
        loads, so the guard returns and registers nothing. It will appear to
        work after 'exec zsh', because PATH/FPATH are exported and inherited.
        Fix: set PATH in ~/.zshrc ABOVE the managed block.
```

The tell is that `exec zsh` "fixes" it while a new terminal window does not.

## Common findings

**`N of M file(s) not linked into $HOME`** — you pulled commits that added new files to a package
that was stowed earlier. Symlinks are per-file, so new files need a new stow run. Dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate <package>
```

⚠️  MANUAL STEP — run only after reviewing the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding <package>
```

**`~/.config/<pkg> is a symlink`** — stowed without `--no-folding`. See the
[zsh setup guide](zsh-setup.md) for the unstow/re-stow sequence.

**`link(s) point outside this repo`** — another dotfiles checkout owns those links. Run
`task doctor:verbose` to see which, and resolve manually. Never use `--adopt`.

**`zoxide registered N chpwd hooks`** — zoxide was initialised more than once, usually a leftover
`eval "$(zoxide init …)"` in `local.zsh` duplicating what `tools.zsh` already does. Remove it.

**`zinit not found`** — a one-time manual clone that is never automated (ADR-0020). See
[shell dependencies](../shell-dependencies.md).

## What it deliberately does not do

- **It does not fix anything.** A repairing doctor could not honestly claim read-only, which is the
  property that makes it safe to run first. It prints the dry-run command and leaves the decision
  with you.
- **It does not reach the network.** Version drift is reported against local tags only.
- **It does not run in CI.** CI has no stowed `$HOME`; every meaningful assertion would be skipped.
