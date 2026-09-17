vim.pack.add { 'https://github.com/keaising/im-select.nvim' }

require('im_select').setup {
  -- default_im_select = 'xkb:us::eng', -- for ibus
  -- default_command = 'ibus_engine',
  -- put ibus_engine executable in ~.local/bin
  -- contents:
  -- #!/usr/bin/bash
  -- ibus engine $1
  default_im_select = 'keyboard-us', -- for fcitx5
  default_command = 'fcitx5-remote',
}
