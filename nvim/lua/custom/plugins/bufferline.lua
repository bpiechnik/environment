return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    keys = {
      {
        '<Tab>',
        '<Cmd>BufferLineCycleNext<CR>',
        desc = 'Next buffer',
      },
      {
        '<S-Tab>',
        '<Cmd>BufferLineCyclePrev<CR>',
        desc = 'Previous buffer',
      },
      { '<leader>bp', '<Cmd>BufferLinePick<CR>', desc = 'Pick buffer' },
      { '<leader>bc', '<Cmd>bdelete<CR>', desc = 'Close buffer' },
    },
    config = function()
      require('bufferline').setup {}
    end,
  },
}
