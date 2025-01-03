local M = {}
function M.setup()
  local visibilities = { "internal", "public", "protected", "private" }

  local augroup = vim.api.nvim_create_augroup("virtual-visibility", {})

  local ns = vim.api.nvim_create_namespace("virtual-visibility")

  ---@param node TSNode
  local function has_explicit_visibility(node)
    return vim.iter(node:iter_children()):any(function(child)
      if child:type() ~= "modifier" then
        return false
      end
      local a, b, c, d = child:range()
      local modifier = vim.api.nvim_buf_get_text(0, a, b, c, d, {})[1]
      return vim.tbl_contains(visibilities, modifier)
    end)
  end

  local function show_virtual_visibility()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    vim.api.nvim_set_hl_ns(ns)
    vim.api.nvim_set_hl(ns, "VirtualVisibility", { fg = 13346551, bg = "black" })

    local lang = "c_sharp"
    local doc = vim.treesitter.get_parser(0, lang):parse()[1]:root()

    local query_local_functions = vim.treesitter.query.parse(lang, [[ (local_function_statement) @local ]])
    -- TODO: handle structs too
    local query_private_members = vim.treesitter.query.parse(
      "c_sharp",
      [[ 
        (class_declaration 
            body: (
                declaration_list 
                [
                    (field_declaration) @field 
                    (property_declaration) @property 
                    (method_declaration) @method
                ]
            )) 
    ]]
    )
    local query_internal_types = vim.treesitter.query.parse(
      "c_sharp",
      [[ 
        [
            (class_declaration) @class
            (struct_declaration) @struct
            (interface_declaration) @interface
        ]
    ]]
    )

    for id, node, meta, match in query_local_functions:iter_captures(doc, 0) do
      local a, b, c, d = node:range()
      vim.api.nvim_buf_set_extmark(0, ns, a, b, {
        right_gravity = false,
        virt_text_pos = "inline",
        virt_text = { { "local", "VirtualVisibility" }, { " " } },
      })
    end

    for id, node, meta, match in query_private_members:iter_captures(doc, 0) do
      local a, b, c, d = node:range()
      if not has_explicit_visibility(node) then
        vim.api.nvim_buf_set_extmark(0, ns, a, b, {
          right_gravity = false,
          virt_text_pos = "inline",
          virt_text = { { "private", "VirtualVisibility" }, { " " } },
        })
      end
    end

    for id, node, meta, match in query_internal_types:iter_captures(doc, 0) do
      local a, b, c, d = node:range()
      if not has_explicit_visibility(node) then
        local a, b, c, d = node:range()
        vim.api.nvim_buf_set_extmark(0, ns, a, b, {
          right_gravity = false,
          virt_text_pos = "inline",
          virt_text = { { "internal", "VirtualVisibility" }, { " " } },
        })
      end
    end
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = "*.cs",
    callback = show_virtual_visibility,
  })
end
return M
