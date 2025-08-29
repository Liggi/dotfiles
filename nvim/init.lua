-- Neovim configuration from scratch
-- Modern setup with lazy.nvim, LSP, and essential productivity tools

-- Bootstrap lazy.nvim plugin manager
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

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Better defaults
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = "menuone,noselect"
vim.opt.termguicolors = true
-- Smooth, consistent scroll binding behavior
vim.o.scrollopt = "ver,jump"

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Essential keymaps
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Close floating windows with Esc
vim.keymap.set("n", "<Esc>", function()
  -- Close any floating windows first
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.api.nvim_win_close(win, false)
      return
    end
  end
  -- If no floating windows, clear search highlights
  vim.cmd("nohlsearch")
end, { desc = "Close floating windows or clear search" })

-- Window navigation disabled - tmux vim-tmux-navigator plugin handles Ctrl+hjkl

vim.keymap.set("n", "<leader>h", "<cmd>!tmux select-pane -L<cr><cr>", { desc = "Move to tmux pane left" })
vim.keymap.set("n", "<leader>j", "<cmd>!tmux select-pane -D<cr><cr>", { desc = "Move to tmux pane down" })
vim.keymap.set("n", "<leader>k", "<cmd>!tmux select-pane -U<cr><cr>", { desc = "Move to tmux pane up" })
vim.keymap.set("n", "<leader>l", "<cmd>!tmux select-pane -R<cr><cr>", { desc = "Move to tmux pane right" })

-- Diff context expansion (remote control)
vim.keymap.set("n", "<leader>x", function()
  local expanded_count = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_call(win, function() 
      return vim.wo.diff 
    end) then
      vim.api.nvim_win_call(win, function()
        vim.cmd("normal! zR")
      end)
      expanded_count = expanded_count + 1
    end
  end
  if expanded_count > 0 then
    print("Expanded " .. expanded_count .. " diff windows")
  else
    print("No diff windows found")
  end
end, { desc = "eXpand diff context (stay focused here)" })

vim.keymap.set("n", "]d", "]c", { desc = "Next diff change" })
vim.keymap.set("n", "[d", "[c", { desc = "Previous diff change" })

-- Move lines up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Plugin configuration
require("lazy").setup({
  -- Color scheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight-storm]])
      
      -- Clean floating window styling
      vim.schedule(function()
        -- Transparent border background to prevent extending beyond border
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", fg = "#7aa2f7" })
        -- Let Tokyo Night handle NormalFloat styling
      end)
    end,
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git" },
          path_display = { "smart" },
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
      })
      
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
      vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent files' })
    end,
  },

  -- Syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'vim', 'javascript', 'typescript', 'python', 'go', 'rust', 'json', 'yaml' },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<M-space>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
          },
        },
      })
    end,
  },

  -- LSP Configuration & Plugins
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'j-hui/fidget.nvim',
    },
    config = function()
      require('mason').setup()
      
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      -- Modern LspAttach autocmd (replaces on_attach)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end
          
          local bufnr = args.buf
          local nmap = function(keys, func, desc)
            if desc then
              desc = 'LSP: ' .. desc
            end
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
          end

          nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
          nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
          nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
          nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
          nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        end,
      })

      -- Standard LSP hover with borders (the Neovim way)  
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
        max_width = 80,
        max_height = 30,
        focusable = true,
      })
      
      -- DEBUG: Let's see what's happening
      print("LSP handler set with border: rounded")

      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'ts_ls', 'pyright', 'gopls', 'rust_analyzer', 'kotlin_language_server', 'dartls' },
        automatic_installation = true,
        handlers = {
          function(server_name)
            require('lspconfig')[server_name].setup({
              capabilities = capabilities,
            })
          end,
          lua_ls = function()
            require('lspconfig').lua_ls.setup({
              capabilities = capabilities,
              settings = {
                Lua = {
                  workspace = { checkThirdParty = false },
                  telemetry = { enable = false },
                },
              },
            })
          end,
          ts_ls = function()
            require('lspconfig').ts_ls.setup({
              capabilities = capabilities,
              root_dir = require('lspconfig').util.root_pattern('package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'package.json', 'tsconfig.json'),
              settings = {
                typescript = {
                  preferences = {
                    includePackageJsonAutoImports = "auto",
                  },
                },
              },
            })
          end,
        },
      })
      
      require('fidget').setup({})
    end,
  },

  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete({}),
          ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        },
      })
    end,
  },

  -- Git integration
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Git workflow commands
  {
    'tpope/vim-fugitive',
    config = function()
      vim.keymap.set('n', '<leader>gs', '<cmd>Git<cr>', { desc = 'Git status (staging)' })
      vim.keymap.set('n', '<leader>ga', '<cmd>Git add %<cr>', { desc = 'Git add current file' })
      vim.keymap.set('n', '<leader>gc', '<cmd>Git commit<cr>', { desc = 'Git commit' })
      vim.keymap.set('n', '<leader>gp', '<cmd>Git push<cr>', { desc = 'Git push' })
      vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<cr>', { desc = 'Git blame' })
    end,
  },

  -- Git diff viewer
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Function to apply settings to only the diff windows in a given tabpage
      local function apply_diffview_window_opts(tabpage)
        vim.defer_fn(function()
          local wins = {}
          -- Collect and configure only diff windows in this tab
          for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
            local ok, isdiff = pcall(function() return vim.wo[winid].diff end)
            if ok and isdiff then
              table.insert(wins, winid)
              -- Fold settings: show full files with no diff folds
              vim.wo[winid].foldenable = false
              vim.wo[winid].foldmethod = 'manual'
              vim.wo[winid].foldlevel = 99
              vim.wo[winid].foldcolumn = '0'
              -- Scroll + cursor binding for consistent sync from either pane
              vim.wo[winid].scrollbind = true
              vim.wo[winid].cursorbind = true
              -- Avoid scrolloff interfering with binding
              vim.wo[winid].scrolloff = 0
              -- Ensure huge context in diff to avoid diff-based folding
              -- diffopt is global in this Neovim; adjust it globally instead of per-window
              local cur_tbl = vim.opt.diffopt:get()
              -- remove existing context:* entries
              for _, item in ipairs(vim.list_slice(cur_tbl)) do
                if type(item) == 'string' and item:match('^context:%d+') then
                  pcall(function() vim.opt.diffopt:remove(item) end)
                end
              end
              vim.opt.diffopt:append('context:99999')
              -- Ensure filler lines keep windows aligned vertically
              local after_tbl = vim.opt.diffopt:get()
              local has_filler = false
              for _, v in ipairs(after_tbl) do
                if v == 'filler' then has_filler = true break end
              end
              if not has_filler then
                vim.opt.diffopt:append('filler')
              end
            end
          end
          if #wins > 0 then
            pcall(vim.cmd, 'syncbind')
          end
        end, 20)
      end

      require('diffview').setup({
        enhanced_diff_hl = true, -- Enable enhanced syntax highlighting in diffs
        view = {
          default = { layout = 'diff2_horizontal' },
          merge_tool = { layout = 'diff3_horizontal' },
        },
        hooks = {
          view_opened = function(view)
            apply_diffview_window_opts(view.tabpage)
          end,
          view_entered = function(view)
            apply_diffview_window_opts(view.tabpage)
          end,
          -- Some versions expose this hook; safe if present
          diff_buf_win_enter = function(_bufnr, _winid, ctx)
            if ctx and ctx.view and ctx.view.tabpage then
              apply_diffview_window_opts(ctx.view.tabpage)
            end
          end,
        },
      })

      -- While focused in the file panel, provide shortcuts to scroll both diff panes
      local function scroll_diff_in_view(cmd)
        local ok, lib = pcall(require, 'diffview.lib')
        if not ok then return end
        local view = lib.get_current_view()
        if not view then return end
        local tabpage = view.tabpage
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
          local ok2, isdiff = pcall(function() return vim.wo[winid].diff end)
          if ok2 and isdiff then
            pcall(vim.api.nvim_win_call, winid, function()
              vim.cmd('normal! ' .. cmd)
            end)
          end
        end
        pcall(vim.cmd, 'syncbind')
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'DiffviewFiles',
        callback = function(args)
          local buf = args.buf
          -- Scroll by one line
          vim.keymap.set('n', '<C-e>', function() scroll_diff_in_view('<C-e>') end, { buffer = buf, desc = 'Scroll diff panes down' })
          vim.keymap.set('n', '<C-y>', function() scroll_diff_in_view('<C-y>') end, { buffer = buf, desc = 'Scroll diff panes up' })
          -- Scroll by half page
          vim.keymap.set('n', '<C-d>', function() scroll_diff_in_view('<C-d>') end, { buffer = buf, desc = 'Scroll diff panes half-page down' })
          vim.keymap.set('n', '<C-u>', function() scroll_diff_in_view('<C-u>') end, { buffer = buf, desc = 'Scroll diff panes half-page up' })
          -- Optional: mouse wheel support within the file panel
          vim.keymap.set('n', '<ScrollWheelDown>', function() scroll_diff_in_view('<C-e>') end, { buffer = buf, silent = true })
          vim.keymap.set('n', '<ScrollWheelUp>', function() scroll_diff_in_view('<C-y>') end, { buffer = buf, silent = true })
        end,
      })

      -- Also re-apply on Diffview's User events to be extra robust
      local group = vim.api.nvim_create_augroup('DiffviewTweaksRobust', { clear = true })
      local function reapply_for_current_view()
        local ok, lib = pcall(require, 'diffview.lib')
        if not ok then return end
        local view = lib.get_current_view()
        if view then
          apply_diffview_window_opts(view.tabpage)
        end
      end
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = { 'DiffviewViewOpened', 'DiffviewViewEnter', 'DiffviewDiffBufWinEnter' },
        callback = reapply_for_current_view,
      })

      -- Simple mappings
      vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = 'Open git diff' })

      vim.keymap.set('n', '<leader>gq', '<cmd>DiffviewClose<cr>', { desc = 'Close git diff' })
      vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', { desc = 'File history' })

      -- Quick exit from diffview
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "DiffviewFiles", "DiffviewFileHistory" },
        callback = function()
          vim.keymap.set('n', 'q', '<cmd>DiffviewClose<cr>', { buffer = true, desc = 'Close diffview' })
          vim.keymap.set('n', '<Esc><Esc>', '<cmd>DiffviewClose<cr>', { buffer = true, desc = 'Quick exit diffview' })
        end,
      })
    end,
  },

  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'tokyonight',
        component_separators = '|',
        section_separators = '',
      },
    },
  },

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup({
        disable_netrw = true,
        hijack_netrw = true,
        
        view = {
          float = {
            enable = true,
            quit_on_focus_loss = false,
            open_win_config = {
              relative = 'editor',
              border = 'rounded',
              width = 100,
              height = 45,
              row = 2,
              col = 2,
            },
          },
        },
        
        live_filter = {
          prefix = '[FILTER]: ',
          always_show_folders = true,
        },
        
        renderer = {
          group_empty = false,
          full_name = true,
          highlight_opened_files = 'name',
          indent_markers = {
            enable = true,
            inline_arrows = true,
          },
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = false,
            },
          },
        },
        
        filters = {
          dotfiles = false,
          git_clean = false,
          no_buffer = false,
          custom = {
            'node_modules',
            '.git',
            '.DS_Store',
            'thumbs.db',
            '.next',
            'dist',
            'build',
            '.venv',
            '__pycache__',
            '.pytest_cache',
            'coverage',
            '.nyc_output',
          },
          exclude = {
            '.gitignore',
            '.env',
          },
        },
        
        actions = {
          open_file = {
            quit_on_open = false,
            window_picker = {
              enable = true,
            },
          },
          expand_all = {
            max_folder_discovery = 300,
            exclude = { '.git', 'node_modules', '.cache' },
          },
        },
        
        git = {
          enable = false,
        },
        
        diagnostics = {
          enable = false,
        },
      })
      
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<cr>', { desc = 'Toggle floating file tree' })
      vim.keymap.set('n', '<leader>E', ':NvimTreeFindFile<cr>', { desc = 'Find current file in tree' })
    end,
  },

  -- Which-key for keybind help
  {
    'folke/which-key.nvim',
    config = function()
      require('which-key').setup()
    end,
  },

  -- Auto pairs
  {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup({})
    end,
  },

  -- Comment toggling
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },

  -- Tmux navigation
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    config = function()
      vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Navigate right from Claude terminal', silent = true, remap = false })
    end,
  },

  {
    'coder/claudecode.nvim',
    dependencies = { 'folke/snacks.nvim' },
    config = function()
      require('claudecode').setup({
        terminal = {
          split_side = 'left',
          split_width_percentage = 0.4,
        },
        diff_opts = {
          keep_terminal_focus = true,
        },
      })
      
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          vim.keymap.set('n', 'i', 'i', { buffer = true, desc = 'Enter terminal insert mode' })
          vim.keymap.set('n', 'a', 'A', { buffer = true, desc = 'Enter terminal insert mode at end' })
          vim.keymap.set('n', '<Esc>', 'i', { buffer = true, desc = 'Quick return to terminal insert mode' })
        end,
      })
    end,
    keys = {
      { '<leader>cc', '<cmd>ClaudeCode<cr>', desc = 'Launch Claude Code' },
      { '<leader>ca', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept Claude diff' },
      { '<leader>cr', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Reject Claude diff' },
    },
  },

  -- Formatting (conform.nvim)
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    opts = {
      format_on_save = function(bufnr)
        -- Use LSP if no formatter configured; keep it fast
        return { timeout_ms = 2000, lsp_fallback = true }
      end,
      formatters_by_ft = {
        -- JS/TS and friends via prettierd (fallback to prettier)
        javascript = { { 'prettierd', 'prettier' } },
        javascriptreact = { { 'prettierd', 'prettier' } },
        typescript = { { 'prettierd', 'prettier' } },
        typescriptreact = { { 'prettierd', 'prettier' } },
        json = { { 'prettierd', 'prettier' } },
        jsonc = { { 'prettierd', 'prettier' } },
        yaml = { { 'prettierd', 'prettier' } },
        markdown = { { 'prettierd', 'prettier' } },

        -- Lua
        lua = { 'stylua' },

        -- Python
        python = { 'black' },

        -- Go
        go = { { 'goimports', 'gofmt' } },

        -- Shell
        sh = { 'shfmt' },

        -- Rust
        rust = { 'rustfmt' },
      },
    },
  },

  -- Linting (nvim-lint)
  {
    'mfussenegger/nvim-lint',
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        javascript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        python = { 'ruff' },
        lua = { 'luacheck' },
        go = { 'golangcilint' },
        sh = { 'shellcheck' },
        markdown = { 'markdownlint' },
        yaml = { 'yamllint' },
      }

      local grp = vim.api.nvim_create_augroup('NvimLint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = grp,
        callback = function()
          -- try all configured linters for the current filetype
          require('lint').try_lint()
        end,
      })
    end,
  },

  -- Ensure external tools exist (installed via mason)
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require('mason-tool-installer').setup({
        ensure_installed = {
          -- Formatters
          'prettierd', 'prettier', 'stylua', 'black', 'shfmt', 'goimports',
          -- Linters
          'eslint_d', 'ruff', 'luacheck', 'golangci-lint', 'shellcheck', 'markdownlint', 'yamllint',
        },
        auto_update = false,
        run_on_start = true,
      })
    end,
  },
})
