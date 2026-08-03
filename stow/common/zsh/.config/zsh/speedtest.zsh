# speedtest.zsh — cloudflare-speed-cli helpers. Guarded; no-op without the binary.
#
# cloudflare-speed-cli ships NO configuration file — every knob is a CLI flag. This
# file therefore IS the config layer: repo defaults live in the variables below, and
# ~/.config/zsh/local.zsh (sourced last, git-ignored) overrides them per machine.
#
# Nothing here runs a test at shell startup: the guard is the only command executed at
# source time. `speed-log` is the sole writer, and only when you call it — it creates
# its own directory under XDG state and appends a CSV. See docs/guides/speedtest-setup.md.

command -v cloudflare-speed-cli >/dev/null 2>&1 || return

# Defaults — override in local.zsh or in the environment.
: "${SPEEDTEST_DOWNLOAD_DURATION:=10s}"
: "${SPEEDTEST_UPLOAD_DURATION:=10s}"
: "${SPEEDTEST_CONCURRENCY:=6}"

# speed — interactive TUI run with the defaults above; extra flags pass through.
speed() {
  cloudflare-speed-cli \
    --download-duration "$SPEEDTEST_DOWNLOAD_DURATION" \
    --upload-duration "$SPEEDTEST_UPLOAD_DURATION" \
    --concurrency "$SPEEDTEST_CONCURRENCY" \
    "$@"
}

# speed-json — machine-readable, no TUI. Pipe to jq.
speed-json() {
  speed --json "$@"
}

# speed-log — silent run appended to a monthly CSV under XDG state. Cron/timer friendly.
speed-log() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli"
  mkdir -p "$dir" || return 1
  speed --silent --export-csv "$dir/history-$(date +%Y%m).csv" "$@"
}
