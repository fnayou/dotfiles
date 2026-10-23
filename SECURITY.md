# Security Policy

## Supported versions

Only the `main` branch is supported.

## Reporting a vulnerability

Do not open a public issue for a security problem.

Report it privately with GitHub's
[private vulnerability reporting](https://github.com/fnayou/dotfiles/security/advisories/new).

Include what you found, where, and how to reproduce it. Expect an acknowledgement within a few
days. This is a personal project, so response times are best effort.

## Scope

Examples of in-scope reports:

- A committed secret, token or private key.
- A script that modifies files outside the repository or `$HOME` without a dry-run step.
- A script that runs Stow, `rm` or `mv` against user data unexpectedly.

If you find a leaked credential, report it privately and rotate it at the source.
