#!/usr/bin/env bash
# os-maintenance.sh — OS-aware system maintenance helper.
#
# Usage:
#   bash scripts/os-maintenance.sh update         # sync + upgrade packages (interactive)
#   bash scripts/os-maintenance.sh clean          # DRY RUN: report what cleanup would remove
#   bash scripts/os-maintenance.sh clean --apply  # actually perform the cleanup (destructive)
#
# Concerns are separated (PRD 0018, Architecture 0018):
#   - update : sync + upgrade. Forward-only by nature.
#   - clean  : orphans, package-cache pruning, journal vacuum. NON-DESTRUCTIVE by default;
#              real deletion only with --apply, which re-prints the report first.
#
# Out of scope by design: this script never runs `pacdiff`, edits mirrorlist, re-ranks mirrors,
# touches $HOME, runs stow, or schedules itself. See docs/guides/os-maintenance.md for the manual
# mirrorlist / pacdiff runbook.

set -euo pipefail

# --- Tunable defaults (Architecture Decision 3) ---
readonly PACCACHE_KEEP=3            # cached versions to keep per package
readonly JOURNAL_VACUUM_SIZE=200M   # cap for the persistent systemd journal

usage() {
  cat >&2 <<'EOF'
Usage: os-maintenance.sh <command> [--apply]

Commands:
  update          Sync and upgrade installed packages (interactive).
  clean           Report what cleanup would remove (dry run; deletes nothing).
  clean --apply   Perform the cleanup (destructive: removes orphans, prunes cache, vacuums journal).

Unsupported OS or unknown command exits non-zero.
EOF
}

# ---------------------------------------------------------------------------
# Arch / EndeavourOS
# ---------------------------------------------------------------------------

arch_update() {
  echo ":: Arch — sync + upgrade"
  if command -v yay >/dev/null 2>&1; then
    yay -Syu                     # AUR helper; must NOT run as root
  else
    sudo pacman -Syu
  fi
}

arch_clean_report() {
  echo ":: Arch cleanup — report (nothing is removed)"
  echo ""

  echo "Orphaned packages (pacman -Qtdq):"
  local orphans
  orphans="$(pacman -Qtdq 2>/dev/null || true)"
  if [[ -n "$orphans" ]]; then
    echo "$orphans" | sed 's/^/  /'
  else
    echo "  (none)"
  fi
  echo ""

  echo "Package cache (keep last $PACCACHE_KEEP):"
  if command -v paccache >/dev/null 2>&1; then
    paccache -dvk"$PACCACHE_KEEP" || true
    paccache -dvuk0 || true
  else
    echo "  paccache not found (install pacman-contrib to prune the cache)"
  fi
  echo ""

  echo "Journal disk usage:"
  journalctl --disk-usage 2>/dev/null | sed 's/^/  /' || echo "  (unavailable)"
  echo "  -> would vacuum to $JOURNAL_VACUUM_SIZE"
  echo ""
}

arch_clean_apply() {
  arch_clean_report
  echo ":: Arch cleanup — applying"
  echo ""

  local orphans
  orphans="$(pacman -Qtdq 2>/dev/null || true)"
  if [[ -n "$orphans" ]]; then
    # shellcheck disable=SC2086
    sudo pacman -Rns $orphans
  else
    echo "No orphans to remove."
  fi

  if command -v paccache >/dev/null 2>&1; then
    sudo paccache -rk"$PACCACHE_KEEP"   # keep last N of installed packages
    sudo paccache -ruk0                 # remove all cached uninstalled packages
  else
    echo "paccache not found — skipping cache prune (install pacman-contrib)."
  fi

  sudo journalctl --vacuum-size="$JOURNAL_VACUUM_SIZE"
  echo ""
  echo "Done. Note: mirrorlist / pacdiff are intentionally NOT handled here —"
  echo "see docs/guides/os-maintenance.md for the manual runbook."
}

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------

macos_require_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew (brew) not found — required for macOS maintenance." >&2
    exit 1
  fi
}

macos_update() {
  macos_require_brew
  echo ":: macOS — update + upgrade (Homebrew)"
  brew update
  brew upgrade
}

macos_clean_report() {
  macos_require_brew
  echo ":: macOS cleanup — report (nothing is removed)"
  echo ""
  echo "brew cleanup (dry run):"
  brew cleanup --dry-run || true
  echo ""
  echo "brew autoremove (dry run):"
  brew autoremove --dry-run || true
  echo ""
  echo "brew doctor:"
  brew doctor || true   # advisory; non-zero exit is informational
  echo ""
}

macos_clean_apply() {
  macos_clean_report
  echo ":: macOS cleanup — applying"
  brew cleanup
  brew autoremove
  echo ""
  echo "Done."
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

detect_os() {
  if [[ "${OSTYPE:-}" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  else
    echo "unsupported"
  fi
}

main() {
  local command="${1:-}"
  local apply="${2:-}"

  if [[ -z "$command" ]]; then
    usage
    exit 1
  fi

  local os
  os="$(detect_os)"
  if [[ "$os" == "unsupported" ]]; then
    echo "Unsupported OS: ${OSTYPE:-unknown}" >&2
    exit 1
  fi

  case "$command" in
    update)
      "${os}_update"
      ;;
    clean)
      if [[ "$apply" == "--apply" ]]; then
        "${os}_clean_apply"
      elif [[ -z "$apply" ]]; then
        "${os}_clean_report"
        echo "(dry run — nothing removed. Re-run with --apply to perform cleanup.)"
      else
        echo "Unknown flag for clean: $apply" >&2
        usage
        exit 1
      fi
      ;;
    *)
      echo "Unknown command: $command" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
