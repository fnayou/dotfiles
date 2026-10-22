#!/usr/bin/env bash
# Sync the repo-owned Terminal.app profile into the live Terminal preferences.
#
# Architecture (PRD 0031, architecture 0027, plan 0035):
#   - The profile stow/macos/terminal/"Catppuccin Macchiato.terminal" is the source
#     of truth. It is listed in stow/macos/terminal/.stow-local-ignore, so Stow links
#     nothing: Terminal.app keeps its profiles inside the com.apple.Terminal
#     preference domain, not in a dotfile.
#   - Sync is one-directional, repo -> live. Only the profile named
#     "Catppuccin Macchiato" is added or replaced. Every other profile, and the
#     default profile, stay untouched unless --set-default is given.
#   - The domain is written with `defaults write ... -dict-add`, which goes through
#     cfprefsd, replaces exactly one key and is idempotent.
#
# Usage:
#   terminal-sync.sh                        status report (read-only): ok/ko table
#   terminal-sync.sh --apply                back up the domain, add or update the profile
#   terminal-sync.sh --apply --set-default  as above, then make it the default and startup profile
#   terminal-sync.sh --build                regenerate the .terminal file from the Alacritty
#                                           theme (writes inside the repository only)
#
# --apply refuses while Terminal.app is running: it keeps its profiles in memory and
# rewrites them on quit, which can drop a key added behind its back.
#
# TERMINAL_SYNC_DOMAIN exists for validation only. It accepts the live domain
# (com.apple.Terminal, the default) or a domain starting with
# com.example.terminal-sync-test; anything else exits 2. The running-Terminal guard
# and the backup always apply to the live domain.
#
# The report is colored on a terminal (ok=green, ko=red); NO_COLOR disables it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_FILE="$REPO_ROOT/stow/macos/terminal/Catppuccin Macchiato.terminal"
ALACRITTY_THEME="$REPO_ROOT/stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml"
LIVE_DOMAIN="com.apple.Terminal"
SCRATCH_PREFIX="com.example.terminal-sync-test"
DOMAIN="${TERMINAL_SYNC_DOMAIN:-$LIVE_DOMAIN}"

MODE="report"
APPLY=0
SET_DEFAULT=0
BUILD=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --set-default) SET_DEFAULT=1 ;;
    --build) BUILD=1 ;;
    *)
      echo "usage: terminal-sync.sh [--apply [--set-default]] | [--build]" >&2
      exit 2
      ;;
  esac
done

if ((SET_DEFAULT && !APPLY)); then
  echo "REFUSED: --set-default needs --apply." >&2
  exit 2
fi
if ((BUILD && (APPLY || SET_DEFAULT))); then
  echo "REFUSED: --build cannot be combined with --apply or --set-default." >&2
  exit 2
fi
if ((BUILD)); then
  MODE="build"
elif ((APPLY)); then
  MODE="apply"
fi

# Domain allowlist: the live domain, or a throwaway test domain. Nothing else.
if [[ "$DOMAIN" != "$LIVE_DOMAIN" && "$DOMAIN" != "$SCRATCH_PREFIX"* ]]; then
  echo "REFUSED: TERMINAL_SYNC_DOMAIN must be $LIVE_DOMAIN or start with $SCRATCH_PREFIX." >&2
  exit 2
fi

# macOS only, decided before any preference is read.
OS="$(bash "$REPO_ROOT/scripts/detect-os.sh" 2>/dev/null || true)"
if [[ "$OS" != "macos" ]]; then
  echo "UNSUPPORTED: Terminal.app exists on macOS only (detected: ${OS:-unknown}). Nothing changed." >&2
  exit 1
fi

if [[ "$MODE" != "build" ]]; then
  if ! command -v defaults >/dev/null 2>&1; then
    echo "MISSING: the macOS 'defaults' command was not found." >&2
    exit 1
  fi
  if [[ "$DOMAIN" == "$LIVE_DOMAIN" ]] && ! defaults read "$DOMAIN" >/dev/null 2>&1; then
    echo "MISSING: preference domain $DOMAIN not found. Open Terminal.app once, then retry." >&2
    exit 1
  fi
  if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "MISSING: profile not found: $PROFILE_FILE (run: task terminal:sync ARGS='--build')" >&2
    exit 1
  fi
fi

exec python3 -I - "$MODE" "$DOMAIN" "$LIVE_DOMAIN" "$SET_DEFAULT" "$PROFILE_FILE" "$ALACRITTY_THEME" "$HOME" <<'PYEOF'
import os
import plistlib
import subprocess
import sys
import time
import tomllib
from pathlib import Path

mode, domain, live_domain, set_default, profile_path, theme_path, home = sys.argv[1:8]
set_default = set_default == "1"
profile_path = Path(profile_path)
theme_path = Path(theme_path)
is_live = domain == live_domain

PROFILE_NAME = "Catppuccin Macchiato"
# Read once from the existing "Clear Dark" profile on 2026-10-22; the build never
# reads local preferences.
PROFILE_CURRENT_VERSION = 2.09
FONT_POSTSCRIPT = "JetBrainsMonoNF-Regular"
FONT_FILE_GLOB = "JetBrainsMonoNerdFont-Regular.*"
FONT_SIZE = 13.0
# Terminal.app cannot set a selection text color, so the rosewater selection of
# Alacritty and Ghostty would hide light text. Surface2 keeps it readable.
SELECTION_HEX = "#5b6078"

ANSI_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

use_color = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def paint(text, code):
    return f"\033[{code}m{text}\033[0m" if use_color else text


OK = paint("ok", "32")
KO = paint("ko", "31")


# --- archive builders (NSKeyedArchiver, same shape Terminal.app writes) ------------

def hex_to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def archive_color(hex_value):
    rgb = " ".join(f"{c / 255:.10g}" for c in hex_to_rgb(hex_value)).encode() + b"\x00"
    archive = {
        "$archiver": "NSKeyedArchiver",
        "$objects": [
            "$null",
            {"NSRGB": rgb, "NSColorSpace": 2, "$class": plistlib.UID(2)},
            {"$classname": "NSColor", "$classes": ["NSColor", "NSObject"]},
        ],
        "$top": {"root": plistlib.UID(1)},
        "$version": 100000,
    }
    return plistlib.dumps(archive, fmt=plistlib.FMT_BINARY)


def archive_font(postscript_name, size):
    archive = {
        "$archiver": "NSKeyedArchiver",
        "$objects": [
            "$null",
            {"NSSize": size, "NSfFlags": 16, "NSName": plistlib.UID(2), "$class": plistlib.UID(3)},
            postscript_name,
            {"$classname": "NSFont", "$classes": ["NSFont", "NSObject"]},
        ],
        "$top": {"root": plistlib.UID(1)},
        "$version": 100000,
    }
    return plistlib.dumps(archive, fmt=plistlib.FMT_BINARY)


def decode_color(blob):
    archive = plistlib.loads(blob)
    rgb = archive["$objects"][1]["NSRGB"].rstrip(b"\x00").split()
    return "#" + "".join(f"{round(float(c) * 255):02x}" for c in rgb[:3])


def build_profile():
    theme = tomllib.loads(theme_path.read_text())["colors"]
    profile = {
        "name": PROFILE_NAME,
        "type": "Window Settings",
        "ProfileCurrentVersion": PROFILE_CURRENT_VERSION,
        "BackgroundColor": archive_color(theme["primary"]["background"]),
        "TextColor": archive_color(theme["primary"]["foreground"]),
        "TextBoldColor": archive_color(theme["primary"]["foreground"]),
        "CursorColor": archive_color(theme["cursor"]["cursor"]),
        "SelectionColor": archive_color(SELECTION_HEX),
        "Font": archive_font(FONT_POSTSCRIPT, FONT_SIZE),
        "FontAntialias": True,
    }
    for name in ANSI_NAMES:
        key = name.lower()
        profile[f"ANSI{name}Color"] = archive_color(theme["normal"][key])
        profile[f"ANSIBright{name}Color"] = archive_color(theme["bright"][key])
    return profile


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def read_domain():
    """Return the preference domain as a dict; an empty dict when it has no keys yet."""
    result = subprocess.run(["defaults", "export", domain, "-"], capture_output=True)
    if result.returncode != 0 or not result.stdout.strip():
        return {}
    return plistlib.loads(result.stdout)


def font_installed():
    for base in (Path(home) / "Library/Fonts", Path("/Library/Fonts")):
        if base.is_dir() and any(base.glob(FONT_FILE_GLOB)):
            return True
    return False


# --- build ------------------------------------------------------------------------

if mode == "build":
    profile = build_profile()
    with open(profile_path, "wb") as handle:
        plistlib.dump(profile, handle, fmt=plistlib.FMT_XML, sort_keys=True)
    print(f"built: {profile_path}")
    sys.exit(0)

committed = plistlib.loads(profile_path.read_bytes())
if committed.get("name") != PROFILE_NAME or committed.get("type") != "Window Settings":
    print(f"INVALID: {profile_path} is not a '{PROFILE_NAME}' Window Settings profile.", file=sys.stderr)
    sys.exit(1)

state = read_domain()
profiles = state.get("Window Settings", {})
live_profile = profiles.get(PROFILE_NAME)
current_default = state.get("Default Window Settings")
current_startup = state.get("Startup Window Settings")


def drifted_keys():
    if live_profile is None:
        return None
    return sorted(k for k, v in committed.items() if live_profile.get(k) != v)


# --- report -----------------------------------------------------------------------

def report():
    drift = drifted_keys()
    rows = [
        (font_installed(), "font JetBrainsMono Nerd Font installed"),
        (live_profile is not None, f"profile '{PROFILE_NAME}' present in {domain}"),
        (drift == [] if drift is not None else False, "live profile matches the repository file"),
        (current_default == PROFILE_NAME, f"default profile is '{PROFILE_NAME}'"),
        (current_startup == PROFILE_NAME, f"startup profile is '{PROFILE_NAME}'"),
    ]
    print(f"terminal-sync  domain={domain}  profiles={len(profiles)}")
    for good, label in rows:
        print(f"  {OK if good else KO}  {label}")
    print(f"  default profile now: {current_default!r}   startup profile now: {current_startup!r}")
    if drift:
        print(f"  differing keys: {', '.join(drift)}")
    synced = bool(rows[1][0] and rows[2][0])
    print("SYNCED" if synced else "NOT SYNCED")
    if not synced and is_live:
        print("To apply (manual step): quit Terminal.app, then from another terminal run:")
        print("  task terminal:sync ARGS='--apply'")
    return 0


# --- apply ------------------------------------------------------------------------

def defaults_write(*args):
    result = run("defaults", "write", domain, *args)
    if result.returncode != 0:
        print(f"FAILED: defaults write {args[0]}: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)


def restore_command(key, previous):
    if previous is None:
        return f"defaults delete {domain} '{key}'"
    return f"defaults write {domain} '{key}' -string '{previous}'"


def apply():
    global state, profiles, live_profile, current_default, current_startup
    if is_live:
        running = run("pgrep", "-x", "Terminal")
        if running.returncode == 0:
            print("REFUSED: Terminal.app is running. Quit it (Cmd+Q) and run this from another terminal.", file=sys.stderr)
            sys.exit(1)
        stamp = time.strftime("%Y%m%d%H%M%S")
        backup = Path(home) / "Library/Preferences" / f"{domain}.plist.bak-{stamp}"
        exported = run("defaults", "export", domain, str(backup))
        if exported.returncode != 0 or not backup.exists():
            print(f"FAILED: could not back up {domain}: {exported.stderr.strip()}", file=sys.stderr)
            sys.exit(1)
        print(f"backup created: {backup}")
        print(f"  restore with (manual step): defaults import {domain} '{backup}'")

    xml = plistlib.dumps(committed, fmt=plistlib.FMT_XML).decode()
    defaults_write("Window Settings", "-dict-add", PROFILE_NAME, xml)
    print(f"profile written: '{PROFILE_NAME}' in {domain}")

    if set_default:
        print(f"previous default profile: {current_default!r}; previous startup profile: {current_startup!r}")
        print("  restore with (manual step):")
        print(f"    {restore_command('Default Window Settings', current_default)}")
        print(f"    {restore_command('Startup Window Settings', current_startup)}")
        defaults_write("Default Window Settings", "-string", PROFILE_NAME)
        defaults_write("Startup Window Settings", "-string", PROFILE_NAME)
        print(f"default and startup profile set to '{PROFILE_NAME}'")

    state = read_domain()
    profiles = state.get("Window Settings", {})
    live_profile = profiles.get(PROFILE_NAME)
    current_default = state.get("Default Window Settings")
    current_startup = state.get("Startup Window Settings")
    print("--- after apply ---")
    return report()


sys.exit(report() if mode == "report" else apply())
PYEOF
