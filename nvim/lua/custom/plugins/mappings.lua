return {
  vim.keymap.set('n', '<leader>nu', '<cmd>set rnu!<CR>', { desc = 'Toggle relative number' }),
  vim.keymap.set('n', '<leader>nn', '<cmd>set nu!<CR>', { desc = 'Toggle line number' }),
  vim.keymap.set('n', '<leader>vs', '<cmd>:vs<CR>', { desc = 'Vertical pane split' }),
  vim.keymap.set('n', '<leader>sp', '<cmd>:sp<CR>', { desc = 'Horizontal pane split' }),
  vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv"),
  vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv"),
  vim.keymap.set('i', '<C-h>', '<Left>'),
  vim.keymap.set('i', '<C-l>', '<Right>'),
  vim.keymap.set('i', '<C-b>', '<ESC>^i'),
  vim.keymap.set('i', '<C-e>', '<END>'),
}
