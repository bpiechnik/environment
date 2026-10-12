vim.loader.enable()

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Options
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8
-- Suppress the interactive "ATTENTION: swap file exists" prompt: plugins like
-- fff.nvim open files via vim.cmd('edit ...') from Lua, which can't render
-- that dialog and crashes with E5108 when another nvim session has the file open.
vim.opt.shortmess:append("A")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "python", "typescript", "javascript", "json", "yaml", "lua", "markdown" },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- LSP keymaps (fires for every LSP client that attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local picker = require("snacks").picker
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end
    map("gd", function() picker.lsp_definitions() end, "Go to Definition")
    map("grr", function() picker.lsp_references() end, "References")
    map("gri", function() picker.lsp_implementations() end, "Implementations")
    map("<leader>s", function() picker.lsp_symbols() end, "Document Symbols")
    map("<leader>k", vim.lsp.buf.hover, "Hover Documentation")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>a", vim.lsp.buf.code_action, "Code Action")
    map("[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
    map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
    map("<leader>e", vim.diagnostic.open_float, "Show Diagnostic")
  end,
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlights" })
vim.api.nvim_create_user_command("Rla", function()
  local cur = vim.api.nvim_get_current_buf()
  vim.cmd("bufdo e!")
  vim.api.nvim_set_current_buf(cur)
end, { desc = "Reload all buffers from disk" })
vim.cmd("cabbrev rla Rla")
vim.keymap.set({ "n", "v" }, "gl", "$", { desc = "Go to end of line" })
vim.keymap.set({ "n", "v" }, "gs", "^", { desc = "Go to first char of line" })
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>wh", "<cmd>split<cr>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>wc", "<cmd>close<cr>", { desc = "Close split" })


-- Open file picker on startup when no file argument given
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      require("fff").find_files()
    end
  end,
})

vim.api.nvim_create_user_command("Fmt", function()
  require("conform").format({ async = true })
end, { desc = "Format current buffer" })

local function open_base_diff()
  local cwd = vim.fn.getcwd()
  local function get_git_output(args)
    local command = { "git", "-C", cwd }
    vim.list_extend(command, args)
    local result = vim.system(command, { text = true }):wait(2000)
    if result.code == 0 then
      return vim.trim(result.stdout or "")
    end
    return ""
  end

  if get_git_output({ "rev-parse", "--show-toplevel" }) == "" then
    vim.notify("Not in a Git repository", vim.log.levels.WARN)
    return
  end

  local function prompt_base(pr_base)
    local suggested = get_git_output({ "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
    if pr_base and pr_base ~= "" then
      local remote_ref = "origin/" .. pr_base
      suggested = get_git_output({ "rev-parse", "--verify", "--end-of-options", remote_ref .. "^{commit}" }) ~= "" and remote_ref or pr_base
    elseif suggested == "" then
      for _, branch in ipairs({ "main", "master" }) do
        if get_git_output({ "rev-parse", "--verify", "refs/heads/" .. branch }) ~= "" then
          suggested = branch
          break
        end
      end
    end

    -- Git stores ancestry, not the name of the branch a checkout was created from.
    vim.ui.input({ prompt = "Review base branch: ", default = suggested }, function(base)
      if not base or vim.trim(base) == "" then return end
      local commit = get_git_output({ "rev-parse", "--verify", "--end-of-options", vim.trim(base) .. "^{commit}" })
      if commit == "" then
        vim.notify("Base branch not found locally; fetch it or choose another branch", vim.log.levels.WARN)
        return
      end
      vim.cmd.DiffviewOpen(commit .. "...HEAD")
    end)
  end

  if vim.fn.executable("gh") == 1 then
    vim.system({ "gh", "pr", "view", "--json", "baseRefName", "--jq", ".baseRefName" }, {
      cwd = cwd,
      text = true,
      timeout = 3000,
    }, function(result)
      vim.schedule(function()
        prompt_base(result.code == 0 and vim.trim(result.stdout or "") or nil)
      end)
    end)
  else
    prompt_base()
  end
end

-- Plugins
require("lazy").setup({
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    keys = {
      { "<leader>fe", function() require("snacks").explorer() end, desc = "File Explorer" },
    },
    opts = {
      explorer = { enabled = true },
      picker = {
        enabled = true,
        sources = {
          lsp_symbols = { filter = { default = true } },
        },
      },
    },
  },

  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        golangci_lint_fmt = {
          command = "/opt/homebrew/bin/golangci-lint",
          args = { "fmt", "--stdin", "-c", vim.fn.expand("~/.config/.golangci-lint.yaml") },
          stdin = true,
        },
      },
      formatters_by_ft = {
        go         = { "golangci_lint_fmt" },
        lua        = { "stylua" },
        python     = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json       = { "prettier" },
        yaml       = { "prettier" },
        markdown   = { "prettier" },
        toml       = { "taplo" },
        sql        = { "pg_format" },
      },
    },
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      -- Completion
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("mason").setup()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      -- gopls: use native nvim 0.11 API, bypass mason entirely
      vim.lsp.config("gopls", {
        cmd = { "/opt/homebrew/bin/gopls" },
        -- Homebrew go (version-independent opt symlink); keeps gopls off the
        -- asdf shim and the monorepo's bazel `go` wrapper. The binary infers
        -- its own GOROOT, so no GOROOT override is needed.
        cmd_env = {
          PATH = "/opt/homebrew/opt/go/bin:" .. vim.env.PATH,
        },
        capabilities = capabilities,
        settings = {
          gopls = {
            gofumpt = true,
            semanticTokens = false,
            usePlaceholders = true,
            linksInHover = false,
            codelenses = {
              gc_details = false,
              generate = false,
              regenerate_cgo = false,
              run_govulncheck = false,
              tidy = false,
              upgrade_dependency = false,
              vendor = false,
              test = false,
            },
          },
        },
      })
      vim.lsp.enable("gopls")

      -- Other LSP servers via mason-lspconfig
      vim.lsp.config("ts_ls", {
        root_markers = { "tsconfig.json", "package.json" },
      })
      vim.lsp.config("pyright", {
        root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py" },
      })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pyright",
          "ts_ls",
          "intelephense",
        },
        automatic_enable = { exclude = { "gopls" } },
      })

      -- Completion setup
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        performance = {
          debounce = 150,              -- wait 150ms after typing before requesting completions
          throttle = 80,               -- minimum gap between completion requests
          fetching_timeout = 200,      -- give up on slow sources faster
          max_view_entries = 20,       -- don't render huge lists
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]   = cmp.mapping.select_next_item(),
          ["<C-p>"]   = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-d>"]   = cmp.mapping.scroll_docs(4),
          ["<C-u>"]   = cmp.mapping.scroll_docs(-4),
          ["<Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer", option = {
            get_bufnrs = function()
              local bufs = {}
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                  local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
                  if byte_size < 512 * 1024 then
                    bufs[#bufs + 1] = buf
                  end
                end
              end
              return bufs
            end,
          }},
          { name = "path" },
        }),
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      ensure_installed = { "lua", "go", "python", "typescript", "javascript", "json", "yaml", "markdown" },
      auto_install = false,
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)

      local move = require("nvim-treesitter-textobjects.move")
      local map = function(keys, func, desc)
        vim.keymap.set({ "n", "x", "o" }, keys, func, { desc = desc })
      end
      map("]f", function() move.goto_next_start("@function.outer") end, "Next function")
      map("[f", function() move.goto_previous_start("@function.outer") end, "Prev function")
      map("]c", function() move.goto_next_start("@class.outer") end, "Next class/struct")
      map("[c", function() move.goto_previous_start("@class.outer") end, "Prev class/struct")
      map("]a", function() move.goto_next_start("@parameter.inner") end, "Next parameter")
      map("[a", function() move.goto_previous_start("@parameter.inner") end, "Prev parameter")
    end,
  },

  -- Inline LSP diagnostics
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    config = function()
      vim.diagnostic.config({ virtual_text = false }) -- disable default virtual text
      require("tiny-inline-diagnostic").setup()
    end,
  },

  -- Keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 0,
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>c", group = "comment" },
        { "<leader>m", group = "markdown" },
        { "<leader>f", group = "find" },
        { "<leader>w", group = "window" },
        { "<leader>g", group = "git" },
        { "g",         group = "goto" },
        { "]",         group = "next" },
        { "[",         group = "prev" },
      })
    end,
  },

  -- Commenting
  {
    "numToStr/Comment.nvim",
    keys = {
      { "<leader>c", function() require("Comment.api").toggle.linewise.current() end, desc = "Toggle comment" },
      { "<leader>c", "<Plug>(comment_toggle_linewise_visual)", mode = "v", desc = "Toggle comment" },
    },
    opts = {},
  },

  -- Jump anywhere on screen with 2 chars
  -- Markdown preview in browser
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = "cd app && npm install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  },

  {
    "folke/flash.nvim",
    keys = {
      { "s", function() require("flash").jump() end,       mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
    },
  },

  -- Add/change/delete surrounding chars
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- Status bar
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { theme = "auto" },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then return "no lsp" end
              return table.concat(vim.tbl_map(function(c) return c.name end, clients), ", ")
            end,
            icon = "",
          },
        },
        lualine_y = { "filetype" },
        lualine_z = { "location" },
      },
    },
  },

  -- LSP loading progress
  {
    "j-hui/fidget.nvim",
    opts = {},
  },

  {
    "sindrets/diffview.nvim",
    commit = "4516612fe98ff56ae0415a259ff6361a89419b0a",
    cmd = {
      "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory",
      "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh",
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review Changes" },
      { "<leader>gD", open_base_diff, desc = "Review Against Base Branch" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Review" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
      { "<leader>gf", "<cmd>DiffviewFocusFiles<cr>", desc = "Focus Review Files" },
    },
    opts = {
      default_args = {
        DiffviewOpen = { "--imply-local" },
      },
      keymaps = {
        view = {
          ["<leader>e"] = false,
          { "n", "]c", "]c", { desc = "Next Diff Hunk" } },
          { "n", "[c", "[c", { desc = "Previous Diff Hunk" } },
        },
      },
    },
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "Git: " .. desc })
        end
        map("]h", gs.next_hunk, "Next Hunk")
        map("[h", gs.prev_hunk, "Prev Hunk")
        map("<leader>gp", gs.preview_hunk, "Preview Hunk")
        map("<leader>gr", gs.reset_hunk, "Reset Hunk")
        map("<leader>gb", gs.blame_line, "Blame Line")
        map("<leader>gB", function() gs.blame() end, "Blame File")
      end,
    },
  },


  -- Buffer line fuzzy search
  {
    "ibhagwan/fzf-lua",
    keys = {
      { "<leader>/", function() require("fzf-lua").blines() end, desc = "Fuzzy search in buffer" },
    },
    opts = {},
  },

  -- Tmux/nvim pane navigation
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft", "TmuxNavigateDown",
      "TmuxNavigateUp", "TmuxNavigateRight",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },

  -- Fuzzy finder
  {
    "dmtrKovalenko/fff.nvim",
    lazy = false,
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    opts = {
      git = { status_text_color = true },
    },
    keys = {
      { "<leader>ff", function() require("fff").find_files() end, desc = "Find Files" },
      { "<leader>fg", function() require("fff").live_grep() end,  desc = "Live Grep" },
      { "<leader>fz", function() require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } }) end, desc = "Fuzzy Grep" },
      { "<leader>fc", function() require("fff").live_grep({ query = vim.fn.expand("<cword>") }) end, desc = "Search Word" },
      { "<leader>fF", function()
        local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if not root or root == "" then vim.notify("Not in a git repo", vim.log.levels.WARN) return end
        require("fff").find_files_in_dir(root)
      end, desc = "Find Files (repo)" },
      { "<leader>fG", function()
        local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if not root or root == "" then vim.notify("Not in a git repo", vim.log.levels.WARN) return end
        require("fff").live_grep({ cwd = root })
      end, desc = "Live Grep (repo)" },
    },
  },
}, {
  -- lazy.nvim options
  ui = { border = "rounded" },
})
