# Review: CLI Speed Test Local Validation (EndeavourOS)

**Number:** 0068
**Status:** Complete
**Date:** 2026-08-03
**Plan reviewed:** 0027 — Implement CLI Speed Test Tool (already Complete; this is post-implementation
validation on real hardware)
**Supersedes findings of:** 0067 — CLI Speed Test Tool Implementation Review
**Machine:** EndeavourOS / Arch Linux, `cloudflare-speed-cli` 1.0.8-1 from `extra`

## Summary

Review 0067 passed the implementation by inspection — the tool was **not installed** at that time and
the wrapper flags had been derived from upstream `src/cli.rs`. This review records the result of
installing 1.0.8 on the EndeavourOS machine and exercising the layer for real, before the PR is
accepted.

Two defects were found and fixed. Both were invisible to source reading.

## Findings

### Blocking (fixed in this branch)

1. **`speed-log` failed on every invocation.** The binary rejects `--silent` unless `--json` is also
   passed:

   ```
   --silent can only be used with --json. Use --silent --json together.   (exit 1)
   ```

   The original wrapper passed `--silent --export-csv` with no `--json`. Fixed: `speed-log` now runs
   `speed --json --silent "$@" >/dev/null` — silent for cron, errors still on stderr.

2. **`--export-csv` truncates; it is not an append log.** The original design wrote a "monthly CSV"
   and the docs described accumulating rows. Measured: two consecutive runs against the same path
   leave the file at **2 lines** (header + one row), holding the later run only.

   Fixed by delegating history to the tool instead of reimplementing it. `--auto-save` (default true)
   writes one JSON per run under `${XDG_DATA_HOME:-$HOME/.local/share}/cloudflare-speed-cli/runs/`,
   and the new `speed-history` function calls `--export-all-csv` over that set. Measured: two saved
   runs → `Exported 2 run(s)`, CSV of 3 lines.

### Non-blocking

- `--auto-save` defaults to **true**, so `speed` and `speed-json` also record runs. Documented, with
  `--auto-save false` given as the opt-out.
- Two background Bash invocations in this session stalled with their newlines collapsed into one line
  (the same rewrite behaviour `ship-change` documents for `git commit`). Running the same sequence
  from a script file worked every time. Noted here so the next session does not re-diagnose it.

## Verification performed

| Check | Result |
|---|---|
| `pacman -Si cloudflare-speed-cli` | `extra`, 1.0.8-1, GPL-3.0-only, deps `glibc` + `libgcc` — manifest claim correct |
| All wrapper flags present in `--help` | Yes — `--download-duration`, `--upload-duration`, `--concurrency`, `--json`, `--silent`, `--export-csv`, `--export-all-csv`, `-4`, `--traceroute`, `--compare-ip-versions` |
| `zsh -n` on the fixed layer | Clean |
| Guard with binary hidden from `PATH` | File sources, defines **nothing** (`speed`, `speed-json`, `speed-log`, `speed-history` all "not found") |
| Defaults resolve | `down=10s up=10s conc=6` |
| Post-source override (the `local.zsh` path) | Takes effect |
| `speed-json` real run | Exit 0, valid JSON |
| `speed-log` ×2 | Exit 0, no stdout, two runs recorded |
| `speed-history` (default path and argument form) | Exit 0, CSV of 3 lines in both cases |
| `$HOME` after all tests | No `cloudflare-speed-cli` directory under `.local/share`, `.local/state`, or `.config` |

All tests redirected `XDG_DATA_HOME` / `XDG_STATE_HOME` into the session scratchpad and sourced the
layer directly from the repository. **Nothing was stowed and `$HOME` was never written to.**

## Safety Verdict

PASS — No `stow` was run; the layer was exercised by sourcing it from the repository in a throwaway
shell. No `rm`/`mv`/`ln -s` against `$HOME`. `speed-history` is the only writer and creates only its
own output directory, on explicit call. Every risky command in the guide keeps its `⚠️  MANUAL STEP`
marker, and the rollback section now covers both storage locations.

## Privacy Verdict

PASS, with a finding now documented — saved runs and exported CSV/JSON contain the machine's **public
IP, ISP, region, local IP, and interface MAC**. Confirmed by inspecting a real run. These files live
under XDG data/state, outside the repository working tree, and cannot be committed accidentally. A
privacy note was added to the guide (§11), the website functions page, and ADR 0061.
`--hide-network-info` redacts the TUI only, not the saved files. No secrets in the diff.

## Documentation Verdict

PASS — The guide, both READMEs, the website pages, ADR 0061, PRD 0022, architecture 0021, and plan
0027 were all corrected to describe the real mechanism. The `cron` example now uses `--json --silent`
(the form that actually works). Two troubleshooting entries were added for the failure modes this
validation hit.

## Recommended Next Action

Commit the fix onto `feat/cloudflare-speed-cli` and let CI re-run before merging PR #63. The Arch
install path is validated on real hardware; the macOS and Debian paths remain documented but untested
on this machine.
