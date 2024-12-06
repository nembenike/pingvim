-- Auto-install Lazy.nvim if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    print("Installing Lazy.nvim...")
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- Latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.mapleader = " " -- Set leader key to space
vim.g.maplocalleader = " "

-- Window split keymaps
vim.api.nvim_set_keymap('n', '<leader>sv', ':vsplit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sh', ':split<CR>', { noremap = true, silent = true })

-- Terminal functions with size control
vim.cmd([[
  function! OpenVerticalTerminal()
    vsplit
    vertical resize 80
    terminal
    startinsert
  endfunction

  function! OpenHorizontalTerminal()
    rightbelow split
    resize 15
    terminal
    startinsert
  endfunction
]])

-- Terminal keymaps using the sizing functions
vim.api.nvim_set_keymap('n', '<leader>tv', ':call OpenVerticalTerminal()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>th', ':call OpenHorizontalTerminal()<CR>', { noremap = true, silent = true })

-- Terminal-specific settings
vim.cmd([[
  " Auto-enter insert mode when entering terminal
  autocmd TermOpen * startinsert
  
  " Easy escape from terminal
  tnoremap <Esc> <C-\><C-n>
]])

-- Install required Debian dependencies if on Debian-based OS
if vim.fn.has("unix") == 1 then
    local os_name = io.popen("lsb_release -is"):read("*l")
    if os_name == "Debian" or os_name == "Ubuntu" then
        print("Installing dependencies for Debian-based systems...")
        os.execute([[
            sudo apt update && sudo apt install -y \
            git make gcc ripgrep fd-find curl python3 python3-pip nodejs npm
        ]])
    end
end

-- Lazy.nvim setup with plugins
require("lazy").setup({
    -- Colorschemes
    { "gruvbox-community/gruvbox" },
    { "catppuccin/nvim", name = "catppuccin" },
    { "dracula/vim", name = "dracula" },

    -- Fuzzy finder: Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup()
            vim.api.nvim_set_keymap("n", "<leader>f", ":Telescope find_files<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<leader>g", ":Telescope live_grep<CR>", { noremap = true, silent = true })
        end,
    },

    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup()
            vim.api.nvim_set_keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
        end,
    },

    -- LSP and autocompletion
    {
        "neovim/nvim-lspconfig",
        dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "pyright", "ts_ls" },
            })

            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup {}
            lspconfig.pyright.setup {}
            lspconfig.ts_ls.setup {}
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                mapping = {
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                },
            })
        end,
    },

    -- Syntax and treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

    -- Git integration
    { "lewis6991/gitsigns.nvim" },

    -- UI Enhancements
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup()
        end,
    },
    { "lukas-reineke/indent-blankline.nvim" },
    {
        "akinsho/bufferline.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("bufferline").setup()
        end,
    },

    -- Productivity tools
    { "numToStr/Comment.nvim", config = true },
    { "windwp/nvim-autopairs", config = true },
    { "kylechui/nvim-surround", config = true },
})

-- Define colorscheme switcher function
_G.switch_colorscheme = function()
    local colorschemes = { "gruvbox", "catppuccin", "dracula" }
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local sorters = require("telescope.config").values.generic_sorter
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
        prompt_title = "Select Colorscheme",
        finder = finders.new_table({
            results = colorschemes,
        }),
        sorter = sorters(),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
                local selection = action_state.get_selected_entry(prompt_bufnr)
                actions.close(prompt_bufnr)
                vim.cmd.colorscheme(selection.value) -- Apply selected colorscheme
            end)
            return true
        end,
    }):find()
end

-- Keybinding for colorscheme switcher
vim.api.nvim_set_keymap("n", "<leader>cs", ":lua switch_colorscheme()<CR>", { noremap = true, silent = true })

-- Default colorscheme
vim.cmd.colorscheme("gruvbox")
