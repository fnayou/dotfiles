# ssh.zsh — SSH host completion tuning. Guarded; no-op without `ssh` or a config.
#
# Native completion comes from the shipped `_ssh` (autoloaded by compinit). This file
# does NOT replace it — option/remote-path completion stay intact. It only swaps the
# HOST source: instead of the shipped mix of ~/.ssh/config plus every (often hashed,
# unusable) known_hosts line, host candidates come solely from the `Host` aliases you
# defined in ~/.ssh/config. Sourced after compinit. Everything here is read-only: it
# parses the config for names and never opens a connection.

command -v ssh >/dev/null 2>&1 || return
[[ -r "$HOME/.ssh/config" ]] || return

# Dynamic candidates: the `Host` aliases from ~/.ssh/config, re-read on every
# completion. Multi-host lines are split; wildcard/negation patterns (* ? !) are
# dropped since they are not connectable names.
_ssh_config_hosts() {
  awk 'tolower($1) == "host" {
    for (i = 2; i <= NF; i++)
      if ($i !~ /[*?!]/) print $i
  }' "$HOME/.ssh/config" 2>/dev/null
}

# Feed those names as the `hosts` tag for the ssh family. `zstyle -e` re-evaluates the
# body per completion, so edits to ~/.ssh/config show up without a new shell.
zstyle -e ':completion:*:(ssh|scp|sftp|rsync|ssh-copy-id):*:hosts' hosts \
  'reply=(${(f)"$(_ssh_config_hosts)"})'

# Show only the host aliases. `_ssh` also offers a `users` tag (every local account,
# ~140 daemon users on macOS) and `hosts-domain`/`my-accounts` noise; restricting the
# tag-order to `hosts` drops all of that so the menu is just your configured servers.
zstyle ':completion:*:(ssh|scp|sftp|rsync|ssh-copy-id):*' tag-order 'hosts'

# fzf-tab preview: the effective config the highlighted alias resolves to. `ssh -G`
# only prints resolved options and never connects; the grep trims it to the essentials.
zstyle ':fzf-tab:complete:ssh:*' fzf-preview \
  'ssh -G "$word" 2>/dev/null | grep -iE "^(hostname|user|port|identityfile|proxyjump|proxycommand) " || true'
