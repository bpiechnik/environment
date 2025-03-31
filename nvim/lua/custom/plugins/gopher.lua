return {

  {
    'olexsmir/gopher.nvim',
    ft = 'go',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    build = function()
      vim.cmd.GoInstallDeps()
    end,
    opts = {
      commands = {
        go = 'go',
        gomodifytags = 'gomodifytags',
        gotests = 'gotests',
        impl = 'impl',
        iferr = 'iferr',
        dlv = 'dlv',
      },
      gotests = {
        -- gotests doesn't have template named "default" so this plugin uses "default" to set the default template
        template = 'default',
        -- path to a directory containing custom test code templates
        template_dir = nil,
        -- switch table tests from using slice to map (with test name for the key)
        -- works only with gotests installed from develop branch
        named = false,
      },
      gotag = {
        transform = 'snakecase',
      },
    },
    config = function()
      vim.keymap.set('n', '<leader>gif', '<cmd> GoIfErr <CR>', { desc = 'Generate if err != nil' })
      vim.keymap.set('n', '<leader>gtj', '<cmd> GoTagAdd json <CR>', { desc = 'Generate json struct tags' })
      vim.keymap.set('n', '<leader>gtb', '<cmd> GoTagAdd bson <CR>', { desc = 'Generate bson struct tags' })
      vim.keymap.set('n', '<leader>gtv', '<cmd> GoTagAdd validate:required <CR>', { desc = 'Generate validate required struct tags' })
    end,
  },
}
