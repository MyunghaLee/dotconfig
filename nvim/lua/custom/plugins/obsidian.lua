local vault_path = vim.fn.expand '~/.local/share/obsidian'

if vim.fn.isdirectory(vault_path) == 0 then
  return
end

vim.pack.add {
  {
    src = "https://github.com/obsidian-nvim/obsidian.nvim",
    version = vim.version.range "*", -- use latest release, remove to use latest commit
  },
}

vim.opt.conceallevel = 1

require("obsidian").setup {
  legacy_commands = false,

  workspaces = {
    {
      name = "obsidian",
      path = vault_path,
    },
  },

  ui = {
    enable = true,
  },
}

-- Obsidian keymaps
vim.keymap.set("n", "<leader>oo", "<cmd>Obsidian open<CR>", {
  desc = "Obsidian open",
})

vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<CR>", {
  desc = "Obsidian new note",
})

vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<CR>", {
  desc = "Obsidian search",
})

vim.keymap.set("n", "<leader>oq", "<cmd>Obsidian quick_switch<CR>", {
  desc = "Obsidian quick switch",
})

vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<CR>", {
  desc = "Obsidian backlinks",
})

vim.keymap.set("n", "<leader>ol", "<cmd>Obsidian links<CR>", {
  desc = "Obsidian links",
})

vim.keymap.set("n", "<leader>ot", "<cmd>Obsidian tags<CR>", {
  desc = "Obsidian tags",
})

vim.keymap.set("n", "<leader>od", "<cmd>Obsidian dailies<CR>", {
  desc = "Obsidian dailies",
})

vim.keymap.set("n", "<leader>oy", "<cmd>Obsidian yesterday<CR>", {
  desc = "Obsidian yesterday",
})

vim.keymap.set("n", "<leader>oT", "<cmd>Obsidian tomorrow<CR>", {
  desc = "Obsidian tomorrow",
})

vim.keymap.set("n", "<leader>op", "<cmd>Obsidian paste_img<CR>", {
  desc = "Obsidian paste image",
})

vim.keymap.set("n", "<leader>or", "<cmd>Obsidian rename<CR>", {
  desc = "Obsidian rename note",
})
