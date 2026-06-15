# Decision: SSH Configuration is Out of Scope

**Number:** 0005
**Date:** 2026-06-15
**Status:** Accepted

## Context

SSH configuration (`~/.ssh/config`, `~/.ssh/id_*`) is highly sensitive and varies significantly per host. It contains private hostnames, internal aliases, identity file paths, and sometimes port-forwarding rules specific to each machine or work environment.

Options considered:
- Manage SSH config in the repository as `.example` files.
- Manage SSH config fully manually, outside this repository.

## Decision

SSH configuration is **an explicit non-goal** of this dotfiles repository.

- No SSH package will be created.
- No `~/.ssh/config` template or example will be committed.
- No SSH private keys, public keys, hostnames, aliases, or jump host rules will be stored here.
- SSH configuration is managed manually on each host (macOS and Arch separately).

This decision is permanent unless explicitly revisited and reversed by the user.

## Consequences

- No risk of leaking SSH hostnames, internal infrastructure, or key material via this repository.
- SSH setup must be performed manually on each new machine — no automation provided here.
- Trade-off accepted: reduced convenience on new machine setup in exchange for permanent security boundary.
