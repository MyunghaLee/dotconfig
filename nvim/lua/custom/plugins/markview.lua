vim.pack.add({
    "https://github.com/OXY2DEV/markview.nvim",
})

require("markview").setup({
    preview = {
        enable = true,           -- 프리뷰 모드 활성화
        icon = "󰽉 ",
        split = "tab",    -- 'horizontal' | 'vertical' | 'tab'
    },
    markdown = {
        enable = true,           -- 인라인 렌더링
        conceal = true,
    },
    html = {
        enable = false,          -- .html 파일은 비활성 (필요시 켜기)
    },
})

-- 4. 키맵
vim.keymap.set("n", "<leader>m", ":Markview toggle<CR>", { silent = true, desc = "Markview Toggle" })
