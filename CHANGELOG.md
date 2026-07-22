# Changelog

All notable changes to this dotfiles repository, generated from Conventional
Commits via [git-cliff](https://git-cliff.org). Do not edit by hand.

Versioning is CalVer (`vYYYY.MM`) — see the git-cliff config for rationale.

## [Unreleased]

### Features

- **stow**: Add dotfiles foundation
- **git**: Add safe Git configuration templates
- **zsh**: Add configuration foundation templates
- **omp**: Add Oh My Posh configuration template
- **deps**: Add shell dependency checks and macOS manifests
- **git**: Adopt managed XDG configuration
- **zsh**: Activate managed layer with no-folding strategy
- **zsh**: Activate managed layer with no-folding strategy
- **git**: Adopt managed XDG configuration
- **zsh**: Adopt real guarded configuration
- **zsh**: Encode personal preference policy via ADR-0044
- **zsh**: Add section headers, guards, packages consolidation, and omp alignment
- **alacritty**: Add managed alacritty package with Catppuccin theme
- **herdr**: Add managed agent multiplexer configuration
- **zsh**: Improve completions, fzf-tab previews, and plugin loading
- **bat**: Add managed bat config and Catppuccin Macchiato theme
- **eza**: Add managed eza Catppuccin Macchiato theme
- **zsh**: Add Taskfile completion and fix fzf-tab load order
- **alacritty**: Increase padding and add Alt+Shift+L pipe binding
- **omp**: Add OS segment before path in prompt
- **nvim**: Add managed Neovim config with Catppuccin Macchiato
- **claude**: Add claude stow package for Claude Code statusline
- **scripts**: Add OS maintenance helper (update/clean) via task
- **zsh**: Add Herdr session completion with fzf-tab preview
- Add Debian as a third supported platform
- **alacritty**: Add Shift+Enter newline binding, disable Buttonless
- **btop**: Add btop package with Catppuccin Macchiato (blue) theme
- **claude**: Add rtk savings statusline segment
- **btop**: Stow package and adopt btop 1.4.7 config

### Bug Fixes

- **zsh**: Guard compinit against Zinit and expand guarded eza aliases
- **zsh**: Replace GITHUB_TOKEN example with generic token name
- **zsh**: Move cat=bat alias inside bat availability guard
- **nvim**: Drop ansible-lint, document tree-sitter CLI dependency
- **zsh**: Init zoxide after Oh My Posh to keep its hook
- **zsh**: Init fzf before completion styles
- **claude**: Correct path tilde and add PR number segment to statusline
- **claude**: Harden caveman path + statusline forge/path bugs
- **btop**: Disable save_config_on_exit to protect stow symlink

### Documentation

- **reviews**: Add pre-first-commit review report
- Clarify canonical project workflow
- **plans**: Mark plans 0005 and 0006 as Complete
- Define document lifecycle workflow
- **zsh**: Add optional Oh My Posh integration reference
- **zsh**: Add activation migration path
- **zsh**: Record manual migration validation
- **zsh**: Add activation migration path
- **zsh**: Record manual migration validation
- **zsh**: Validate local no-folding migration
- **git**: Validate setup flow and require no-folding
- **decisions**: Add status-sync rule keeping status blocks in sync (ADR-0048)
- **readme**: Overhaul README and add per-package READMEs
- Clarify repo is public but treated as private by default
- Sync status blocks — all common packages stowed
- Reduce EndeavourOS setup friction
- **readme**: List claude and nvim packages
- **stow**: Document restow needed for new files in stowed packages
- **site**: Scaffold MkDocs Material homepage
- **site**: Write public homepage content and embed screenshots
- **readme**: Link to the published documentation site
- Polish repository presentation
- **assets**: Resize social preview under GitHub's 1MB limit
- **assets**: Refresh website screenshots
- **site**: Document task deps:debian in task reference
- **site**: Document Alacritty Shift+Enter binding
- **zsh**: Exclude local.zsh.example and zshrc.example from stow
- Sync statusline segment lists with PR/MR + rtk savings

### Chores

- Prepare repo for public release
- **btop**: Expand config to full option set, tune for weak-GPU server
- **claude**: Add ship-change skill for the release flow

### Other

- **main**: Resolve conflicts for --no-folding migration docs
- **main**: Resolve decisions README conflict — insert zsh ADRs 0024-0027 before git ADRs 0028-0032


