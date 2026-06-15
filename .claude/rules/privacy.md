# Privacy Rules

These rules apply to all agents and all sessions.

## Default stance

Treat this repository as **private by default**. Even if it becomes public later, assume sensitive data must never be committed.

## Forbidden content

Never commit:

- API keys, tokens, or access credentials of any kind.
- Passwords or passphrases.
- SSH private key content (e.g., `-----BEGIN OPENSSH PRIVATE KEY-----`).
- Private hostnames, internal IP addresses, or internal service URLs.
- Work-specific secrets, configuration values, or environment variables.
- Sensitive personal information not suitable for version control.

## Required approach

- Use **placeholder values** in all examples:
  - `YOUR_API_KEY`
  - `your-token-here`
  - `your-email@example.com`
  - `hostname.example.com`
- Prefer `.example`, `.template`, or `.sample` files — the user renames and fills them locally.
- **Audit files before staging**: run `git diff --staged` and inspect for real values.
- If a file might contain secrets, explicitly note it and recommend adding it to `.gitignore`.

## Pre-commit checklist reminder

Before any commit, verify:

- [ ] No API keys or tokens in staged files.
- [ ] No passwords or private key content.
- [ ] No private hostnames or internal URLs.
- [ ] No work-specific secrets.
- [ ] All examples use placeholder values.
