-- neo-tree — file explorer sidebar.
-- Toggle/reveal with `\` (backslash). Press `\` again inside the tree to close.

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- icons (mini.icons also mocks these)
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    },
    opts = {
      filesystem = {
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
        filtered_items = {
          visible = true, -- show dotfiles / gitignored, dimmed
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
}
