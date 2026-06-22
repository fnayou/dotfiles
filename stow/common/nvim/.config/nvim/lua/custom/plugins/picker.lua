-- snacks.nvim picker — the project's fuzzy finder (PRD 0016).
-- Replaces kickstart's bundled Telescope: files / grep / buffers / diagnostics
-- and the LSP navigation pickers. Pure Lua (needs ripgrep + fd on PATH).

return {
  -- Disable kickstart's bundled Telescope and its extensions.
  { 'nvim-telescope/telescope.nvim', enabled = false },
  { 'nvim-telescope/telescope-fzf-native.nvim', enabled = false },
  { 'nvim-telescope/telescope-ui-select.nvim', enabled = false },

  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      picker = { enabled = true },
    },
    config = function(_, opts)
      local snacks = require 'snacks'
      snacks.setup(opts)

      local picker = snacks.picker

      -- Use snacks for vim.ui.select (replaces telescope-ui-select).
      vim.ui.select = picker.select

      -- [[ Search keymaps ]] (mirror kickstart's Telescope maps)
      vim.keymap.set('n', '<leader>sh', picker.help, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', picker.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', picker.files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', picker.pickers, { desc = '[S]earch [S]elect picker' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', picker.grep_word, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', picker.grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', picker.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', picker.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', picker.recent, { desc = '[S]earch Recent Files' })
      vim.keymap.set('n', '<leader>sc', picker.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', picker.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>/', picker.lines, { desc = '[/] Fuzzily search in current buffer' })
      vim.keymap.set('n', '<leader>s/', function() picker.grep_buffers() end, { desc = '[S]earch [/] in Open Files' })
      vim.keymap.set('n', '<leader>sn', function() picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

      -- [[ LSP pickers on attach ]] (replaces telescope-lsp-attach)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('snacks-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', picker.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', picker.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', picker.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'grt', picker.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
          vim.keymap.set('n', 'gO', picker.lsp_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', picker.lsp_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
        end,
      })
    end,
  },
}
