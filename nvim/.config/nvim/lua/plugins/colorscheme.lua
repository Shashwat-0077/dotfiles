-- return {
--     "catppuccin/nvim",
--     name = "catppuccin",
--     priority = 1000,
--     config = function()
--         require("catppuccin").setup({
--             flavour = "mocha",
--             integrations = {
--                 treesitter = true,
--                 telescope = true,
--                 nvimtree = true,
--                 cmp = true,
--                 gitsigns = true,
--             },
--         })
--         vim.cmd.colorscheme("catppuccin")
--     end,
-- }


-- return {
--     "rebelot/kanagawa.nvim",
--     config = function()
--         require('kanagawa').setup({
--             compile = false,             -- enable compiling the colorscheme
--             undercurl = true,            -- enable undercurls
--             commentStyle = { italic = true },
--             functionStyle = {},
--             keywordStyle = { italic = true},
--             typeStyle = {},
--             transparent = false,         -- do not set background color
--             dimInactive = false,         -- dim inactive window `:h hl-NormalNC`
--             terminalColors = true,       -- define vim.g.terminal_color_{0,17}
--             colors = {                   -- add/modify theme and palette colors
--                 palette = {},
--                 theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
--             },
--             overrides = function(colors) -- add/modify highlights
--                 return {}
--             end,
--             theme = "wave",              -- Load "wave" theme when 'background' option is not set
--             background = {               -- map the value of 'background' option to a theme
--                 dark = "wave",           -- try "dragon" !
--                 light = "wave"
--             },
--         })

--         vim.cmd("colorscheme kanagawa-wave")
--     end,
-- }

return {
    'Yazeed1s/oh-lucy.nvim',
    config = function()
        vim.cmd('colorscheme oh-lucy')
    end,
}
