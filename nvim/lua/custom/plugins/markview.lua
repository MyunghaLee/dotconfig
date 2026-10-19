vim.pack.add({
    "https://github.com/OXY2DEV/markview.nvim",
    "https://github.com/gunasekar/markview-smart-tables.nvim",
})

-- 넓은 표를 창 너비에 맞춰 자동 축소/줄바꿈
require("markview-smart-tables").setup({
    wrap_width = 0.9,    -- 표 최대 너비: 창 너비의 비율(0<n<=1) 또는 절대 열 수(n>1)
    wrap_minwidth = 5,   -- 줄바꿈 전에 열이 줄어들 수 있는 최소 너비
})

require("markview").setup({
    preview = {
        enable = true,           -- 프리뷰 모드 활성화
        icon = "󰽉 ",
        split = "tab",    -- 'horizontal' | 'vertical' | 'tab'
        -- 스마트 표는 소스 라인을 가상 텍스트로 덮으므로 커서가 보이지 않는다.
        -- 입력 모드에서만 원본 마크다운을 드러내 편집할 수 있게 한다.
        hybrid_modes = { "i" },
    },
    renderers = {
        markdown_table = function(buffer, item)
            require("markview-smart-tables").render(buffer, item)
        end,
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
