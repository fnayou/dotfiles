#!/usr/bin/env bash
# Claude Code PreToolUse hook (matcher: Bash), registered in .claude/settings.json.
#
# When an agent session is about to run `git commit`, `git push` or `gh pr create`, show the operator a
# reminder to regenerate the art, but only when the change touches an art input and a committed SVG is
# stale (the logic lives in `scripts/art.sh remind`). It shows the message and lets the command go
# on: it never prints a permission decision, never exits 2, and changes nothing. On any error it stays
# silent and exits 0.
#
# Output (only when there is something to say):
#   systemMessage                      the operator's message
#   hookSpecificOutput.additionalContext   asks Claude to relay it, in case the first is not shown
exec python3 -c '
import json, os, re, subprocess, sys

try:
    event = json.load(sys.stdin)
    command = (event.get("tool_input") or {}).get("command", "")
    # git commit/push or gh pr create, alone or after cd / && / ; / |
    m = re.search(r"(?:^|[;&|]\s*)\s*(?:git(?:\s+-C\s+\S+)?\s+(commit|push)\b|gh\s+pr\s+create\b)", command)
    if not m:
        sys.exit(0)
    root = os.environ.get("CLAUDE_PROJECT_DIR") or subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
    kind = m.group(1)
    if kind == "commit":
        args = ["--working"] if re.search(r"\s(-[a-zA-Z]*a[a-zA-Z]*|--all)\b", command) else ["--staged"]
    elif kind == "push":
        up = subprocess.run(["git", "-C", root, "rev-parse", "--abbrev-ref", "@{u}"], capture_output=True, text=True)
        args = ["--range", "@{u}..HEAD" if up.returncode == 0 else "origin/main..HEAD"]
    else:
        args = ["--range", "origin/main..HEAD"]
    out = subprocess.run(["bash", os.path.join(root, "scripts", "art.sh"), "remind", *args],
                         capture_output=True, text=True, timeout=8).stdout.strip()
    if not out:
        sys.exit(0)
    print(json.dumps({
        "systemMessage": out,
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "Before you run this command, tell the operator this reminder, word for word: " + out,
        },
    }))
except Exception:
    pass
sys.exit(0)
'
