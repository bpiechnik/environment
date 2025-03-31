return {
  {
    'sindrets/diffview.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
  vim.keymap.set('n', '<leader>dvo', '<cmd>DiffviewOpen<CR>', { desc = 'Open Diffview' }),
  vim.keymap.set('n', '<leader>dvc', '<cmd>DiffviewClose<CR>', { desc = 'Open Diffview' }),
}
