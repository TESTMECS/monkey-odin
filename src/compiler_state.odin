package monkey

import "core:mem"
import "core:strings"

Compiler_State :: struct {
	varena:        mem.Allocator,
	symbol_table:  Symbol_Table,
	globals:       []ObjectBase,
	constants:     [dynamic]ObjectBase,
	scopes:        [dynamic]Compilation_Scope,
	cli_arguments: []string,
	sb:            strings.Builder,
	mexpand_rec:   int,
}

Compiler_State_New :: proc(varena: mem.Allocator, cli_args: []string, mexpand_rec := 1) -> Compiler_State {
	scopes := make([dynamic]Compilation_Scope, 0, STACK_SIZE, varena)
	main_scope: Compilation_Scope
	main_scope_instructions := make(Instructions, 0, varena)
	main_scope.instructions = main_scope_instructions
	append(&scopes, main_scope)

	return Compiler_State {
		constants = make([dynamic]ObjectBase, 0, varena),
		globals = make([]ObjectBase, GLOBALS_SIZE, varena),
		cli_arguments = cli_args,
		symbol_table = Symbol_Table_New(varena),
		scopes = scopes,
		varena = varena,
		mexpand_rec = mexpand_rec,
	}
}

