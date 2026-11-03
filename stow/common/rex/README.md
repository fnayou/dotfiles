# rex

[Rex](https://www.superlogical.com/rex/) terminal theme (beta). Holds one Ghostty-format theme file
that the user imports into Rex by hand.

## What it provides

- Catppuccin Macchiato palette with a blue `#8aadf4` accent (cursor, selection, blue ANSI slots).

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/rex/themes/catppuccin-macchiato-blue` | `~/.config/rex/themes/catppuccin-macchiato-blue` | Theme import source. Rex does not read this path on its own. |

## Activation is manual

Rex keeps imported themes in its app preferences and has no `init.lua` theme key, so stowing does not
change Rex. Import the file in Rex, then set the two accent settings by hand. Stowing is optional.

See [Rex Package Setup Guide](../../../docs/guides/rex-setup.md) for the import, dry-run, rollback and
accent steps.
