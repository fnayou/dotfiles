#!/usr/bin/env bash
# Claude Code statusLine — mirrors Oh My Posh theme (Catppuccin Macchiato).
# Managed by the dotfiles `claude` package; theme source is the `omp` package.
# Segments: OS icon | model | path (depth-limited) | git branch+status | PR # | ctx % | caveman badge
# Colors match omp.toml: mauve #c6a0f6, teal #8bd5ca, blue #8aadf4, green #a6da95, yellow #eed49f

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# --- OS icon (mauve #c6a0f6) ---
# Nerd Font glyphs are stored as \u escapes (pure ASCII in source) and rendered with
# printf, so the private-use codepoints can never be stripped by an editor.
os_id=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
if [[ "$OSTYPE" == "darwin"* ]]; then
  os_esc=''              # Apple (nf-fa-apple)
elif [[ "$os_id" == "endeavouros" ]]; then
  os_esc=''             # EndeavourOS (nf-linux-endeavour)
elif [[ "$os_id" == "arch" || -f /etc/arch-release ]]; then
  os_esc=''             # Arch (nf-linux-archlinux)
elif [[ "$os_id" == "debian" ]]; then
  os_esc=''             # Debian (nf-linux-debian)
else
  os_esc=''             # Linux (nf-fa-linux / Tux)
fi
os_icon=$(printf "$os_esc")
printf '\033[38;2;198;160;246m%s \033[0m' "$os_icon"

# --- Model (teal #8bd5ca) ---
model=$(echo "$input" | jq -r '.model.display_name // empty')
[[ -n "$model" ]] && printf '\033[38;2;139;213;202m%s \033[0m' "$model"

# --- Path segment (blue #8aadf4) ---
# Replicate OMP "full" style with max_depth=3, home_icon="~"
display_path="$cwd"
display_path="${display_path/#$HOME/~}"
# Truncate to last 3 components if deeper
IFS='/' read -ra parts <<< "$display_path"
if (( ${#parts[@]} > 3 )); then
  display_path=".../${parts[-3]}/${parts[-2]}/${parts[-1]}"
fi
printf '\033[38;2;138;173;244m%s\033[0m' "$display_path"

# --- Git segment (green #a6da95) ---
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -c core.fsmonitor= --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  # Truncate branch to 25 chars with ellipsis (matches omp.toml branch_max_length)
  if (( ${#branch} > 25 )); then
    branch="${branch:0:25}…"
  fi
  git_str=" on ${branch}"
  # Working tree changes
  if ! git -c core.fsmonitor= --no-optional-locks -C "$cwd" diff --quiet 2>/dev/null; then
    git_str+=" ●"
  fi
  # Staged changes
  if ! git -c core.fsmonitor= --no-optional-locks -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_str+=" ✚"
  fi
  # Ahead/behind
  upstream=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
  if [[ -n "$upstream" ]]; then
    ahead_behind=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null)
    ahead=$(echo "$ahead_behind" | cut -f1)
    behind=$(echo "$ahead_behind" | cut -f2)
    (( ahead > 0 )) && git_str+=" ↑"
    (( behind > 0 )) && git_str+=" ↓"
  fi
  printf '\033[38;2;166;218;149m%s\033[0m' "$git_str"

  # --- GitHub PR for current branch (mauve #c6a0f6; cached, non-blocking) ---
  # `gh pr view` is a ~0.5s network call — too slow to run on every render. Cache the
  # open-PR number per repo+branch and refresh in the background so the statusLine never
  # blocks; the number appears one render after the branch first gains a PR. Nerd Font
  # glyph stored as an octal escape (pure ASCII) and rendered with printf, like the OS icon.
  if command -v gh >/dev/null 2>&1 && [[ -n "$branch" ]]; then
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
    mkdir -p "$cache_dir" 2>/dev/null
    toplevel=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    cache_key="${toplevel//\//_}__${branch//\//_}"
    cache_file="$cache_dir/pr_${cache_key}"
    ttl=120
    now=$(date +%s)
    mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    if (( now - mtime > ttl )); then
      # Record every attempt (even "no PR" → empty file) so the TTL throttles re-runs.
      ( pr=$(gh pr view "$branch" --json number,state \
               -q 'select(.state=="OPEN") | .number' 2>/dev/null)
        printf '%s' "$pr" >"$cache_file.tmp" 2>/dev/null \
          && mv -f "$cache_file.tmp" "$cache_file" 2>/dev/null ) >/dev/null 2>&1 &
      disown 2>/dev/null
    fi
    pr_num=""
    [[ -f "$cache_file" ]] && pr_num=$(<"$cache_file")
    if [[ "$pr_num" =~ ^[0-9]+$ ]]; then
      gh_icon=$(printf '\357\202\233')   # GitHub (nf-fa-github, U+F09B)
      printf ' \033[38;2;198;160;246m%s #%s\033[0m' "$gh_icon" "$pr_num"
    fi
  fi
fi

# --- Context window usage (yellow #eed49f; null before first API call / after compact) ---
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [[ -n "$ctx" ]]; then
  ctx=${ctx%%.*}   # truncate any decimal
  printf ' \033[38;2;238;212;159m%s%% ctx\033[0m' "$ctx"
fi

# --- Caveman badge (chained; optional) ---
# When the caveman plugin owns the statusLine on a fresh install it renders its own
# badge. Here we call its hardened, self-contained script to append the [CAVEMAN]
# badge + token-savings suffix. No-op when caveman is inactive or not installed.
caveman_sl="$HOME/.claude/plugins/marketplaces/caveman/src/hooks/caveman-statusline.sh"
if [[ -x "$caveman_sl" || -f "$caveman_sl" ]]; then
  badge=$(bash "$caveman_sl" 2>/dev/null)
  [[ -n "$badge" ]] && printf ' %s' "$badge"
fi
