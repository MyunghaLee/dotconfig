-- 1. csvview.nvim 패키지 추가
vim.pack.add { 'https://github.com/hat0uma/csvview.nvim' }

-- 2. csvview 올바른 설정
require("csvview").setup({
  parser = {
    async_chunksize = 50,
  },
  keymaps = {
    -- Text objects (Visual/Operator-pending 모드용)
    textobject_field_inner = { "if", mode = { "o", "x" } },
    textobject_field_outer = { "af", mode = { "o", "x" } },
    
    -- Excel 스타일 내비게이션 (Normal/Insert 모드용)
    jump_next_field = { "<Tab>", mode = { "n", "v" } },
    jump_prev_field = { "<S-Tab>", mode = { "n", "v" } },
  },
  view = {
    max_column_width = 80,
    min_column_width = 5,
    display_mode = "border",
  },
})

-- 3. CSV/TSV 파일 열릴 때 자동 실행
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "csv", "tsv" },
  callback = function()
    vim.cmd("CsvViewEnable")
  end,
})
