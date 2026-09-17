vim.pack.add { 'https://github.com/akinsho/toggleterm.nvim' }

require('toggleterm').setup {
  direction = 'horizontal',
  shell = 'fish',
}

vim.keymap.set('n', '<leader>t', '<cmd>ToggleTerm<CR>', { noremap = true, silent = true, desc = "Toggle Terminal" })
