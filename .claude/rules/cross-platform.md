# Cross-Platform Rules

These rules apply to all agents and all sessions.

## Supported platforms

- **macOS** (primary environment, frequently used)
- **EndeavourOS / Arch Linux** (also used)
- **Debian** (stable, trixie / 13+ — all servers run Debian)

## Separation principle

macOS, Arch, and Debian must be **considered separately** for every decision that could differ between them.

Do not assume a single approach works on all three without explicit analysis.

## Package manager rules

- Do not assume **Homebrew** exists on Arch or Debian.
- Do not assume **pacman** or **yay** exists on macOS or Debian.
- Do not assume **apt** exists on macOS or Arch.
- Do not mix one platform's package manager commands into another's documentation.
- When suggesting package installation, specify the target platform:

  ```
  # macOS
  brew install <package>

  # Arch / EndeavourOS
  sudo pacman -S <package>

  # Debian
  sudo apt install <package>
  ```

- Debian binary-name quirks: `bat` runs as `batcat`, `fd` ships in `fd-find`
  and runs as `fdfind`. `go-task` and `oh-my-posh` are not in the Debian
  archive — install them out-of-band (see `packages/debian/packages.txt`).

## Configuration separation

- **Common packages**: configurations that work on all platforms without modification.
- **macOS-specific packages**: configurations only applicable to macOS.
- **Arch-specific packages**: configurations only applicable to EndeavourOS / Arch.
- **Debian-specific packages**: configurations only applicable to Debian.
- Do not mix OS-specific settings into common/shared config files.

## Script safety

- Future scripts must **detect the OS** before suggesting package manager commands.
- Example detection pattern:

  ```bash
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
  elif [[ -f /etc/arch-release ]]; then
    # Arch / EndeavourOS
  elif [[ -f /etc/debian_version ]]; then
    # Debian
  else
    echo "Unsupported OS"
    exit 1
  fi
  ```

  Order matters: test `/etc/arch-release` before `/etc/debian_version`.

## Path safety

- Avoid hardcoded machine-specific paths (e.g., `/Users/yourusername/` or `/home/yourusername/`).
- Use `$HOME` as a portable reference to the user's home directory.
- Do not assume the username is the same on both platforms.

## Documentation

When documenting any command or config, always state which platform it applies to if it is not portable.

Convention for inline platform labels:
- In code blocks: use `# macOS`, `# Arch`, or `# Debian` comments on the first line.
- In prose: use `[macOS]`, `[Arch]`, or `[Debian]` labels before the relevant item.
