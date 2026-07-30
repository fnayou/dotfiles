#!/usr/bin/env bash
# Claude Code statusLine — mirrors Oh My Posh theme (Catppuccin Macchiato).
# Managed by the dotfiles `claude` package; theme source is the `omp` package.
# Segments: OS icon | model | path (depth-limited) | git branch+status | PR/MR | ctx % | rtk savings | caveman badge
# Colors match omp.toml: mauve #c6a0f6, teal #8bd5ca, blue #8aadf4, green #a6da95, yellow #eed49f
# Exception: rtk savings uses 256-color 172 (orange) to match the caveman plugin badge, not omp.

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
# Truncate to last 3 components if deeper. Use positive indices computed from the
# array length — negative subscripts (${parts[-1]}) need bash >= 4.3, but macOS
# ships bash 3.2, where they raise "bad array subscript" and collapse the path to
# "...///". n-1/-2/-3 are safe here because this branch only runs when n > 3.
IFS='/' read -ra parts <<< "$display_path"
n=${#parts[@]}
if (( n > 3 )); then
  display_path=".../${parts[$((n-3))]}/${parts[$((n-2))]}/${parts[$((n-1))]}"
fi
printf '\033[38;2;138;173;244m%s\033[0m' "$display_path"

# --- Git segment (green #a6da95) ---
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -c core.fsmonitor= --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  # Keep the full ref for machine use (PR/MR lookup, cache key). Display is
  # truncated to 25 chars with an ellipsis (matches omp.toml branch_max_length) —
  # passing the ellipsis'd name to gh/glab would look up a non-existent branch.
  branch_full="$branch"
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

  # --- Merge/pull request for current branch (mauve #c6a0f6; cached, non-blocking) ---
  # `gh`/`glab` are ~0.5s network calls — too slow per render. Cache the open request
  # number per repo+branch and refresh in the background so the statusLine never blocks;
  # the number appears one render after the branch first gains a request.
  #
  # Forge is detected from the origin remote URL: GitHub -> gh, "PR", "#" sigil, github
  # glyph; GitLab -> glab, "MR", "!" sigil (GitLab's MR convention), gitlab glyph.
  #
  # The glyphs are Nerd Font private-use codepoints; a shell cannot tell whether the
  # terminal font actually has them, so an automatic icon->text fallback is impossible.
  # Set STATUSLINE_NERD_FONT=0 to render the ASCII label ("PR"/"MR") instead of the icon.
  remote_url=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" remote get-url origin 2>/dev/null)
  forge=""; forge_cli=""
  if [[ "$remote_url" == *gitlab* ]]; then
    forge="gitlab"; forge_cli="glab"
  elif [[ "$remote_url" == *github* ]]; then
    forge="github"; forge_cli="gh"
  fi
  if [[ -n "$forge" ]] && command -v "$forge_cli" >/dev/null 2>&1 && [[ -n "$branch_full" ]]; then
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
    mkdir -p "$cache_dir" 2>/dev/null
    toplevel=$(git -c core.fsmonitor= --no-optional-locks -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    cache_key="${toplevel//\//_}__${branch_full//\//_}"
    cache_file="$cache_dir/mr_${forge}_${cache_key}"
    ttl=120
    now=$(date +%s)
    # GNU form first: on Linux `stat -f` means --file-system, which exits non-zero but still
    # prints a filesystem block to stdout, so the BSD-first order concatenated that garbage with
    # the fallback's timestamp. BSD/macOS stat rejects -c cleanly (no stdout), so this order is
    # safe on both. The regex guard keeps any future surprise out of the arithmetic below.
    mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
    [[ "$mtime" =~ ^[0-9]+$ ]] || mtime=0
    if (( now - mtime > ttl )); then
      # Record every attempt (even "no request" -> empty file) so the TTL throttles re-runs.
      if [[ "$forge" == "github" ]]; then
        ( num=$(gh pr view "$branch_full" --json number,state \
                  -q 'select(.state=="OPEN") | .number' 2>/dev/null)
          printf '%s' "$num" >"$cache_file.tmp" 2>/dev/null \
            && mv -f "$cache_file.tmp" "$cache_file" 2>/dev/null ) >/dev/null 2>&1 &
      else
        # GitLab MR number is the project-scoped iid (the "!123" the UI shows).
        ( num=$(glab mr list --source-branch "$branch_full" -F json \
                  --jq '.[0].iid // empty' 2>/dev/null)
          printf '%s' "$num" >"$cache_file.tmp" 2>/dev/null \
            && mv -f "$cache_file.tmp" "$cache_file" 2>/dev/null ) >/dev/null 2>&1 &
      fi
      disown 2>/dev/null
    fi
    mr_num=""
    [[ -f "$cache_file" ]] && mr_num=$(<"$cache_file")
    if [[ "$mr_num" =~ ^[0-9]+$ ]]; then
      if [[ "$forge" == "github" ]]; then
        label="PR"; sigil="#"; glyph=$(printf '\357\202\233')   # GitHub (nf-fa-github, U+F09B)
      else
        label="MR"; sigil="!"; glyph=$(printf '\357\212\226')   # GitLab (nf-fa-gitlab, U+F296)
      fi
      [[ "${STATUSLINE_NERD_FONT:-1}" == "0" ]] && marker="$label" || marker="$glyph"
      printf ' \033[38;2;198;160;246m%s %s%s\033[0m' "$marker" "$sigil" "$mr_num"
    fi
  fi
fi

# --- Context window usage (yellow #eed49f; null before first API call / after compact) ---
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [[ -n "$ctx" ]]; then
  ctx=${ctx%%.*}   # truncate any decimal
  printf ' \033[38;2;238;212;159m%s%% ctx\033[0m' "$ctx"
fi

# --- rtk savings (orange 256-color 172; matches caveman badge = stats zone; optional) ---
# rtk gain --format json is a ~13ms local DB read, cheap enough to run inline on
# every render (unlike the gh network call above). --project filters to the exact
# current working directory — not the whole repo, so cd'ing into a subdirectory
# shows only that directory's tokens saved + avg savings %, not the global total.
# In a Claude Code session cwd is the workspace dir (usually the repo root).
# Nerd Font bolt glyph stored as octal (pure ASCII), like the OS icon.
# No-op when rtk is absent or has no recorded runs for this directory.
if command -v rtk >/dev/null 2>&1; then
  rtk_json=$(rtk gain --project --format json 2>/dev/null)
  if [[ -n "$rtk_json" ]]; then
    read -r rtk_saved rtk_pct < <(echo "$rtk_json" | jq -r '"\(.summary.total_saved // 0) \(.summary.avg_savings_pct // 0)"')
    if [[ "$rtk_saved" =~ ^[0-9]+$ ]] && (( rtk_saved > 0 )); then
      # Humanize saved tokens: 879302 -> 879K, 1347025 -> 1.3M
      if (( rtk_saved >= 1000000 )); then
        rtk_h=$(awk -v n="$rtk_saved" 'BEGIN{printf "%.1fM", n/1000000}')
      elif (( rtk_saved >= 1000 )); then
        rtk_h=$(awk -v n="$rtk_saved" 'BEGIN{printf "%dK", n/1000}')
      else
        rtk_h="$rtk_saved"
      fi
      rtk_pct=${rtk_pct%%.*}   # truncate decimal
      rtk_icon=$(printf '\357\203\247')   # bolt (nf-fa-bolt, U+F0E7)
      printf ' \033[38;5;172m%s rtk %s↓ %s%%\033[0m' "$rtk_icon" "$rtk_h" "$rtk_pct"
    fi
  fi
fi

# --- Caveman badge (orange 256-color 172; optional) ---
# Mode badge + tokens saved, scoped to THIS session and THIS repository.
#
# We deliberately do not call caveman's own caveman-statusline.sh here. That
# script renders ~/.claude/.caveman-statusline-suffix, which is the sum of every
# caveman session ever recorded on this machine across every project — a
# machine-wide lifetime total sitting in a project-scoped status line, right next
# to the project-scoped rtk figure. See docs/prd/0021-caveman-session-scoped-savings.md.
#
# statusline-caveman.js recomputes the figure from this session's own
# transcript_path, reusing caveman's exported estimator rather than forking it.
# It is handed the payload we already captured in $input — stdin is read exactly
# once, at the top of this script, and never re-read by a segment.
# Plugin source: https://github.com/JuliusBrussee/caveman
# Sibling of this script. Stow links both files into ~/.claude/ side by side, so
# resolving relative to BASH_SOURCE works stowed and works when run from the repo
# for testing. Guard the no-slash case: ${x%/*} returns x unchanged when x has no
# directory part, which would build "statusline-command.sh/statusline-caveman.js".
caveman_dir="${BASH_SOURCE[0]%/*}"
[[ "$caveman_dir" == "${BASH_SOURCE[0]}" ]] && caveman_dir="."
caveman_seg="$caveman_dir/statusline-caveman.js"
if [[ -f "$caveman_seg" ]] && command -v node >/dev/null 2>&1; then
  badge=$(printf '%s' "$input" | node "$caveman_seg" 2>/dev/null)
  [[ -n "$badge" ]] && printf ' %s' "$badge"
else
  # No node, or the segment is missing (package not fully stowed). Fall back to
  # caveman's own script with its savings suffix switched OFF, so we degrade to
  # the mode badge alone — less information, never the wrong number.
  # Path is globbed, not hardcoded: Claude Code installs the plugin under
  # marketplaces/ (canonical) or cache/<name>/<name>/<hash>/ (versioned checkout),
  # and the hash changes per release. Prefer marketplaces; else fall back to the
  # newest cache checkout by mtime (hash dirs sort by hex, not by age, so a plain
  # glob could pick a stale version). The final -f test handles the empty result
  # from an unmatched glob, so a missing plugin is a clean no-op.
  caveman_sl="$HOME/.claude/plugins/marketplaces/caveman/src/hooks/caveman-statusline.sh"
  [[ -f "$caveman_sl" ]] || caveman_sl=$(ls -t "$HOME"/.claude/plugins/cache/caveman/*/*/src/hooks/caveman-statusline.sh 2>/dev/null | head -1)
  if [[ -f "$caveman_sl" ]]; then
    badge=$(CAVEMAN_STATUSLINE_SAVINGS=0 bash "$caveman_sl" 2>/dev/null)
    [[ -n "$badge" ]] && printf ' %s' "$badge"
  fi
fi

# The last command above is a `[[ ... ]] &&` short-circuit, which returns 1 when
# the badge is empty — the normal case for an inactive or absent caveman. That
# would make the whole status line exit non-zero on an ordinary render. Every
# segment here is optional by design, so the script always succeeds.
exit 0
