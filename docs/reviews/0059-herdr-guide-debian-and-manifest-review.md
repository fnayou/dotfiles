# Review: Herdr Guide Debian Support, herdr Manifest Entry, Debian git-cliff Verification

**Number:** 0059
**Status:** Complete
**Date:** 2026-07-31
**Plan reviewed:** None — corrective documentation fix (see Process Note)
**Branch:** `docs/herdr-guide-debian`

**Files reviewed:**

- `docs/guides/herdr-setup.md`
- `packages/Brewfile`
- `packages/arch/packages.txt`
- `packages/debian/packages.txt`
- `docs/reviews/0055-git-cliff-package-manifests-review.md`

---

## Summary

Two carried-over items, plus a third gap found while fixing them.

**1. `docs/guides/herdr-setup.md` predated Debian support.** ADR-0053 added Debian as a third
supported platform; the guide still said the package is "shared across macOS and Arch" and offered
prerequisites for two platforms only. Flagged in reviews 0054 and 0057, unaddressed until now.

**2. The Debian `git-cliff` claim is now verified.** Review 0055 recorded it as inherited from
`task changelog:install` rather than checked. Confirmed absent from every Debian suite — details
appended to review 0055 as a Post-Completion Note; its **Complete** status is unchanged.

**3. `herdr` was in no package manifest at all** — found while writing the platform notes. Exactly
the gap closed for `git-cliff` in review 0055: `docs/guides/packages-setup.md` lists herdr as an
optional tool, but neither `packages/Brewfile`, `packages/arch/packages.txt`, nor
`packages/debian/packages.txt` mentioned it. A fresh machine following the repository's own
manifests would not install it, then find the stowed `herdr` package inert.

---

## Availability — verified, not assumed

Every platform claim written into the guide and manifests was checked first:

| Platform | Source | Result |
|---|---|---|
| Debian | `packages.debian.org`, all suites | `git-cliff` — no results |
| Debian | `sources.debian.org` API | `git-cliff` — `404` / empty |
| Debian | `packages.debian.org`, all suites | `herdr` — no results |
| Debian | `packages.debian.org`, trixie | `stow` — found (4 packages) |
| Arch | `pacman -Si herdr` | `package 'herdr' was not found` |
| Arch | AUR RPC v5 | `herdr` 0.7.5-1, maintained, not flagged out-of-date |
| macOS / Linux | `brew info herdr` | 0.7.5, bottled |

The AUR result changed what was written: an earlier draft said herdr must come from Homebrew on
Arch. It is in the AUR at the same version as the Homebrew bottle, so the guide now documents both
and the Arch manifest lists the AUR line alongside the brew one.

---

## Changes

- **Guide §3** — rewritten for three platforms; states that herdr is in neither the official Arch
  repos nor the Debian archive, that Homebrew covers all three, that the AUR is an Arch alternative,
  and that GNU Stow comes from each platform's native package manager.
- **Guide §4** — new Debian prerequisites block (`brew install herdr`, `sudo apt install stow`), and
  an AUR alternative added under Arch. Both carry `⚠️  MANUAL STEP` markers.
- **Guide §2** — configuration table said `default_shell = zsh` is consistent "on both platforms";
  now "all three".
- **`packages/Brewfile`** — new "Terminal workspace manager" section with `brew "herdr"`, marked
  optional.
- **`packages/arch/packages.txt`** — herdr section (Homebrew) plus `yay -S herdr` under AUR packages.
- **`packages/debian/packages.txt`** — herdr under Out-of-band; git-cliff entry annotated with the
  verification date and source.
- **`docs/reviews/0055`** — Post-Completion Note recording the Debian verification; the open caveat
  is marked resolved and cross-referenced.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

- **`brew "herdr"` makes `brew bundle` install it for everyone**, including users who never stow the
  herdr package. Consistent with how the Brewfile already treats optional tools (`btop`, `eza`), and
  the comment marks it optional, but it is a behaviour change for anyone running `brew bundle`.

- **The AUR package is third-party.** `herdr` is maintained by `huyz`, not by the herdr project, and
  AUR builds run a `PKGBUILD` from source. Documented as an alternative rather than the recommended
  path; Homebrew stays first in both the guide and the manifests.

- **`task deps:*` tasks do not mention herdr.** They cover the zsh and Neovim dependency tiers, and
  herdr sits outside both. Left alone rather than widening their scope.

---

## Safety Verdict

**PASS** — Documentation and commented manifest lines only. No `stow`, `rm`, `mv`, or `ln -s`
against `$HOME`; no file outside the repository modified. Every new install command carries a
`⚠️  MANUAL STEP` marker, and the Arch and Debian manifests keep their commented-out,
read-and-run-manually format. Nothing executes automatically.

## Privacy Verdict

**PASS** — No credentials, tokens, hostnames, or personal data. The only external references added
are the public AUR package name and the herdr setup guide path.

## Documentation Verdict

**PASS** — Platform-specific commands are correctly labelled per the cross-platform rule: `brew` for
macOS/Linux Homebrew, `yay` only under Arch, `apt` only under Debian, `pacman` only under Arch. No
package manager appears in another platform's section. Every availability claim is backed by a query
run against the relevant archive, tabulated above.

---

## Process Note

Corrective documentation fix, consistent with reviews 0054, 0055 and 0056 — no PRD, Architecture, or
Plan. Written before the commit.

---

## Recommended Next Action

Approve and merge.
