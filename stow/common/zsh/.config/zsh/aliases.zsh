# aliases.zsh — portable aliases

# --- File listing (eza / ls fallback) ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --long'
  alias ll='eza --icons --all --long'
  alias tree='eza --icons --tree'
else
  alias ll='ls -ahl'
fi

# --- Safety overrides ---
alias grep='grep --color=auto'
alias cp='cp -iv'
alias rm='rm -i'
alias mv='mv -iv'
# --- Suffix aliases (bat) ---
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  alias -s md=bat
  alias -s txt=bat
  alias -s log=bat
fi

# --- Image preview (chafa) ---
# cat sends image files to chafa and everything else to bat (or the real cat
# when bat is absent). Calls without an image, and every call whose output is
# not a terminal, keep today's behaviour exactly.
if command -v chafa >/dev/null 2>&1; then
  _cat_text() {
    if (( $+commands[bat] )); then bat "$@"; else command cat "$@"; fi
  }

  _is_image() {
    [[ -f $1 ]] || return 1
    case ${1:e:l} in
      (png|jpg|jpeg|gif|tif|tiff|webp) return 0 ;;
    esac
    return 1
  }

  # Show image files with chafa. herdr answers kitty graphics but chafa cannot
  # detect it there, so force kitty inside herdr. Height leaves the prompt visible.
  imgview() {
    if [[ ! -t 1 ]]; then _cat_text "$@"; return; fi
    local -a opts=(--animate off -s "x$(( LINES > 9 ? LINES - 4 : LINES ))")
    [[ $TERM_PROGRAM == herdr ]] && opts=(-f kitty $opts)
    local f
    for f in "$@"; do
      [[ $f == -* ]] && f=./$f   # chafa reads `--` as a file name
      chafa $opts "$f"
    done
  }

  unalias cat 2>/dev/null       # drop the bat alias; `function cat` avoids parse-time alias expansion
  function cat {
    local a has_image=0
    for a in "$@"; do _is_image "$a" && { has_image=1; break; }; done
    if (( ! has_image )) || [[ ! -t 1 ]]; then _cat_text "$@"; return; fi
    local -a bat_opts files
    for a in "$@"; do
      if [[ $a == -* ]] && ! _is_image "$a"; then bat_opts+=("$a"); else files+=("$a"); fi
    done
    for a in "${files[@]}"; do
      if _is_image "$a"; then imgview "$a"; else _cat_text "${bat_opts[@]}" "$a"; fi
    done
  }

  for _ext in png jpg jpeg gif tif tiff webp; do
    alias -s $_ext=imgview ${(U)_ext}=imgview
  done
  unset _ext
fi

# --- Functions ---
sizeof(){ du -sh ./*; }

# List the directory after every `cd`, but only at a real terminal. Coding
# agents inherit this hook and run `cd` with their output captured; there the
# eza listing has hung their shell for minutes, so skip it for them.
chpwd() {
  [[ -t 1 ]] && ll
}
