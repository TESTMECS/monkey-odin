-- DEBUG for my tree-sitter-highlights in nvim
local ok, err = pcall(vim.treesitter.require_language, "monkey")
print(ok, err)
-- print(vim.inspect(vim.opt.runtimepath:get()))
print(vim.inspect(vim.api.nvim_get_runtime_file("parser/monkey.so", true)))

print(vim.inspect(vim.api.nvim_get_runtime_file("parser/monkey.so", true)))

local ok, err = pcall(vim.treesitter.require_language, "monkey", nil, true)
print("ok =", ok, "err =", err)
print(vim.inspect(vim.treesitter.language_version))
print(vim.inspect(vim.api.nvim_get_runtime_file("queries/monkey/*", true)))
local lang = vim.treesitter.language.get_lang("monkey")
print(lang)
-- :lua dofile("treesitter.lua")
-- vim.filetype.add({
-- 	extension = {
-- 		monkey = "monkey",
-- 	},
-- })
