return {
  {
    'Yu-Leo/gosigns.nvim',
    ft = 'go',
    cmd = { 'GosignsEnable', 'GosignsDisable', 'GosignsToggle' },
    opts = {},
  },
  vim.keymap.set('n', '<leader>gse', '<cmd> GosignsEnable <CR>', { desc = 'Enable gosigns' }),
  vim.keymap.set('n', '<leader>gsd', '<cmd> GosignsEnable <CR>', { desc = 'Disable gosigns' }),
  vim.keymap.set('n', '<leader>gst', '<cmd> GosignsEnable <CR>', { desc = 'Toggle gosigns' }),
}
