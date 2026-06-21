# Review: eza Configuration PRD and Architecture

**Number:** 0043
**Status:** Complete
**Date:** 2026-06-21
**Documents reviewed:**
- `docs/prd/0014-eza-configuration.md`
- `docs/architecture/0014-eza-configuration-architecture.md`

---

## Summary

PRD/architecture review for the eza configuration Stow package (PRD 0014 / Architecture
0014). This is a genuine pre-implementation review — unlike bat (review 0041), the documents
were written before any code exists, following `AGENTS.md` §6 in order.

The package closely mirrors the bat precedent (vendored single theme, `stow/common/`,
`--no-folding`) with one simplification correctly identified: eza needs no cache-build step.
No blocking issues.

---

## Blocking Issues

None.

---

## Non-Blocking Issues

### N1 — `EZA_CONFIG_DIR` override path

Architecture Risks notes that a user with `EZA_CONFIG_DIR` set elsewhere would not read the
stowed `~/.config/eza/theme.yml`. Correct and adequately documented. The setup guide should
repeat this in troubleshooting. No change to PRD/architecture required.

### N2 — Vendored theme can drift from upstream

Decision 1 vendors the `theme.yml`. Same accepted tradeoff as bat — reproducibility over
staying current. Documented under Risks. No action; noted for maintenance.

### N3 — Accent choice is a preference, not a constraint

Decision 3 picks Blue to match Alacritty/Herdr. Sound and consistent. The PRD Open Questions
correctly flags it as user-swappable. If the user wants a different Macchiato accent, swap the
file before build — no structural impact.

---

## Safety Verdict

**PASS**

- No `stow --adopt` anywhere.
- No `rm`, `mv`, or `ln -s` targeting `$HOME` in automated context.
- All stow install/delete commands marked `⚠️ MANUAL STEP`.
- Dry-run (`--simulate`) precedes install in all documented sequences.
- No dependency installation (eza already installed).
- No host-state mutation analogue to bat's cache build — eza activation is pure stow.

---

## Privacy Verdict

**PASS**

- Theme file carries only color values and styling keys.
- No API keys, tokens, credentials, passwords, SSH keys, private hostnames, or work-specific
  values described anywhere.

---

## Cross-Platform Verdict

**PASS**

- `stow/common/` placement justified: eza, config path (`~/.config/eza/` via XDG), and theme
  format are identical on macOS and Arch.
- No OS-specific values.

---

## Documentation Verdict

**PASS**

- Decisions include tradeoff analysis (vendoring, single vs. switchable theme, accent,
  `--no-folding`, common placement).
- The eza-vs-bat difference (no cache build) is correctly identified as the simplifying factor.
- PRD ↔ architecture cross-references accurate.

---

## Recommended Next Action

PRD 0014 and Architecture 0014 are **approved**. Proceed to Plan 0018, then build, then the
implementation review (0044). The plan should reference Blue accent
(`catppuccin-macchiato-blue.yml`) and the setup guide should include the `EZA_CONFIG_DIR`
troubleshooting note (N1).
