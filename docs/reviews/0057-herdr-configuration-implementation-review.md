# Review: Herdr Configuration Package — Implementation

**Number:** 0057
**Status:** Complete
**Date:** 2026-07-31
**Plan reviewed:** 0016 — Implement Herdr Configuration Package
**PRD:** 0012 · **Architecture:** 0012

**Files reviewed:**

- `stow/common/herdr/.config/herdr/config.toml`
- `stow/common/herdr/.stow-local-ignore`
- `stow/common/herdr/README.md`
- `docs/guides/herdr-setup.md`
- machine state: `~/.config/herdr/`

---

## Summary

Retrospective implementation review for **Plan 0016 — Implement Herdr Configuration Package**. The
package shipped without one, leaving the plan stuck at `Approved` while the package had been live
for weeks. Verified against the running machine, not just the repository.

Everything functional passes:

| Check | Result |
|---|---|
| `.stow-local-ignore` (six patterns) | present |
| `config.toml` present, non-empty | yes |
| `delivery = "herdr"` (not `"system"`, per Architecture Decision 1) | confirmed |
| All five Catppuccin Macchiato overrides (`#24273a`, `#8aadf4`, `#a6da95`, `#ed8796`, `#eed49f`) | present |
| D1 — TOML parses (`tomllib`) | pass |
| D3 — privacy audit | no matches |
| D4 — dependency/network audit | no matches |
| `~/.config/herdr/config.toml` symlinked into the repo | yes |
| `~/.config/herdr` is a real directory, not folded | confirmed |
| Live runtime validation: `herdr config check` | `config: ok` |

The runtime check goes beyond what Plan 0016 asked for. It was added after review 0054 found a key
in this same file that Herdr had been silently ignoring since the package was created — file-level
checks alone would not have caught it.

---

## Divergences from the Plan

Two settings differ from what Plan 0016 (dated 2026-06-20) specified. Both are accepted as
post-plan evolution rather than defects; the plan text is what is stale.

1. **`theme.name` is `"tokyo-night"`, the plan specified `"catppuccin"`.** `tokyo-night` is a valid
   built-in in Herdr 0.7.5, and the `[theme.custom]` Macchiato overrides still apply on top, so the
   palette intent of PRD 0012 is preserved. Treated as a deliberate user preference change.

2. **`[scrollback] history = 20000` is absent.** Re-adding it would be a regression, not a fix:
   Herdr 0.7.5 has no `[scrollback]` table — the binary exposes scrollback as
   `scrollback_limit_bytes` under its advanced config. Restoring the planned key would recreate
   exactly the class of silently-ignored-key bug that review 0054 fixed.

Settings added since the plan (`update.channel`, `ui.sidebar_width`, `ui.agent_panel_sort`,
`ui.toast.herdr.position`, `ui.sound.enabled`) are all documented in `docs/guides/herdr-setup.md`
and accepted by `herdr config check`.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

- **Plan 0016's config block is now a historical record, not a specification.** It is left unedited
  — plans describe what was decided at the time. This review is the authority on what the file
  actually contains.

- **`docs/guides/herdr-setup.md` §3 still says "shared across macOS and Arch."** Debian became
  supported in ADR-0053. Carried over from review 0054; still unaddressed.

---

## Safety Verdict

**PASS** — No `stow --adopt`, `rm`, `mv`, or `ln -s` against `$HOME` in the package or its docs. All
install/delete commands in the guide and README carry `⚠️  MANUAL STEP` markers. Verification for
this review was entirely read-only. `~/.config/herdr` is confirmed a real directory, so the folding
hazard the guide warns about has not occurred.

## Privacy Verdict

**PASS** — Audit D3 returns no matches. The file holds UI preferences and Catppuccin hex codes only;
no credentials, tokens, hostnames, or personal data.

## Documentation Verdict

**PASS** — README and setup guide are accurate and copy-pasteable. The guide's configuration table
matches the file as it stands today, including the corrections made in review 0054.

---

## Plan Status

Plan 0016 is marked **Complete** in this change, per DOCUMENT-LIFECYCLE (implementation review
passes with no blocking issues), with the two divergences recorded above.

---

## Recommended Next Action

Approve and merge. No follow-up work required for this package.
