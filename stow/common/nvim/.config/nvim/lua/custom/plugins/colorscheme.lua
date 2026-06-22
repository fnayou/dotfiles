-- Catppuccin Macchiato — matches the repo-wide terminal identity
-- (alacritty / zsh / oh-my-posh / bat / eza). Blue is the accent;
-- macchiato Blue = #8aadf4.
--
-- This file overrides kickstart's default Tokyonight colorscheme.

return {
  -- Disable kickstart's bundled Tokyonight so it does not fight Catppuccin.
  { 'folke/tokyonight.nvim', enabled = false },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000, -- load before any other UI plugin
    config = function()
      require('catppuccin').setup {
        flavour = 'macchiato',
        background = { dark = 'macchiato' },
        term_colors = true,
        integrations = {
          gitsigns = true,
          mason = true,
          mini = { enabled = true },
          neotree = true,
          treesitter = true,
          which_key = true,
          snacks = { enabled = true },
          native_lsp = { enabled = true },
        },
      }
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
  },
}
