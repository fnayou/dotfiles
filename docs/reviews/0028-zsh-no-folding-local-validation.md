# 0028: Zsh --no-folding Migration Local Validation Report

| Metadata | Value |
|----------|-------|
| Status | Complete |
| Date | 2026-06-18 |
| Type | Local Validation Report |
| Related | Plan 0013, Review 0027, ADR-0024, ADR-0026, ADR-0027 |

## 1. Commands Run

### 1.1 Directory structure check
```bash
$ ls -ld "$HOME/.config/zsh"
lrwxr-xr-x@ 1 fnayou  staff  45 Jun 18 00:12 /Users/fnayou/.config/zsh -> ../works/dotfiles/stow/common/zsh/.config/zsh
```

### 1.2 Real directory formal check
```bash
$ [[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"
NOT-real-dir
```

### 1.3 Directory contents listing
```bash
$ ls -la "$HOME/.config/zsh/"
total 72
drwxr-xr-x@ 11 fnayou  staff   352 Jun 18 01:25 .
drwxr-xr-x@  3 fnayou  staff    96 Jun 17 19:33 ..
-rw-r--r--@  1 fnayou  staff   226 Jun 17 23:38 .gitignore
-rw-r--r--@  1 fnayou  staff   456 Jun 17 19:33 arch.zsh.example
-rw-r--r--@  1 fnayou  staff  1282 Jun 18 01:25 index.zsh
-rw-r--r--@  1 fnayou  staff  1282 Jun 17 23:37 index.zsh.example
-rw-r--r--@  1 fnayou  staff   629 Jun 17 19:33 macos.zsh.example
-rw-r--r--@  1 fnayou  staff  1115 Jun 17 18:14 omp.zsh.example
-rw-r--r--@  1 fnayou  staff  3263 Jun 18 01:25 shared.zsh
-rw-r--r--@  1 fnayou  staff  3263 Jun 17 23:38 shared.zsh.example
-rw-r--r--@  1 fnayou  staff  1185 Jun 18 00:29 zshrc.example
```

### 1.4 Symlink status of managed files
```bash
$ for f in index.zsh shared.zsh zshrc.example index.zsh.example shared.zsh.example; do
  if [[ -L "$HOME/.config/zsh/$f" ]]; then
    echo "SYMLINK: $f -> $(readlink "$HOME/.config/zsh/$f")"
  elif [[ -f "$HOME/.config/zsh/$f" ]]; then
    echo "REAL-FILE: $f"
  else
    echo "ABSENT: $f"
  fi
done

REAL-FILE: index.zsh
REAL-FILE: shared.zsh
REAL-FILE: zshrc.example
REAL-FILE: index.zsh.example
REAL-FILE: shared.zsh.example
```

### 1.5 Local private file status
```bash
$ if [[ -L "$HOME/.config/zsh/local.zsh" ]]; then
  echo "ERROR: local.zsh is a symlink (unexpected)"
elif [[ -f "$HOME/.config/zsh/local.zsh" ]]; then
  echo "REAL-FILE: local.zsh (correct — private, outside repo)"
else
  echo "ABSENT: local.zsh (correct — not yet created)"
fi

ABSENT: local.zsh (correct — not yet created)
```

### 1.6 ~/.zshrc regular file check
```bash
$ [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && echo "zshrc-regular-file-ok" || echo "zshrc-PROBLEM"
zshrc-regular-file-ok
```

### 1.7 ~/.zshrc guarded include block check
```bash
$ grep "config/zsh/index.zsh" "$HOME/.zshrc"
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
```

### 1.8 Zsh startup (no rc files)
```bash
$ zsh --no-rcs -c 'echo zsh-norc-ok'
zsh-norc-ok
```

### 1.9 Zsh interactive startup
```bash
$ zsh -ic 'echo zsh-interactive-ok'
zsh-interactive-ok
```

### 1.10 Syntax check (index.zsh)
```bash
$ zsh -n /Users/fnayou/works/dotfiles/stow/common/zsh/.config/zsh/index.zsh && echo "index-syntax-ok"
index-syntax-ok
```

### 1.11 Syntax check (shared.zsh)
```bash
$ zsh -n /Users/fnayou/works/dotfiles/stow/common/zsh/.config/zsh/shared.zsh && echo "shared-syntax-ok"
shared-syntax-ok
```

### 1.12 Git status: managed files are .gitignore'd
```bash
$ git -C /Users/fnayou/works/dotfiles check-ignore stow/common/zsh/.config/zsh/index.zsh stow/common/zsh/.config/zsh/shared.zsh
stow/common/zsh/.config/zsh/index.zsh
stow/common/zsh/.config/zsh/shared.zsh
```

### 1.13 Git status: no unmanaged tracked files in zsh layer
```bash
$ git -C /Users/fnayou/works/dotfiles ls-files "stow/common/zsh/.config/zsh/" | grep -vE '\.example$|\.gitignore$'
(no output)
```

### 1.14 Stow simulate: current state
```bash
$ stow --dir=/Users/fnayou/works/dotfiles/stow/common --target="$HOME" --no-folding --simulate zsh 2>&1
WARNING: in simulation mode so not modifying filesystem.
```

### 1.15 Stow simulate --delete: rollback path
```bash
$ stow --dir=/Users/fnayou/works/dotfiles/stow/common --target="$HOME" --no-folding --simulate --delete zsh 2>&1
WARNING: in simulation mode so not modifying filesystem.
```

## 2. Findings Table

| Check Name | Expected | Actual | Verdict |
|-----------|----------|--------|---------|
| ~/.config/zsh is a real directory | Real directory (not symlink) | Symlink to `../works/dotfiles/stow/common/zsh/.config/zsh` | FAIL |
| Managed files are per-file symlinks | Symlinks or real-files (controlled) | All real-files (index.zsh, shared.zsh, *.example) | FAIL |
| index.zsh exists and readable | Present in ~/.config/zsh | PASS: real-file at `~/.config/zsh/index.zsh` | PASS |
| shared.zsh exists and readable | Present in ~/.config/zsh | PASS: real-file at `~/.config/zsh/shared.zsh` | PASS |
| local.zsh status | Absent (not yet created) or real-file (not symlink) | PASS: absent | PASS |
| ~/.zshrc is a regular file | Real file (not symlink) | PASS: regular file | PASS |
| ~/.zshrc guarded include present | `[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"` | PASS: present and correct | PASS |
| Zsh no-rcs startup | No errors | PASS: `zsh-norc-ok` | PASS |
| Zsh interactive startup | No errors, sources ~/.zshrc and managed layer | PASS: `zsh-interactive-ok` | PASS |
| index.zsh syntax | Valid zsh syntax | PASS: `index-syntax-ok` | PASS |
| shared.zsh syntax | Valid zsh syntax | PASS: `shared-syntax-ok` | PASS |
| Managed files git-ignored | index.zsh and shared.zsh in .gitignore | PASS: both files confirmed ignored | PASS |
| No unmanaged tracked files | Only .example and .gitignore tracked in repo | PASS: no untracked managed files | PASS |
| Stow simulate clean | No conflicts or unexpected operations | PASS: clean state | PASS |
| Stow simulate --delete clean | No errors on rollback simulation | PASS: clean deletion path | PASS |

## 3. Real Directory Check

**Result: FAIL**

`~/.config/zsh` is NOT a real directory. It is a **directory-fold symlink** pointing to `../works/dotfiles/stow/common/zsh/.config/zsh`.

This **contradicts the --no-folding migration goal**. The migration was intended to:
- Create `~/.config/zsh` as a real directory.
- Stow individual managed files (`index.zsh`, `shared.zsh`) as **per-file symlinks** under that real directory.

**Actual state**: The directory itself is a symlink (folded), and all managed files underneath are real-files within the symlink target, not per-file symlinks. This is the **opposite** of what --no-folding should achieve.

## 4. Symlink Verification

All files under `~/.config/zsh` are **real-files**, not per-file symlinks:

- `index.zsh` — real-file (should be symlink)
- `shared.zsh` — real-file (should be symlink)
- `zshrc.example` — real-file (OK to be real, not stowed)
- `index.zsh.example` — real-file (OK, template only)
- `shared.zsh.example` — real-file (OK, template only)
- `arch.zsh.example` — real-file (OK, template only)
- `macos.zsh.example` — real-file (OK, template only)
- `omp.zsh.example` — real-file (OK, template only)
- `.gitignore` — real-file (OK)

**This is NOT the intended --no-folding state.** The correct state should be:
- `~/.config/zsh` is a real directory.
- `~/.config/zsh/index.zsh` is a symlink to `../works/dotfiles/stow/common/zsh/.config/zsh/index.zsh`.
- `~/.config/zsh/shared.zsh` is a symlink to `../works/dotfiles/stow/common/zsh/.config/zsh/shared.zsh`.

## 5. Zsh Startup

Both startup checks pass cleanly:

- **No-rcs startup**: `zsh --no-rcs -c 'echo zsh-norc-ok'` → `zsh-norc-ok` ✓
- **Interactive startup**: `zsh -ic 'echo zsh-interactive-ok'` → `zsh-interactive-ok` ✓

This indicates that:
1. Zsh binary itself is functional.
2. When ~/.zshrc is sourced in interactive mode, it completes without syntax errors.
3. The include block in ~/.zshrc successfully sources the managed layer.

No startup errors are present, but this does not validate the symlink structure — only that the content is syntactically correct.

## 6. Privacy

- **~/.zshrc**: User-owned regular file. Safe. Not a symlink. ✓
- **~/.config/zsh/local.zsh**: Absent (not yet created). This is correct. When created, it should be a real-file (user-owned, not tracked, not a symlink). ✓
- **Managed files (index.zsh, shared.zsh)**: Currently real-files under the `~/.config/zsh` symlink. In the intended --no-folding state, they would be per-file symlinks pointing back to the repo. This structure preserves privacy (no untracked managed content is exposed). ✓

## 7. Rollback Path

Both stow simulate commands complete cleanly without errors:

- **Stow simulate**: `WARNING: in simulation mode so not modifying filesystem.` ✓
- **Stow simulate --delete**: `WARNING: in simulation mode so not modifying filesystem.` ✓

This indicates that Stow recognizes the current state and can simulate both installation and removal without conflicts. However, because the current state is **not** the intended --no-folding state (directory is folded, not per-file symlinks), a true rollback using Stow --delete would not cleanly remove the current structure.

## 8. Final Verdict

**Status: NEEDS ATTENTION**

The `~/.config/zsh` directory is currently a **directory-fold symlink**, not a real directory with per-file symlinks. This contradicts the --no-folding migration goal.

**What was observed vs. expected:**
- Expected: `~/.config/zsh` = real directory; `index.zsh`, `shared.zsh` = per-file symlinks into repo.
- Actual: `~/.config/zsh` = symlink to repo directory; all files underneath = real-files in the symlink target.

**Consequence**: The migration has not been completed correctly. A proper --no-folding setup requires manual reconstruction:
1. Remove the `~/.config/zsh` symlink.
2. Create `~/.config/zsh` as a real directory.
3. Run `stow --no-folding` to install per-file symlinks.
4. Verify each managed file is a per-file symlink, not a real-file.

**Managed layer functionality is NOT impaired** — startup checks pass and syntax is valid — but the symlink structure does not match the documented --no-folding intent.

