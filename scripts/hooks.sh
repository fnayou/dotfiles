#!/usr/bin/env bash
# Enable or disable this repository's opt-in Git hooks (.githooks/).
#
# The hooks only remind the operator to regenerate the art; they never change a file and always
# exit 0. Enabling them sets `core.hooksPath` in THIS repository's local Git config, nothing else.
#
# Usage:
#   hooks.sh status                 report the current setting (read-only)
#   hooks.sh install   [--apply]    DRY RUN by default; --apply sets core.hooksPath=.githooks
#   hooks.sh uninstall [--apply]    DRY RUN by default; --apply removes it, only if it is .githooks
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

HOOKS_DIR=".githooks"
ACTION="${1:-status}"
APPLY=0
[[ "${2:-}" == "--apply" ]] && APPLY=1
if [[ $# -gt 2 || ( $# -eq 2 && "${2}" != "--apply" ) ]]; then
  echo "usage: hooks.sh status | install [--apply] | uninstall [--apply]" >&2
  exit 2
fi

current="$(git config --local --get core.hooksPath || true)"

case "$ACTION" in
  status)
    echo "core.hooksPath (local): ${current:-<not set>}"
    for h in pre-commit pre-push; do
      if [[ -x "$HOOKS_DIR/$h" ]]; then echo "  $HOOKS_DIR/$h: present"; else echo "  $HOOKS_DIR/$h: MISSING or not executable"; fi
    done
    if [[ "$current" == "$HOOKS_DIR" ]]; then echo "ENABLED"; else echo "NOT ENABLED"; fi
    ;;
  install)
    if [[ "$current" == "$HOOKS_DIR" ]]; then echo "already enabled: core.hooksPath=$HOOKS_DIR"; exit 0; fi
    if [[ -n "$current" ]]; then
      echo "REFUSED: core.hooksPath is already set to '$current'. Not overwriting it." >&2
      exit 1
    fi
    for h in pre-commit pre-push; do
      [[ -x "$HOOKS_DIR/$h" ]] || { echo "MISSING: $HOOKS_DIR/$h is not an executable file" >&2; exit 1; }
    done
    echo "would run: git config --local core.hooksPath $HOOKS_DIR"
    if ((APPLY)); then
      git config --local core.hooksPath "$HOOKS_DIR"
      echo "enabled: core.hooksPath=$HOOKS_DIR (this repository only)"
    else
      echo "DRY RUN. To enable: task hooks:install ARGS='--apply'"
    fi
    ;;
  uninstall)
    if [[ -z "$current" ]]; then echo "nothing to do: core.hooksPath is not set"; exit 0; fi
    if [[ "$current" != "$HOOKS_DIR" ]]; then
      echo "REFUSED: core.hooksPath is '$current', not '$HOOKS_DIR'. Not touching it." >&2
      exit 1
    fi
    echo "would run: git config --local --unset core.hooksPath"
    if ((APPLY)); then
      git config --local --unset core.hooksPath
      echo "disabled: core.hooksPath removed"
    else
      echo "DRY RUN. To disable: task hooks:uninstall ARGS='--apply'"
    fi
    ;;
  *)
    echo "usage: hooks.sh status | install [--apply] | uninstall [--apply]" >&2
    exit 2
    ;;
esac
