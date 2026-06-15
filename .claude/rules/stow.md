# GNU Stow Rules

These rules apply to all agents and all sessions.

GNU Stow has not been set up yet. These rules define how it must be used when the time comes.

## Layout

- Use a **package-based layout** — one directory per logical config group.
- Do not use a flat `stow .` approach — it is unsafe and uncontrolled.
- Separate packages into categories:

  ```
  stow/
  ├── common/        # Works on both macOS and Arch
  ├── macos/         # macOS-specific only
  └── arch/          # Arch / EndeavourOS-specific only
  ```

## Stow commands

Always use explicit commands:

```bash
stow --dir=stow --target="$HOME" <package>
```

Never use:

```bash
stow .          # Unsafe — stows everything
stow --adopt    # Overwrites existing files without warning
```

## Dry-run before install — mandatory

Always provide a dry-run step before any install command:

```bash
# Step 1: Dry run — verify what would be linked
stow --dir=stow --target="$HOME" --simulate <package>

# Step 2: Install — only after reviewing dry-run output
⚠️  MANUAL STEP — run only after approving dry-run output
stow --dir=stow --target="$HOME" <package>
```

## `.example` files

- Use `.example` files during early adoption of any package.
- The user renames or copies them locally before stowing.
- Do not stow `.example` files directly unless the user explicitly intends this.

## Automatic stow

- Do not run Stow automatically in any script — this includes bootstrap scripts, install scripts, shell init scripts, and cloud-init or provisioning scripts.
- Scripts may print the Stow commands for the user to review and run manually, but must not execute them.

## Conflict handling

- If a conflict is detected during dry-run, stop and report to the user.
- Do not use `--adopt` to resolve conflicts — it overwrites the existing file.
- The user must manually resolve conflicts before stowing.
