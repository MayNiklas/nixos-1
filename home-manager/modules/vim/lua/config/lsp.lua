require'lspconfig'.pyright.setup{}
require'lspconfig'.gopls.setup{}
require'lspconfig'.terraformls.setup{}
require'lspconfig'.bashls.setup{}
require'lspconfig'.yamlls.setup{}

require'lspconfig'.sumneko_lua.setup {
    cmd = { 'lua-language-server' },
    settings = {
	Lua = {
	    diagnostics = {
		-- Get the language server to recognize the `vim` global
		globals = { 'vim' }
	    },
	    -- Do not send telemetry data containing a randomized but unique identifier
	    telemetry = {
		enable = false,
	    },
	}
    },
    -- on_attach = custom_attach,
}

require'lspconfig'.jsonls.setup {

    cmd = { "json-languageserver", "--stdio" },
    commands = {
	Format = {
	    function()
		vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
	    end
	}
    }
}

-- lspconfig updates while typing
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
vim.lsp.diagnostic.on_publish_diagnostics, { update_in_insert = true, })

-- TODO auto-format on save
-- autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 100)
-- autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 100)
-- autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 100
