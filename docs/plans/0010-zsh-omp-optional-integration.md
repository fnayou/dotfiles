# Plan: Zsh — Reference Oh My Posh as Optional Integration

**Number:** 0010
**Status:** Complete
**Date:** 2026-06-17
**PRD:** N/A (corrective documentation task)
**Architecture:** N/A (template/docs only)
**Relates to:** Plan 0007 (Zsh foundation), Plan 0008 (OMP support)

---

## Objective

Update the zsh template files to reference Oh My Posh as an optional integration — a documentation and template-only change that requires no installation, no activation, no `$HOME` changes, and no new Stow packages.

---

## Assumptions

- Plan 0007 (Status: Complete) produced `stow/common/zsh/.config/zsh/shared.zsh.example`, `macos.zsh.example`, `arch.zsh.example`, and `.gitignore`.
- Plan 0008 (Status: Complete) produced `stow/common/omp/`, `omp.toml.example`, and `stow/common/zsh/.config/zsh/omp.zsh.example`.
- `omp.zsh.example` is inert (22 lines, all comments). No change to this file is needed.
- `shared.zsh.example` currently has no mention of OMP. It ends with a portable alias block followed by a NOTE comment.
- `docs/stow-usage.md` has a complete "Zsh package adoption" section. The zsh section does not reference OMP.
- `docs/plans/0007-implement-zsh-configuration-foundation.md` is Status: Complete. Appending a post-completion note does not change its status.
- `docs/reviews/0012-zsh-implementation-final-review.md` is Status: Complete. Appending a post-completion note does not change its status.
- `git`, `stow`, and `mktemp` are available on the dev machine.
- The working tree is on a feature branch (not `main`).
- No stow install command will be run at any point in this plan. `--simulate` only, and only against a temporary `TEST_HOME`.

---

## Ordered Tasks

### Task 1 — Update `stow/common/zsh/.config/zsh/shared.zsh.example`

Insert the OMP optional block after the portable aliases block and before the NOTE comment that closes the file.

**Content inserted:**

```zsh
# --- Optional: Oh My Posh prompt integration ---
# Oh My Posh is a prompt engine (NOT Oh My Zsh — it has no plugin manager).
# Requires: oh-my-posh installed, a Nerd Font in your terminal, ~/.config/omp/omp.toml
# See stow/common/omp/ for the config template and docs/stow-usage.md for setup steps.
#
# To activate, copy this block to your real shared.zsh and uncomment:
# if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "$HOME/.config/omp/omp.toml" ]]; then
#   eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
# fi
```

All lines are comments. No active shell code.

### Task 2 — Update `docs/stow-usage.md`

Append `### Optional — Oh My Posh integration` subsection after Step 6 in the Zsh adoption section. Contains: OMP/Oh My Zsh distinction, reference to `stow/common/omp/`, fake-home `TEST_HOME` validation technique. No active shell commands.

### Task 3 — Append post-completion note to `docs/plans/0007-implement-zsh-configuration-foundation.md`

Append-only. Status: Complete unchanged.

### Task 4 — Append post-completion note to `docs/reviews/0012-zsh-implementation-final-review.md`

Append-only. Status: Complete unchanged.

### Task 5 — Fake-home validation

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
rm -rf "$TEST_HOME"
```

Result: clean (no conflicts). `omp` package validate omitted — package not on this branch.

---

## Files Affected

| File | Operation |
|---|---|
| `stow/common/zsh/.config/zsh/shared.zsh.example` | Modified |
| `docs/stow-usage.md` | Modified |
| `docs/plans/0007-implement-zsh-configuration-foundation.md` | Modified (append only) |
| `docs/reviews/0012-zsh-implementation-final-review.md` | Modified (append only) |

---

## Safety Checks

- No file outside repository root modified.
- `~/.zshrc` never read, copied, or modified.
- No symlink created in `$HOME`.
- No stow install run. `--simulate` only against `TEST_HOME`.
- No `--adopt` used.
- No plugin manager or framework introduced.
- No secrets, credentials, or personal identifiers in any committed file.

---

## Completion Criteria

- [x] `shared.zsh.example` contains 9-line OMP optional block, fully commented, between alias block and NOTE comment.
- [x] No active `eval` or uncommented shell code in `shared.zsh.example`.
- [x] NOTE comment remains last block in `shared.zsh.example`.
- [x] `docs/stow-usage.md` has `### Optional — Oh My Posh integration` subsection in Zsh adoption section.
- [x] New subsection clarifies OMP is not Oh My Zsh. No active shell commands.
- [x] `docs/plans/0007-implement-zsh-configuration-foundation.md` has Post-Completion Notes appended. Status: Complete unchanged.
- [x] `docs/reviews/0012-zsh-implementation-final-review.md` has Post-Completion Notes appended. Status: Complete unchanged.
- [x] Fake-home validation passes for zsh package.
- [x] No `$HOME` change, no symlink, no stow install against real `$HOME`.
- [x] Plan not committed automatically.
