vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require("snacks").setup {
  image = {
    resolve = function(path, src)
      local api = require "obsidian.api"
      if api.path_is_note(path) then
        return api.resolve_attachment_path(src)
      end
    end,
  },
  -- 단축키로 호출할 기능들 켜기
  -- picker = { enabled = true },
  explorer = { enabled = true },
  -- terminal = { enabled = true },
  -- lazygit = { enabled = true },
  -- notifier = { enabled = true },
  -- scratch = { enabled = true },
  -- words = { enabled = true },
}

vim.keymap.set("n", "<leader>e", function()
  require("snacks").explorer({
    hidden = true,   -- 숨김 파일 (.으로 시작하는 파일) 표시
    ignored = true,  -- .gitignore 등에서 무시된 파일 표시
  })
end, { desc = "Snacks Explorer" })
