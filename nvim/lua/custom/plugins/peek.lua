return {
  {
    'toppair/peek.nvim',
    event = { 'VeryLazy' },
    app = { 'chromium', '--new-window' },
    build = 'deno task --quiet build:fast',
    config = function()
      require('peek').setup {
        auto_load = true, -- whether to automatically load preview when
        -- entering another markdown buffer
        close_on_bdelete = true, -- close preview window on buffer delete

        syntax = true, -- enable syntax highlighting, affects performance

        theme = 'dark', -- 'dark' or 'light'

        update_on_change = true,

        app = 'browser', -- 'webview', 'browser', string or a table of strings
        -- explained below

        filetype = { 'markdown' }, -- list of filetypes to recognize as markdown

        -- relevant if update_on_change is true
        throttle_at = 200000, -- start throttling when file exceeds this
        -- amount of bytes in size
        throttle_time = 'auto',
      }
      vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
      vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})
    end,
  },
  vim.keymap.set('n', '<leader>mp', '<cmd> PeekOpen <CR>', { desc = 'Open Markdown preview window' }),
  vim.keymap.set('n', '<leader>mc', '<cmd> PeekClose <CR>', { desc = 'Close Markdown preview window' }),
}
