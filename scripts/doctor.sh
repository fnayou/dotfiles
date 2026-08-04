#!/usr/bin/env bash
# Usage: bash scripts/doctor.sh [--verbose]
#
# Health check for an installed copy of these dotfiles. Answers one question:
# "is this machine actually set up the way the repository intends?"
#
# READ-ONLY. It never installs, stows, symlinks, moves, or deletes anything, and
# never writes inside $HOME. The one subprocess it starts (a probe shell) runs with
# HISTFILE redirected into a temp dir, so your real zsh history is not touched.
# The temp dir is removed on exit.
#
# Why this exists: every managed layer is guarded (`command -v tool || return`,
# `[[ -r file ]] && source`). A missing tool, a missing symlink, or a missed
# `.example` copy therefore produces SILENCE, not an error — "my shell starts
# fine" proves nothing. This asserts the positive instead.
#
# Output legend:
#   PASS  — verified correct
#   FAIL  — broken; exits 1 at the end
#   WARN  — works, but not as intended, or a known trap is present
#   SKIP  — not applicable on this machine (tool absent, package not stowed)
#   INFO  — context, no judgement
#
# See docs/decisions/0024 (--no-folding), 0020 (Zinit never auto-cloned),
# 0027 (~/.zshrc unmanaged), 0049 (compinit ordering), 0062 (PATH placement).

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
FAILED=0
WARNED=0

SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=$((FAILED + 1)); }
warn() { echo "WARN: $1"; WARNED=$((WARNED + 1)); }
skip() { echo "SKIP: $1"; }
info() { echo "INFO: $1"; }
note() { echo "      $1"; }
section() { echo; echo "── $1 ─────────────────────────────────────────"; }

# Resolve a symlink without readlink -f / realpath — neither is portable to
# stock macOS. Prints the absolute target, or nothing if the link is unreadable.
resolve_link() {
  local link=$1 target dir
  target=$(readlink "$link" 2>/dev/null) || return 1
  case "$target" in
    /*) printf '%s\n' "$target" ;;
    *)
      dir=$(dirname -- "$link")
      (cd -- "$dir" 2>/dev/null &&
        cd -- "$(dirname -- "$target")" 2>/dev/null &&
        printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$target")")
      ;;
  esac
}

# --- Environment -------------------------------------------------------------

section "Environment"

if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
elif [[ -f /etc/debian_version ]]; then
  OS="debian"
else
  OS="unknown"
fi

if [[ "$OS" == "unknown" ]]; then
  warn "unsupported OS ($OSTYPE) — platform layers will not load"
else
  info "OS: $OS"
fi

info "repo: $REPO_ROOT"

if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  pass "repository is a git checkout"
else
  fail "not a git checkout — version drift cannot be determined"
fi

# --- Core tooling ------------------------------------------------------------

section "Core tooling"

for tool in git stow task zsh; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$tool"
  else
    fail "$tool (not installed)"
    note "→ see docs/guides/packages-setup.md"
  fi
done

# --- Stow linkage ------------------------------------------------------------
# Every managed file must exist in $HOME as a symlink pointing back into THIS repo.
# A file present in the repo but unlinked in $HOME is the classic "pulled a new
# version, forgot to re-stow" drift: index.zsh guards the absence into silence.

section "Stow linkage"

PKG_TOTAL=0
PKG_STOWED=0

for pkg_dir in "$REPO_ROOT"/stow/common/*/; do
  [[ -d "$pkg_dir" ]] || continue
  pkg=$(basename -- "$pkg_dir")
  PKG_TOTAL=$((PKG_TOTAL + 1))

  missing=0
  foreign=0
  linked=0
  managed=0

  while IFS= read -r file; do
    rel=${file#"$pkg_dir"}
    case "$rel" in
      README.md | .stow-local-ignore | *.example | tests/*) continue ;;
    esac
    managed=$((managed + 1))
    target="$HOME/$rel"

    if [[ -L "$target" ]]; then
      resolved=$(resolve_link "$target")
      if [[ "$resolved" == "$REPO_ROOT"/* ]]; then
        linked=$((linked + 1))
      else
        foreign=$((foreign + 1))
        [[ $VERBOSE -eq 1 ]] && note "foreign link: ~/$rel -> ${resolved:-<unresolvable>}"
      fi
    else
      missing=$((missing + 1))
      [[ $VERBOSE -eq 1 ]] && note "not linked: ~/$rel"
    fi
  done < <(find "$pkg_dir" -type f | sort)

  if [[ $managed -eq 0 ]]; then
    skip "$pkg (no stowable files)"
  elif [[ $linked -eq 0 ]]; then
    skip "$pkg (not stowed — $managed file(s) available)"
  elif [[ $missing -eq 0 && $foreign -eq 0 ]]; then
    pass "$pkg ($linked/$managed linked)"
    PKG_STOWED=$((PKG_STOWED + 1))
  else
    PKG_STOWED=$((PKG_STOWED + 1))
    if [[ $missing -gt 0 ]]; then
      fail "$pkg — $missing of $managed file(s) not linked into \$HOME"
      note "→ new files landed since this package was stowed. Dry-run, then re-stow:"
      note "  stow --dir=stow/common --target=\"\$HOME\" --no-folding --simulate $pkg"
    fi
    if [[ $foreign -gt 0 ]]; then
      fail "$pkg — $foreign link(s) point outside this repo"
      note "→ another dotfiles checkout may own them; re-run with --verbose"
    fi
  fi
done

info "$PKG_STOWED of $PKG_TOTAL package(s) stowed"

# --- Directory folding (ADR-0024) --------------------------------------------
# A stowed config dir must be a REAL directory of per-file symlinks. If the
# directory itself is a symlink, stow folded it and local-only files (local.zsh,
# omp caches) cannot live alongside the managed ones.

section "Directory folding (ADR-0024)"

folding_checked=0
for cfg in "$HOME"/.config/*/; do
  [[ -d "$cfg" ]] || continue
  name=$(basename -- "$cfg")
  [[ -d "$REPO_ROOT/stow/common/$name/.config/$name" ]] || continue
  folding_checked=$((folding_checked + 1))
  if [[ -L "${cfg%/}" ]]; then
    fail "~/.config/$name is a symlink (stow folded the directory)"
    note "→ re-stow with --no-folding; see docs/guides/zsh-setup.md"
  else
    pass "~/.config/$name is a real directory"
  fi
done
[[ $folding_checked -eq 0 ]] && skip "no stowed config directories found"

# --- Zsh activation (ADR-0027) -----------------------------------------------

section "Zsh activation"

if [[ -f "$HOME/.zshrc" ]]; then
  if [[ -L "$HOME/.zshrc" ]]; then
    fail "~/.zshrc is a symlink — it must stay unmanaged (ADR-0027)"
  else
    pass "~/.zshrc is a real, unmanaged file"
  fi

  if grep -q 'config/zsh/index.zsh' "$HOME/.zshrc" 2>/dev/null; then
    pass "managed block present in ~/.zshrc"
  else
    fail "managed block absent from ~/.zshrc — the layer never loads"
    note "→ task zsh:bootstrap:dry-run"
  fi
else
  skip "~/.zshrc absent (zsh package not activated)"
fi

if [[ -r "$HOME/.config/zsh/index.zsh" ]]; then
  pass "index.zsh readable"
else
  skip "index.zsh not present (zsh package not stowed)"
fi

# --- PATH placement (ADR-0062) -----------------------------------------------
# Static detection of the trap that ADR-0062 documents: PATH set in local.zsh,
# which is sourced LAST — after every guard and after compinit. Line numbers only;
# local.zsh is private and its contents are never printed.

section "PATH placement (ADR-0062)"

LOCAL_ZSH="$HOME/.config/zsh/local.zsh"
if [[ -r "$LOCAL_ZSH" ]]; then
  hits=$(grep -nE '^[[:space:]]*(export[[:space:]]+PATH=|PATH=|.*brew[[:space:]]+shellenv)' \
    "$LOCAL_ZSH" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')
  if [[ -n "${hits// /}" ]]; then
    warn "local.zsh sets PATH/FPATH at line(s): ${hits% }"
    note "→ local.zsh is sourced last, so this lands after every 'command -v' guard"
    note "  and after compinit. Move it into ~/.zshrc ABOVE the managed block."
    note "  See docs/decisions/0062-*.md"
  else
    pass "local.zsh does not set PATH"
  fi
else
  skip "no local.zsh on this machine"
fi

# --- Live shell probe --------------------------------------------------------
# The decisive test. Start zsh with a deliberately minimal PATH — the situation a
# terminal launched from a desktop session is in — and ask what actually got
# registered. A tool that is installed but whose completion does not appear is
# the ADR-0062 failure, and it is invisible any other way.

section "Live shell probe"

if ! command -v zsh >/dev/null 2>&1; then
  skip "zsh not installed — probe unavailable"
elif [[ ! -r "$HOME/.config/zsh/index.zsh" ]]; then
  skip "zsh package not stowed — probe unavailable"
else
  PROBE=$(env -i \
    HOME="$HOME" \
    TERM=xterm \
    HISTFILE="$SANDBOX/probe_history" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin \
    zsh -ic '
      print -r -- "herdr=${+_comps[herdr]}"
      print -r -- "task=${+_comps[task]}"
      print -r -- "ssh=${+_comps[ssh]}"
      print -r -- "speed=${+functions[speed]}"
      print -r -- "cd_is=$(whence -w cd 2>/dev/null)"
      # Assign to a real array first: ${#${(M)arr:#pat}} measures the STRING
      # length of the joined result, not the element count.
      zhooks=(${(M)chpwd_functions:#*zoxide*})
      print -r -- "zoxide_hooks=${#zhooks}"
      print -r -- "compinit=${+functions[compinit]}"
    ' 2>/dev/null)

  probe_val() { printf '%s\n' "$PROBE" | grep "^$1=" | head -1 | cut -d= -f2-; }

  if [[ -z "$PROBE" ]]; then
    warn "probe shell produced no output — cannot verify registration"
  else
    # Completions whose layer is guarded on the tool being findable.
    for tool in herdr task; do
      if ! command -v "$tool" >/dev/null 2>&1; then
        skip "$tool completion ($tool not installed)"
      elif [[ "$(probe_val "$tool")" == "1" ]]; then
        pass "$tool completion registers in a fresh shell"
      else
        fail "$tool is installed but its completion does NOT register in a fresh shell"
        note "→ this is the ADR-0062 trap: $tool is not on PATH yet when its layer"
        note "  loads, so the guard returns and registers nothing. It will appear to"
        note "  work after 'exec zsh', because PATH/FPATH are exported and inherited."
        note "  Fix: set PATH in ~/.zshrc ABOVE the managed block."
      fi
    done

    if command -v cloudflare-speed-cli >/dev/null 2>&1; then
      [[ "$(probe_val speed)" == "1" ]] &&
        pass "speed helpers defined" ||
        fail "cloudflare-speed-cli installed but 'speed' is undefined (see ADR-0062)"
    else
      skip "speed helpers (cloudflare-speed-cli not installed)"
    fi

    [[ "$(probe_val ssh)" == "1" ]] &&
      pass "ssh completion registers" ||
      warn "ssh completion did not register"

    if command -v zoxide >/dev/null 2>&1; then
      hooks=$(probe_val zoxide_hooks)
      cd_is=$(probe_val cd_is)
      if [[ "$hooks" == "1" && "$cd_is" == *function* ]]; then
        pass "zoxide active (single chpwd hook, cd overridden)"
      elif [[ "${hooks:-0}" -gt 1 ]]; then
        warn "zoxide registered $hooks chpwd hooks — initialised more than once"
        note "→ a leftover 'eval \"\$(zoxide init …)\"' in local.zsh duplicates"
        note "  what tools.zsh already does. Remove it; see ADR-0062."
      else
        warn "zoxide installed but not active in a fresh shell"
      fi
    else
      skip "zoxide (not installed)"
    fi
  fi
fi

# --- Optional tooling --------------------------------------------------------
# Absence is legitimate here — layers no-op by design. Reported so that "the
# feature is missing" is never mistaken for "the feature is broken".

section "Optional tooling"

for tool in fzf zoxide eza bat oh-my-posh nvim jq herdr task git-cliff cloudflare-speed-cli; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$tool"
  else
    info "$tool absent — its layer is inert (not an error)"
  fi
done

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  pass "zinit"
else
  warn "zinit not found at $ZINIT_HOME — plugins.zsh prints an error at startup"
  note "→ one-time manual clone, never automatic (ADR-0020):"
  note "  see docs/shell-dependencies.md"
fi

# --- Git package -------------------------------------------------------------

section "Git configuration"

if command -v git >/dev/null 2>&1 && [[ -d "$HOME/.config/git" ]]; then
  if git config --global --get-all include.path 2>/dev/null | grep -q 'config-common'; then
    pass "managed git include wired into global config"
  else
    warn "~/.config/git exists but the managed include is not wired"
    note "→ task git:bootstrap:dry-run"
  fi
else
  skip "git package not stowed"
fi

# --- Version drift -----------------------------------------------------------
# Offline by design: local refs only, no fetch. A doctor should not need network.

section "Version"

if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  head_sha=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null)
  latest_tag=$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "")
  if [[ -n "$latest_tag" ]]; then
    behind=$(git -C "$REPO_ROOT" rev-list --count "$latest_tag..HEAD" 2>/dev/null || echo 0)
    info "HEAD $head_sha — newest local tag $latest_tag (+$behind commit(s) since)"
  else
    info "HEAD $head_sha — no tags in this checkout"
  fi
  if [[ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]]; then
    info "working tree has uncommitted changes"
  fi
  note "tags are read locally; run 'git fetch --tags' to compare against origin"
fi

# --- Summary -----------------------------------------------------------------

section "Summary"

if [[ $FAILED -eq 0 && $WARNED -eq 0 ]]; then
  echo "Healthy — no failures, no warnings."
elif [[ $FAILED -eq 0 ]]; then
  echo "Usable — $WARNED warning(s), no failures."
else
  echo "$FAILED failure(s), $WARNED warning(s)."
fi

[[ $FAILED -gt 0 ]] && exit 1
exit 0
