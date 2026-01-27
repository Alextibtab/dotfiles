return {
  {
    'zaldih/themery.nvim',
    lazy = false,
    dependencies = {
      { 'catppuccin/nvim', name = 'catppuccin' },
      'Shatur/neovim-ayu',
      'webhooked/kanso.nvim',
      'rebelot/kanagawa.nvim',
      'folke/tokyonight.nvim',
      'tiagovla/tokyodark.nvim',
      'haishanh/night-owl.vim',
      'dasupradyumna/midnight.nvim',
      'yorumicolors/yorumi.nvim',
      'sainnhe/everforest',
    },
    config = function()
      require('themery').setup {
        themes = {
          {
            name = 'Dynamic Theme',
            colorscheme = 'dynamic',
          },
          {
            name = 'Ayu Mirage',
            colorscheme = 'ayu-mirage',
            before = [[
              require("lualine").setup({
                options = {
						      theme = "ayu",
					      },
				      })
            ]],
          },
          {
            name = 'Ayu Dark',
            colorscheme = 'ayu-dark',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "ayu",
					      },
				      })
            ]],
          },
          {
            name = 'Catppuccin Frappe',
            colorscheme = 'catppuccin-frappe',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "catppuccin",
					      },
				      })
            ]],
          },
          {
            name = 'Catppuccin Macchiato',
            colorscheme = 'catppuccin-macchiato',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "catppuccin",
					      },
				      })
            ]],
          },
          {
            name = 'Catppuccin Mocha',
            colorscheme = 'catppuccin-mocha',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "catppuccin",
					      },
				      })
            ]],
          },
          {
            name = 'Kanagawa Wave',
            colorscheme = 'kanagawa-wave',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "kanagawa",
					      },
				      })
            ]],
          },
          {
            name = 'Kanagawa Dragon',
            colorscheme = 'kanagawa-dragon',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "kanagawa",
					      },
				      })
            ]],
          },
          {
            name = 'Kanso Mist',
            colorscheme = 'kanso-mist',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "kanso",
					      },
				      })
            ]],
          },
          {
            name = 'Kanso Ink',
            colorscheme = 'kanso-ink',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "kanso",
					      },
				      })
            ]],
          },
          {
            name = 'Kanso Zen',
            colorscheme = 'kanso-zen',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "kanso",
					      },
				      })
            ]],
          },
          {
            name = 'Midnight',
            colorscheme = 'midnight',
            before = [[
              require("lualine").setup({
                options = {
                  theme = "auto",
                },
              })
            ]],
          },
          {
            name = 'Night Owl',
            colorscheme = 'night-owl',
            before = [[
              require("lualine").setup({
                options = {
                  theme = "auto",
                },
              })
            ]],
          },
          {
            name = 'Tokyodark',
            colorscheme = 'tokyodark',
            before = [[
              require("lualine").setup({
                options = {
                  theme = "tokyodark",
                },
              })
            ]],
          },
          {
            name = 'Tokyonight Storm',
            colorscheme = 'tokyonight-storm',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "tokyonight",
					      },
				      })
            ]],
          },
          {
            name = 'Tokyonight Moon',
            colorscheme = 'tokyonight-moon',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "tokyonight",
					      },
				      })
            ]],
          },
          {
            name = 'Tokyonight Night',
            colorscheme = 'tokyonight-night',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "tokyonight",
					      },
				      })
            ]],
          },
          {
            name = 'Yorumi',
            colorscheme = 'yorumi',
            before = [[
              require("lualine").setup({
					      options = {
						      theme = "auto",
					      },
				      })
            ]],
          },
          {
            name = 'Everforest',
            colorscheme = 'everforest',
            before = [[
              require("lualine").setup({
                options = {
                  theme = "everforest",
                },
              })
            ]],
          },
        },
        livePreview = true,
      }
    end,
    keys = {
      { '<leader>ct', '<cmd>Themery<cr>', desc = 'themery: change theme' },
    },
  },
}
