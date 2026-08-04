local M = {}

local CONTEXT_LINES = 15

local function fuzzy_match(str, pattern)
  local pat_i, score = 1, 0
  local lower_str = str:lower()
  local lower_pat = pattern:lower()
  local prev_match = false

  for i = 1, #lower_str do
    if pat_i <= #lower_pat and lower_str:sub(i, i) == lower_pat:sub(pat_i, pat_i) then
      pat_i = pat_i + 1
      score = score + (prev_match and 2 or 1)
      prev_match = true
    else
      prev_match = false
    end
  end

  return pat_i > #lower_pat, score
end

local function ft_from_path(path)
  local ext = vim.fn.fnamemodify(path, ":e")
  local map = { go = "go", py = "python", ts = "typescript", tsx = "typescriptreact", js = "javascript", lua = "lua", json = "json", yaml = "yaml", yml = "yaml" }
  return map[ext] or ext
end

local function open_picker(items, opts)
  opts = opts or {}
  if #items == 0 then
    vim.notify("No results", vim.log.levels.INFO)
    return
  end
  if #items == 1 then
    opts.on_select(items[1])
    return
  end

  local ns = vim.api.nvim_create_namespace("lsp_picker")
  local hl_ns = vim.api.nvim_create_namespace("lsp_picker_hl")
  local query = ""
  local selected = 1
  local filtered = vim.list_slice(items)

  local total_width = math.min(180, math.floor(vim.o.columns * 0.9))
  local list_width = math.min(60, math.floor(total_width * 0.35))
  local preview_width = total_width - list_width - 1
  local list_height = math.max(16, math.floor(vim.o.lines * 0.85) - 4)
  local preview_height = list_height + 2
  local row = math.floor((vim.o.lines - (list_height + 4)) / 2)
  local col = math.floor((vim.o.columns - total_width) / 2)

  local list_buf = vim.api.nvim_create_buf(false, true)
  local preview_buf = vim.api.nvim_create_buf(false, true)
  local prompt_buf = vim.api.nvim_create_buf(false, true)

  vim.bo[preview_buf].bufhidden = "wipe"

  -- Layout:
  -- ╭── List ──┬── Preview ──╮
  -- │          │             │
  -- ├──────────┤             │
  -- │ > query  │             │
  -- ╰──────────┴─────────────╯

  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor",
    row = row,
    col = col + list_width + 1,
    width = preview_width,
    height = preview_height,
    style = "minimal",
    border = { "┬", "─", "╮", "│", "╯", "─", "┴", "│" },
    title = "Preview",
    title_pos = "center",
  })

  local list_win = vim.api.nvim_open_win(list_buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = list_width,
    height = list_height,
    style = "minimal",
    border = { "╭", "─", "┬", "│", "┤", "─", "├", "│" },
    title = opts.title or "LSP Results",
    title_pos = "center",
  })

  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
    relative = "editor",
    row = row + list_height + 2,
    col = col,
    width = list_width,
    height = 1,
    style = "minimal",
    border = { "", "", "", "│", "┴", "─", "╰", "│" },
  })

  vim.wo[list_win].cursorline = true
  vim.wo[preview_win].number = true
  vim.wo[preview_win].cursorline = true

  local cmp_ok, cmp = pcall(require, "cmp")
  if cmp_ok then
    cmp.setup.buffer({ enabled = false })
  end

  vim.bo[prompt_buf].buftype = "nofile"
  vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "> " })
  pcall(vim.api.nvim_win_set_cursor, prompt_win, { 1, 2 })

  local preview_cache = {}

  local function update_preview()
    if #filtered == 0 then
      vim.bo[preview_buf].modifiable = true
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "  No results" })
      vim.bo[preview_buf].modifiable = false
      pcall(vim.api.nvim_win_set_config, preview_win, { title = " Preview ", title_pos = "center" })
      return
    end

    local item = filtered[selected]
    if not item then return end

    local all_lines = preview_cache[item.path]
    if not all_lines then
      local ok, result = pcall(vim.fn.readfile, item.path)
      all_lines = ok and result or { "  Could not read file" }
      preview_cache[item.path] = all_lines
    end

    vim.bo[preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, all_lines)
    vim.bo[preview_buf].modifiable = false

    local ft = ft_from_path(item.path)
    if ft and ft ~= "" then
      pcall(vim.treesitter.start, preview_buf, ft)
    end

    if item.lnum >= 1 and item.lnum <= #all_lines then
      pcall(vim.api.nvim_win_set_cursor, preview_win, { item.lnum, 0 })
      vim.api.nvim_win_call(preview_win, function() vim.cmd("normal! zz") end)
    end

    vim.api.nvim_buf_clear_namespace(preview_buf, hl_ns, 0, -1)
    if item.lnum >= 1 and item.lnum <= #all_lines then
      vim.api.nvim_buf_add_highlight(preview_buf, hl_ns, "Visual", item.lnum - 1, 0, -1)
    end

    local title = vim.fn.fnamemodify(item.path, ":~:.")
    if #title > preview_width - 4 then
      title = "…" .. title:sub(-(preview_width - 5))
    end
    pcall(vim.api.nvim_win_set_config, preview_win, { title = " " .. title .. " ", title_pos = "center" })
  end

  local function truncate(str, max_width)
    if vim.fn.strdisplaywidth(str) <= max_width then return str end
    while vim.fn.strdisplaywidth(str) > max_width - 1 do
      str = str:sub(1, #str - 1)
    end
    return str .. "…"
  end

  local function render()
    local lines = {}
    local icon_hls = {}
    local pad = math.max(0, list_height - #filtered)
    for _ = 1, pad do
      lines[#lines + 1] = ""
      icon_hls[#icon_hls + 1] = nil
    end
    for _, item in ipairs(filtered) do
      local prefix = item.icon and (item.icon .. " ") or ""
      lines[#lines + 1] = truncate(prefix .. item.display, list_width)
      icon_hls[#icon_hls + 1] = item.icon_hl
    end
    vim.bo[list_buf].modifiable = true
    vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, lines)
    vim.bo[list_buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
    for i, item in ipairs(filtered) do
      if item.icon_hl and item.icon then
        local row = pad + i - 1
        local icon_bytes = vim.fn.strlen(item.icon)
        vim.api.nvim_buf_add_highlight(list_buf, ns, item.icon_hl, row, 0, icon_bytes)
      end
    end
    if selected >= 1 and selected <= #filtered then
      pcall(vim.api.nvim_win_set_cursor, list_win, { pad + selected, 0 })
    end

    update_preview()
  end

  local function filter()
    if query == "" then
      filtered = vim.list_slice(items)
    else
      filtered = {}
      local scored = {}
      for _, item in ipairs(items) do
        local ok, score = fuzzy_match(item.display, query)
        if ok then
          scored[#scored + 1] = { item = item, score = score }
        end
      end
      table.sort(scored, function(a, b) return a.score > b.score end)
      for _, s in ipairs(scored) do
        filtered[#filtered + 1] = s.item
      end
    end
    selected = 1
    render()
  end

  local function close()
    pcall(vim.api.nvim_win_close, prompt_win, true)
    pcall(vim.api.nvim_win_close, list_win, true)
    pcall(vim.api.nvim_win_close, preview_win, true)
    pcall(vim.api.nvim_buf_delete, prompt_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, list_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
  end

  local function confirm()
    if #filtered == 0 then
      close()
      return
    end
    local item = filtered[selected]
    close()
    if item and opts.on_select then
      vim.schedule(function() opts.on_select(item) end)
    end
  end

  render()

  vim.keymap.set("i", "<CR>", confirm, { buffer = prompt_buf })
  vim.keymap.set("i", "<Esc>", function()
    close()
    vim.cmd("stopinsert")
  end, { buffer = prompt_buf })
  vim.keymap.set("i", "<C-c>", function()
    close()
    vim.cmd("stopinsert")
  end, { buffer = prompt_buf })

  local function move_down()
    selected = math.min(selected + 1, #filtered)
    render()
  end
  local function move_up()
    selected = math.max(selected - 1, 1)
    render()
  end

  vim.keymap.set("i", "<C-n>", move_down, { buffer = prompt_buf })
  vim.keymap.set("i", "<C-p>", move_up, { buffer = prompt_buf })
  vim.keymap.set("i", "<Down>", move_down, { buffer = prompt_buf })
  vim.keymap.set("i", "<Up>", move_up, { buffer = prompt_buf })

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = prompt_buf,
    callback = function()
      local line = vim.api.nvim_buf_get_lines(prompt_buf, 0, 1, false)[1] or ""
      local new_query = line:match("^> ?(.*)$") or line
      if new_query ~= query then
        query = new_query
        filter()
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = prompt_buf,
    once = true,
    callback = close,
  })

  vim.cmd("startinsert!")
end

local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

local function get_icon(filename)
  if not devicons_ok then return "", nil end
  local ext = vim.fn.fnamemodify(filename, ":e")
  local icon, hl = devicons.get_icon(filename, ext, { default = true })
  return icon or "", hl
end

local function location_to_item(loc, client)
  local uri = loc.uri or loc.targetUri
  local range = loc.range or loc.targetSelectionRange
  local path = vim.uri_to_fname(uri)
  local short = vim.fn.fnamemodify(path, ":~:.")
  local fname = vim.fn.fnamemodify(path, ":t")
  local lnum = range.start.line + 1
  local col = range.start.character + 1

  local icon, icon_hl = get_icon(fname)

  return {
    display = short .. ":" .. lnum,
    icon = icon,
    icon_hl = icon_hl,
    path = path,
    lnum = lnum,
    col = col,
  }
end

local function jump_to(item)
  vim.cmd("edit " .. vim.fn.fnameescape(item.path))
  vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
  vim.cmd("normal! zz")
end

local function lsp_request(method, params, title)
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP client attached", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf_request_all(0, method, params, function(results)
    vim.schedule(function()
      local items = {}
      for client_id, result in pairs(results) do
        if result.result then
          local client = vim.lsp.get_client_by_id(client_id)
          for _, loc in ipairs(result.result) do
            items[#items + 1] = location_to_item(loc, client)
          end
        end
      end
      open_picker(items, { title = title, on_select = jump_to })
    end)
  end)
end

function M.references()
  local params = vim.lsp.util.make_position_params()
  params.context = { includeDeclaration = true }
  lsp_request("textDocument/references", params, "References")
end

function M.implementations()
  local params = vim.lsp.util.make_position_params()
  lsp_request("textDocument/implementation", params, "Implementations")
end

function M.definitions()
  local params = vim.lsp.util.make_position_params()
  lsp_request("textDocument/definition", params, "Definitions")
end

function M.document_symbols()
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return end

  vim.lsp.buf_request_all(0, "textDocument/documentSymbol", params, function(results)
    vim.schedule(function()
      local items = {}
      local path = vim.api.nvim_buf_get_name(0)
      local kind_names = vim.lsp.protocol.SymbolKind

      local symbol_icons = {
        File = "󰈙", Module = "󰏗", Namespace = "󰅩", Package = "󰏗",
        Class = "󰠱", Method = "󰊕", Property = "󰜢", Field = "󰜢",
        Constructor = "󰒓", Enum = "󰕘", Interface = "󰕘", Function = "󰊕",
        Variable = "󰀫", Constant = "󰏿", String = "󰉿", Number = "󰎠",
        Boolean = "◩", Array = "󰅪", Object = "󰅩", Key = "󰌋",
        Null = "󰟢", EnumMember = "󰕘", Struct = "󰠱", Event = "󰉁",
        Operator = "󰆕", TypeParameter = "󰊄",
      }
      local icon, icon_hl = get_icon(vim.fn.fnamemodify(path, ":t"))

      local function collect(symbols, prefix)
        for _, sym in ipairs(symbols) do
          local kind = kind_names[sym.kind] or "Unknown"
          local range = sym.selectionRange or sym.range or sym.location.range
          local lnum = range.start.line + 1
          local name = prefix .. sym.name
          local sym_icon = symbol_icons[kind] or icon or ""
          items[#items + 1] = {
            display = string.format("[%s] %s :%d", kind, name, lnum),
            icon = sym_icon,
            icon_hl = icon_hl,
            path = path,
            lnum = lnum,
            col = range.start.character + 1,
          }
          if sym.children then
            collect(sym.children, name .. ".")
          end
        end
      end

      for _, result in pairs(results) do
        if result.result then
          collect(result.result, "")
        end
      end
      open_picker(items, { title = "Document Symbols", on_select = jump_to })
    end)
  end)
end

function M.buffer_lines()
  local path = vim.api.nvim_buf_get_name(0)
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local fname = vim.fn.fnamemodify(path, ":t")
  local icon, icon_hl = get_icon(fname)
  local items = {}

  for i, line in ipairs(buf_lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      items[#items + 1] = {
        display = string.format("%4d  %s", i, trimmed),
        path = path,
        lnum = i,
        col = 1,
      }
    end
  end

  open_picker(items, { title = "Buffer Lines", on_select = jump_to })
end

return M
