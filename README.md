# Neovim plugin

Setup with Lazy plugin manager.
```lua
return {
  "CharlesTaylor7/virtual-visibility.nvim",
}
```

The plugin uses the cs filetype to autoload so its not doing anything on non-C# files.

## Debugging

Open a C# file, and use `:InspectTree` command to see the treesitter parse tree.
