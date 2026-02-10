package main

// Lua code strings for ExecLua calls.
// Each function uses ... varargs so Go passes arguments separately via msgpack.

const luaGetDefinition = `return require('lsp_gateway').get_definition(...)`

const luaGetReferences = `return require('lsp_gateway').get_references(...)`

const luaGetHover = `return require('lsp_gateway').get_hover(...)`

const luaGetDocumentSymbols = `return require('lsp_gateway').get_document_symbols(...)`

const luaGetDiagnostics = `return require('lsp_gateway').get_diagnostics(...)`

const luaHealth = `return require('lsp_gateway').health()`
