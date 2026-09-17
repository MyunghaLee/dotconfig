vim.pack.add { 'https://github.com/folke/flash.nvim' }

require('flash').setup {
  jump = {
    autojump = true,
  },
  modes = {
    search = {
      enabled = false,
    },
    char = {
      jump_labels = true,
      autohide = true,
    },
  },
}

vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = '[S] Flash Jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = '[S] Flash Treesitter' })
vim.keymap.set('o', 'r', function() require('flash').remote() end, { desc = '[R] Remote Flash' })
vim.keymap.set({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = '[R] Treesitter Search' })
vim.keymap.set('c', '<c-s>', function() require('flash').toggle() end, { desc = 'Toggle Flash Search' })
