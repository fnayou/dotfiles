# Decision: `omp.zsh` as Standalone Double-Guarded Prompt File

**Number:** 0035
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §5, ADR-0016

## Context

Oh My Posh (OMP) is a prompt engine that requires both its binary and a config file to be present before activation. Activating OMP unconditionally, or inside `shared.zsh`, would break shells where OMP is not installed or where the omp config package has not been stowed yet.

The current `omp.zsh.example` ships with the activation block commented out. PRD-0010 requires this block to be active (uncommented) so that users can simply copy the file without having to manually uncomment content.

## Decision

Oh My Posh activation is isolated in `omp.zsh` — a separate file sourced by `index.zsh` at step 3 (after `shared.zsh` and the platform layer, so `$PATH` is fully composed). The activation block uses two independent guards:

```zsh
if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" ]]; then
  eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml")"
fi
```

Guard 1 (`command -v oh-my-posh`): confirms the OMP binary is in `$PATH`. Uses `command -v` rather than a path check because the binary install location differs between macOS (Homebrew bin) and Arch (AUR bin or `~/.local/bin`).

Guard 2 (`[[ -f … omp.toml ]]`): confirms the config file exists. OMP errors on startup without a config file, so this guard prevents a broken prompt when the binary is present but the omp Stow package has not been applied.

If either guard fails: the `if` block is skipped, no error is raised, and the default zsh prompt remains.

`omp.zsh` is git-ignored (ADR-0025). Only `omp.zsh.example` is committed. The template ships with the activation block active (not commented out), so a user copying the template gets a working file immediately upon stowing.

## Consequences

- Users who do not want OMP simply do not create `omp.zsh` — the `[[ -r … ]]` guard in `index.zsh` handles the absent case.
- Users who install OMP after initial setup copy `omp.zsh.example` to `omp.zsh` and re-stow; no code change is needed.
- A machine with OMP binary but without the omp Stow package applied starts cleanly — guard 2 fails safely.
- Performance profiling of shell startup is simplified because the prompt engine is isolated in one file.
- The double-guard pattern is mandatory; removing either guard is a blocking review issue per Architecture-0010 §17.
