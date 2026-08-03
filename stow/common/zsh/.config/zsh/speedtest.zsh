# speedtest.zsh — cloudflare-speed-cli helpers. Guarded; no-op without the binary.
#
# cloudflare-speed-cli ships NO configuration file — every knob is a CLI flag. This
# file therefore IS the config layer: repo defaults live in the variables below, and
# ~/.config/zsh/local.zsh (sourced last, git-ignored) overrides them per machine.
#
# Nothing here runs a test at shell startup: the guard is the only command executed at
# source time.
#
# History is the tool's own: with --auto-save (default true) every run is written as one
# JSON file under ${XDG_DATA_HOME:-$HOME/.local/share}/cloudflare-speed-cli/runs/, and
# `speed-history` exports the whole set to a single CSV. Note that --export-csv writes
# only the current run and TRUNCATES its target, so it is not an append log.
# See docs/guides/speedtest-setup.md.

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

# speed-log — silent run for cron/timers. The result goes to the tool's own auto-saved
# history; stdout is discarded, so only errors surface (cron mails those). --silent is
# rejected without --json, hence both flags.
speed-log() {
  speed --json --silent "$@" >/dev/null
}

# speed-history — export every auto-saved run to one CSV. Runs no test.
# Optional argument: output path (default: <XDG state>/cloudflare-speed-cli/history.csv).
speed-history() {
  local out="${1:-${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli/history.csv}"
  mkdir -p "${out:h}" || return 1
  cloudflare-speed-cli --export-all-csv "$out"
}
