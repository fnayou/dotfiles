#!/usr/bin/env bash
# Sync repo-owned Codex settings into the live config file.
#
# Architecture (agreed 2026-10-15):
#   - The repo file stow/common/codex/.codex/config.toml is a TEMPLATE shipped
#     in the dotfiles. It is listed in stow/common/codex/.stow-local-ignore, so
#     Stow never links it: the live config must stay a regular file that Codex
#     may write generated state into (trust paths, onboarding, hook hashes).
#   - Sync is one-directional, repo -> live. Only keys the repo template
#     defines are written ("ours"). Everything the live file adds — generated
#     state or user TUI edits we do not ship — is preserved and reported as
#     live-only, never deleted and never copied back into the repo.
#
# Usage:
#   codex-sync.sh              status report: SYNCED/NOT SYNCED + ok/ko table
#   codex-sync.sh --inspect    same report
#   codex-sync.sh --apply      backup the live file, then apply the plan
#
# The report is colored on a terminal (ok=green, ko=red); NO_COLOR disables it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_CONFIG="$REPO_ROOT/stow/common/codex/.codex/config.toml"
LIVE_CONFIG="${HOME}/.codex/config.toml"

MODE="plan"
case "${1:-}" in
  "") MODE="plan" ;;
  --inspect) MODE="plan" ;;
  --apply) MODE="apply" ;;
  *)
    echo "usage: codex-sync.sh [--inspect|--apply]" >&2
    exit 2
    ;;
esac

if [[ ! -f "$REPO_CONFIG" ]]; then
  echo "MISSING: repo template not found: $REPO_CONFIG" >&2
  exit 1
fi

if [[ ! -f "$LIVE_CONFIG" ]]; then
  echo "MISSING: live config not found: $LIVE_CONFIG" >&2
  exit 1
fi

if [[ -L "$LIVE_CONFIG" ]]; then
  echo "REFUSED: $LIVE_CONFIG is a symlink — a Stow artifact. Never write" >&2
  echo "  into a managed symlink target. Unstow (stow --dir=stow/common" >&2
  echo "  --target=\"\$HOME\" --no-folding --delete codex) and re-run." >&2
  exit 1
fi

exec python3 - "$REPO_CONFIG" "$LIVE_CONFIG" "$MODE" <<'PYEOF'
import os
import sys
import time
import tomllib
from pathlib import Path

repo_path = Path(sys.argv[1])
live_path = Path(sys.argv[2])
mode = sys.argv[3]

plain = not sys.stdout.isatty() or os.environ.get("NO_COLOR")


def paint(text, code):
    return text if plain else f"\033[{code}m{text}\033[0m"


OK = paint("ok", "32")
KO = paint("ko", "31")
MISS = paint("ko", "31") + " (missing)"

# --- TOML emit helpers (stdlib tomllib parses but never writes) ---------
BARE_EXTRA = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")


def fmt_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(value, list):
        return "[" + ", ".join(fmt_value(item) for item in value) + "]"
    return str(value)


MAX_SHOWN = 72


def short_value(value):
    """Display-only: summarize long arrays; other values show in full."""
    if isinstance(value, list) and len(value) > 3:
        shown = ", ".join(fmt_value(item) for item in value[:2])
        more = len(value) - 2
        return f"[{len(value)} items] {shown} .. (+{more} more)"
    return fmt_value(value)


def fmt_key(key):
    if key and all(char in BARE_EXTRA for char in key):
        return key
    return '"' + key.replace("\\", "\\\\").replace('"', '\\"') + '"'


def dump_table(table, header, lines):
    """Emit one table: scalars first, then nested subtables as [a.b]."""
    if header:
        lines.append("")
        lines.append(f"[{header}]")
    for key, value in table.items():
        if not isinstance(value, dict):
            lines.append(f"{fmt_key(key)} = {fmt_value(value)}")
    for key, value in table.items():
        if isinstance(value, dict):
            child = f"{header}.{fmt_key(key)}" if header else fmt_key(key)
            dump_table(value, child, lines)


def merge_toml(repo_node, live_node):
    """Overwrite live keys the repo template defines, keep everything else."""
    for key, repo_value in repo_node.items():
        if isinstance(repo_value, dict):
            if not isinstance(live_node.get(key), dict):
                live_node[key] = {}
            merge_toml(repo_value, live_node[key])
        else:
            live_node[key] = repo_value


def deep_copy(value):
    return {k: deep_copy(v) if isinstance(v, dict) else v for k, v in value.items()}


with repo_path.open("rb") as handle:
    repo = tomllib.load(handle)
live_raw = live_path.read_bytes()
live = tomllib.loads(live_raw.decode())

# --- classify repo-owned parameters ------------------------------------
ok_rows = []     # (dotted_path, live_value)
ko_rows = []     # (dotted_path, live_value_or_None, repo_value)


def walk(repo_node, live_node, prefix):
    for key, repo_value in repo_node.items():
        path = f"{prefix}.{fmt_key(key)}" if prefix else fmt_key(key)
        if isinstance(repo_value, dict):
            walk(repo_value, live_node.get(key, {}), path)
            continue
        if key not in live_node:
            ko_rows.append((path, None, repo_value))
        elif live_node[key] != repo_value:
            ko_rows.append((path, live_node[key], repo_value))
        else:
            ok_rows.append((path, live_node[key]))


walk(repo, live, "")

live_only = []


def walk_live_only(live_node, repo_node, prefix):
    for key, live_value in live_node.items():
        path = f"{prefix}.{fmt_key(key)}" if prefix else fmt_key(key)
        if isinstance(live_value, dict):
            walk_live_only(live_value, repo_node.get(key, {}), path)
            continue
        if key not in repo_node:
            live_only.append((path, live_value))


walk_live_only(live, repo, "")

# --- human status report ------------------------------------------------
synced = not ko_rows
verdict = paint("SYNCED", "32") if synced else paint("NOT SYNCED", "31")
counts = f"{len(ok_rows)} ok, {len(ko_rows)} ko"
if live_only:
    counts += f", {len(live_only)} live-only"

report = ["codex sync status", "==================", ""]
report.append(f"repo : {repo_path}")
report.append(f"live : {live_path}  (regular file, not a symlink)")
report.append(f"STATUS: {verdict}  ({counts})")
report.append("")
report.append(f"parameters (repo: {repo_path.name})")
report.append("-" * 40)

width = max([len(path) for path, _ in ok_rows] + [len(path) for path, _, _ in ko_rows], default=0)
for path, value in ok_rows:
    report.append(f"{OK}  {path:<{width}}  {short_value(value)}")
for path, live_value, repo_value in ko_rows:
    if live_value is None:
        report.append(f"{MISS}  {path:<{width}}  (repo: {short_value(repo_value)})")
    else:
        report.append(f"{KO}  {path:<{width}}  live {short_value(live_value)} != repo {short_value(repo_value)}")

if mode != "apply":
    report.append("")
    report.append('DRY RUN — no changes written. execute: task codex:sync ARGS="--apply"')

# live-only state (generated machine data / local edits user does not ship) is
# counted in the STATUS verdict but never listed — the repo never writes it back.

print("\n".join(report))

if synced:
    if mode == "apply":
        print()
        print("apply: nothing to write, live already matches the repo template")
    sys.exit(0)
if mode != "apply":
    sys.exit(0)

# --- apply: backup live, merge, write ----------------------------------
backup = live_path.with_name(f"{live_path.name}.bak-{time.strftime('%Y%m%d%H%M%S')}")
backup.write_bytes(live_raw)
print()
print(f"backup created: {backup}")

merged = deep_copy(live)
merge_toml(repo, merged)

out = []
scalars = {k: v for k, v in merged.items() if not isinstance(v, dict)}
tables = {k: v for k, v in merged.items() if isinstance(v, dict)}
for key, value in scalars.items():
    out.append(f"{fmt_key(key)} = {fmt_value(value)}")
for key, value in tables.items():
    dump_table(value, fmt_key(key), out)

live_path.write_text("\n".join(out).lstrip("\n") + "\n")
print(f"applied: {live_path}")
print(f"verdict: {paint('SYNCED', '32')} — verify with: task codex:inspect")
PYEOF
