local visibilities = { "internal", "public", "protected", "private", "file" }
local ns = vim.api.nvim_create_namespace("csharp:virtual-text")
vim.api.nvim_set_hl_ns(ns)
vim.api.nvim_set_hl(ns, "VirtualVisibility", { fg = 13346551, bg = "black" })

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

local function get_root_node(lang, bufnr)
  return vim.treesitter.get_parser(bufnr or 0, lang):parse()[1]:root()
end

---@param doc TSNode
---@param query vim.treesitter.Query
---@param visibility string | function
local function apply_visibility(doc, query, visibility)
  for id, node, meta, match in query:iter_captures(doc, 0) do
    if not has_explicit_visibility(node) then
      local first_non_attribute_child = vim.iter(node:iter_children()):find(function(child)
        return child:type() ~= "attribute_list"
      end)

      local a, b, _, _ = first_non_attribute_child:range()

      local vis
      if type(visibility) == "string" then
        vis = visibility
      else
        vis = visibility(node)
      end
      vim.api.nvim_buf_set_extmark(0, ns, a, b, {
        right_gravity = false,
        virt_text_pos = "inline",
        virt_text = { { vis, "VirtualVisibility" }, { " " } },
      })
    end
  end
end

local function show_virtual_visibility()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local doc = get_root_node("c_sharp")

  local query_local_functions = vim.treesitter.query.parse("c_sharp", [[ (local_function_statement) @local ]])

  apply_visibility(doc, query_local_functions, "local")

  local query_members = vim.treesitter.query.parse(
    "c_sharp",
    [[
        [
            (field_declaration)
            (property_declaration)
            (method_declaration)
            (event_field_declaration)
        ] @member
    ]]
  )

  apply_visibility(doc, query_members, function(node)
    local visibility
    local is_explicit_interface_implementation = vim.iter(node:iter_children()):any(function(child)
      return child:type() == "explicit_interface_specifier"
    end)

    if is_explicit_interface_implementation then
      return "interface"
    elseif node:parent():parent():type() == "interface_declaration" then
      return "public"
    else
      return "private"
    end
  end)

  local query_internal_types = vim.treesitter.query.parse(
    "c_sharp",
    [[
        [
            (class_declaration)
            (struct_declaration)
            (interface_declaration)
            (record_declaration)
            (enum_declaration)
            (delegate_declaration)
            (event_declaration)
        ] @type
    ]]
  )

  apply_visibility(doc, query_internal_types, "internal")

  local query_constructors = vim.treesitter.query.parse(
    "c_sharp",
    [[
        (constructor_declaration) @method
    ]]
  )

  apply_visibility(doc, query_constructors, "public")
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("csharp:virtual-visibility", {}),
  buffer = 0,
  callback = show_virtual_visibility,
})

vim.schedule(show_virtual_visibility)
