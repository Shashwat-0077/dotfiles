return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
        local highlight = {
            "frg1",
            "frg2",
            "frg3",
            "frg4",
            "frg5",
            "frg6",
        }

        local hooks = require "ibl.hooks"
        -- create the highlight groups in the highlight setup hook, so they are reset
        -- every time the colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            vim.api.nvim_set_hl(0, "frg1", { fg = "#5caeef" })
            vim.api.nvim_set_hl(0, "frg2", { fg = "#dfb976" })
            vim.api.nvim_set_hl(0, "frg3", { fg = "#c172d9" })
            vim.api.nvim_set_hl(0, "frg4", { fg = "#4fb1bc" })
            vim.api.nvim_set_hl(0, "frg5", { fg = "#97c26c" })
            vim.api.nvim_set_hl(0, "frg6", { fg = "#abb2c0" })
        end)

        require("ibl").setup { indent = { highlight = highlight } }
    end,
}
