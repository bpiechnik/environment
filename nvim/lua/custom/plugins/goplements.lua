return {
  {
    'maxandron/goplements.nvim',
    ft = 'go',
    opts = {},
  },
  vim.keymap.set('n', '<leader>gpe', '<cmd> GoplementsEnable <CR>', { desc = 'Enable goplements' }),
  vim.keymap.set('n', '<leader>gpd', '<cmd> GoplementsDisable <CR>', { desc = 'Disable goplements' }),
  vim.keymap.set('n', '<leader>gpt', '<cmd> GoplementsToggle <CR>', { desc = 'Toggle goplements' }),
}
