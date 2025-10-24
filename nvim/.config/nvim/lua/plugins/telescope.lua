return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-u>"] = false,
                            ["<C-d>"] = false,
                        },
                    },
                },
            })

            -- Keybindings for Telescope
            local keymap = vim.keymap.set
            local builtin = require("telescope.builtin")
            local themes = require("telescope.themes")

            -- Dropdown theme for Find Files
            keymap("n", "<C-p>", function()
                builtin.git_files(themes.get_dropdown({}))
            end, { desc = "Find Files" })

            keymap("n", "<leader>ff", function()
                builtin.find_files(themes.get_dropdown({}))
            end, { desc = "Find Files" })

            -- Ivy theme for Live Grep
            keymap("n", "<leader>fg", function()
                builtin.live_grep(themes.get_ivy({}))
            end, { desc = "Live Grep" })

            keymap("n", "<leader>en", function()
                builtin.find_files {
                    cwd = vim.fn.stdpath("config")
                }
            end, { desc = "Find in main config" })

            keymap("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
            keymap("n", "<leader>fh", builtin.help_tags, { desc = "Find Help" })
        end,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {
                        }
                    }
                }
            })

            require("telescope").load_extension("ui-select")
        end
    }
}
