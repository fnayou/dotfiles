# Changelog

All notable changes to this dotfiles repository, generated from Conventional
Commits via [git-cliff](https://git-cliff.org). Do not edit by hand.

Versioning is CalVer (`vYYYY.MM`) — see the git-cliff config for rationale.

## [2026.10] - 2026-10-20

### Features

- **doctor**: Add a read-only machine health check
- **codex**: Add managed config package
- **codex**: Align palette and docs
- **packages**: Add rtk to macOS, Arch and Debian package lists
- **agents**: Add rtk/caveman/pocock maintenance scripts and tasks
- **codex**: Sync config template instead of stowing it
- **zsh**: Add lms and docker desktop completion support
- **ghostty**: Add common and macOS Ghostty stow packages
- **zsh**: Show images with chafa from cat and suffix aliases
- **packages**: Add chafa to the package manifests
- **deps**: Report chafa as an optional shell tool
- **doctor**: Report chafa as optional tooling

### Bug Fixes

- **scripts**: Teach detect-os.sh about Debian
- **decisions**: Reconcile ADR-0013/0014 and check the record in CI
- **statusline**: Detect caveman seam by capability
- **zsh**: Guard chpwd listing to interactive terminals
- **doctor**: Check platform-area stow packages

### Refactor

- **claude**: Show actual output tokens in caveman statusline

### Documentation

- **claude**: Record two more git commit stalls in the ship-change skill
- **prd**: Add PRD 0023 for agent-facing install and update documents
- **architecture**: Approve PRD 0023 and design the agent install/update documents
- **architecture**: Resolve nine design questions for the agent install/update documents
- **decisions**: Approve architecture 0022 and lift §8 for provisioning runs
- **statusline**: Sync architecture, guide and site with the seam change
- **plans**: Mark plan 0024 complete
- **workflow**: Require explicit gate approval
- **agent-tooling**: Record rtk, caveman and Pocock skills setup
- **agent-tooling**: Record what installing on a live machine revealed
- **codex**: Align docs with template-not-stowed setup
- **plans**: Rebuild index from actual plan file statuses
- **prd**: Add PRD 0028 for Ghostty configuration
- **prd**: Approve PRD 0028 and resolve its open questions
- **architecture**: Add architecture 0026 for Ghostty configuration
- **prd**: Amend PRD 0028 with a custom macOS Ghostty icon
- **architecture**: Add the macOS Ghostty icon package to architecture 0026
- **architecture**: Approve architecture 0026 for Ghostty configuration
- **reviews**: Add PRD and architecture review for Ghostty configuration
- **prd**: Move macOS Ghostty options into an optional include
- **architecture**: Resolve review 0080 findings for Ghostty
- **reviews**: Re-review Ghostty PRD and architecture after review 0080 fixes
- **architecture**: Resolve review 0081 findings for Ghostty
- **reviews**: Confirm review 0081 fixes for Ghostty PRD and architecture
- **plans**: Add plan 0031 for Ghostty configuration
- **reviews**: Add plan review for Ghostty configuration
- **plans**: Resolve review 0083 findings for plan 0031
- **reviews**: Confirm review 0083 fixes for plan 0031
- **plans**: Approve plan 0031 and apply review 0084 suggestions
- Withdraw the custom Ghostty Dock icon
- **guides**: Add Ghostty setup guide
- Add Ghostty to stow usage and website pages
- Mark Ghostty packages as stowed
- **reviews**: Add Ghostty implementation review
- **plans**: Add Ghostty follow-ups plan
- **task**: Describe all dry-run areas
- Name Ghostty alongside Alacritty for terminal colors
- **reviews**: Add Ghostty follow-ups implementation review
- **website**: Cover platform packages in the folded-directory fix
- **plans**: Close plans 0001-0004 and 0030 with implementation reviews
- **prd**: Draft PRD 0030 for chafa image preview
- **prd**: Record chafa and herdr test results in PRD 0030
- **reviews**: Add PRD review for chafa image preview
- **prd**: Resolve review 0090 findings for PRD 0030
- **prd**: Record remote herdr test results in PRD 0030
- **prd**: Approve PRD 0030 for chafa image preview
- **plans**: Add plan 0033 for chafa image preview
- **plans**: Resolve plan review 0092 findings for plan 0033
- **plans**: Approve plan 0033 for chafa image preview
- Document chafa image preview
- **reviews**: Add implementation review 0093 and complete plan 0033
- **plans**: Add plan 0034 for chafa documentation follow-up
- **plans**: Add the chafa screenshot task to plan 0034
- **plans**: Approve plan 0034 for chafa documentation follow-up
- List chafa with the optional shell tools
- **website**: Add a chafa image preview screenshot
- **reviews**: Add implementation review 0095 for plan 0034
- **plans**: Mark plan 0034 complete

### Chores

- **nvim**: Update lazy-lock.json

## [2026.08.1] - 2026-08-04

### Features

- **herdr**: Set catppuccin base and fill all eight Macchiato colour slots
- **claude**: Scope caveman savings to the current session and repository
- **zsh**: Add cloudflare-speed-cli speed test helpers

### Bug Fixes

- **claude**: Make the statusline mtime check OS-portable
- **zsh**: Correct speed-log flags and delegate speed test history to the tool

### Documentation

- **claude**: Correct the ship-change skill's hang guidance
- **herdr**: Document Debian support, add herdr to the package manifests
- Give colliding document numbers unique identifiers
- **zsh**: Document that PATH setup belongs above the managed block
- **decisions**: Make the ADR index match the ADR files

### Testing

- **claude**: Add a sandboxed end-to-end check for the status line

## [2026.08] - 2026-07-30

### Bug Fixes

- **herdr**: Replace unknown ui.sidebar.initial_split_width with ui.sidebar_width

### Documentation

- Sync PRD, architecture and plan statuses with review outcomes
- **assets**: Resize social preview back under GitHub's 1MB limit
- **reviews**: Add review 0054 for the herdr and status-sync fixes

### Chores

- **packages**: Add git-cliff to the package manifests
- **changelog**: Regenerate CHANGELOG.md with the Unreleased section

## [2026.07] - 2026-07-22

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
- **changelog**: Generate CHANGELOG from commits via git-cliff
- **zsh**: Add SSH host completion from ~/.ssh/config

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


