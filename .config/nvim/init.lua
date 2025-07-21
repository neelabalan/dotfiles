-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin configuration
require("lazy").setup({
  -- Common utilities
  "nvim-lua/plenary.nvim",           
  {
    -- Auto pairs for brackets, quotes, etc.
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
        ts_config = {
          lua = {'string', 'source'},
          javascript = {'string', 'template_string'},
          java = false,
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel" },
        fast_wrap = {
          map = '<M-e>',
          chars = { '{', '[', '(', '"', "'" },
          pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], '%s+', ''),
          offset = 0,
          end_key = '$',
          keys = 'qwertyuiopzxcvbnmasdfghjkl',
          check_comma = true,
          highlight = 'PmenuSel',
          highlight_grey = 'LineNr'
        },
      })
    end
  },
  {
    -- Better indentation visualization
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = {
          char = "│",
          tab_char = "│",
        },
        scope = { enabled = false },
        exclude = {
          filetypes = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "Trouble",
            "trouble",
            "lazy",
            "mason",
            "notify",
            "toggleterm",
            "lazyterm",
          },
        },
      })
    end
  },           
  {
    -- Modern fuzzy finder
    "nvim-telescope/telescope.nvim",  
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.keymap.set('n', '<C-p>', '<cmd>Telescope find_files<cr>')
      vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
    end
  },
  {
    -- Modern file explorer
    "nvim-tree/nvim-tree.lua",        
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<cr>')
    end
  },
  {
    -- Modern statusline
    "nvim-lualine/lualine.nvim",      
    config = function()
      -- Custom theme based on your color scheme
      local custom_theme = {
        normal = {
          a = { fg = '#000000', bg = '#81a2be' },  -- Blue background
          b = { fg = '#ffffff', bg = '#444444' },
          c = { fg = '#a8a8a8', bg = '#242424' }
        },
        insert = {
          a = { fg = '#000000', bg = '#9ec400' },  -- Green background
          b = { fg = '#ffffff', bg = '#444444' }
        },
        visual = {
          a = { fg = '#000000', bg = '#f0c674' },  -- Yellow background
          b = { fg = '#ffffff', bg = '#444444' }
        },
        replace = {
          a = { fg = '#ffffff', bg = '#c70000' },  -- Red background
          b = { fg = '#ffffff', bg = '#444444' }
        },
        command = {
          a = { fg = '#000000', bg = '#b77ee0' },  -- Purple background
          b = { fg = '#ffffff', bg = '#444444' }
        },
        inactive = {
          a = { fg = '#70c0ba', bg = '#444444' },  -- Cyan for inactive
          b = { fg = '#666666', bg = '#353535' },
          c = { fg = '#969696', bg = '#242424' }
        }
      }
      
      require('lualine').setup({
        options = {
          theme = custom_theme,
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
          icons_enabled = false,
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        }
      })
    end
  },
  {
    -- VSCode theme
    "Mofiqul/vscode.nvim",            
    config = function()
      require('vscode').setup({
        transparent = false,
        italic_comments = false,
        disable_nvimtree_bg = true,
      })
      vim.cmd("colorscheme vscode")
    end
  }
})

-- Basic settings
vim.opt.number = true
vim.opt.numberwidth = 2
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.cindent = false
vim.opt.shiftround = false
vim.opt.preserveindent = false
vim.opt.copyindent = false
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.guicursor = "n-v-c-i:block"
vim.opt.showmode = false

-- Additional indentation configuration
vim.opt.smarttab = true
vim.opt.breakindent = true