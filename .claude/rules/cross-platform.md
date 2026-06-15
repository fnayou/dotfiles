# Cross-Platform Rules

These rules apply to all agents and all sessions.

## Supported platforms

- **macOS** (primary environment, frequently used)
- **EndeavourOS / Arch Linux** (also used)

## Separation principle

macOS and Arch must be **considered separately** for every decision that could differ between them.

Do not assume a single approach works on both without explicit analysis.

## Package manager rules

- Do not assume **Homebrew** exists on Arch.
- Do not assume **pacman** or **yay** exists on macOS.
- Do not mix macOS package manager commands into Arch documentation, or vice versa.
- When suggesting package installation, specify the target platform:

  ```
  # macOS
  brew install <package>

  # Arch / EndeavourOS
  sudo pacman -S <package>
  ```

## Configuration separation

- **Common packages**: configurations that work on both platforms without modification.
- **macOS-specific packages**: configurations only applicable to macOS.
- **Arch-specific packages**: configurations only applicable to EndeavourOS / Arch.
- Do not mix OS-specific settings into common/shared config files.

## Script safety

- Future scripts must **detect the OS** before suggesting package manager commands.
- Example detection pattern:

  ```bash
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
  elif [[ -f /etc/arch-release ]]; then
    # Arch / EndeavourOS
  else
    echo "Unsupported OS"
    exit 1
  fi
  ```

## Path safety

- Avoid hardcoded machine-specific paths (e.g., `/Users/yourusername/` or `/home/yourusername/`).
- Use `$HOME` as a portable reference to the user's home directory.
- Do not assume the username is the same on both platforms.

## Documentation

When documenting any command or config, always state which platform it applies to if it is not portable.

Convention for inline platform labels:
- In code blocks: use `# macOS` or `# Arch` comments on the first line.
- In prose: use `[macOS]` or `[Arch]` labels before the relevant item.
