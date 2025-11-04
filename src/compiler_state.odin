package monkey

import "core:mem"
import "core:strings"

// compiler-state=>>begin
Compiler_State :: struct {
	varena:       mem.Allocator,
	symbol_table: Symbol_Table,
	globals:      []ObjectBase,
	constants:    [dynamic]ObjectBase,
	scopes:       [dynamic]Compilation_Scope,
	sb:           strings.Builder,
}

Compiler_State_New :: proc(varena: mem.Allocator) -> Compiler_State {
	scopes := make([dynamic]Compilation_Scope, 0, STACK_SIZE, varena) // $vm::STACK_SIZE
	main_scope: Compilation_Scope
	main_scope_instructions := make(Instructions, 0, varena)
	main_scope.instructions = main_scope_instructions
	append(&scopes, main_scope) // append main scope

	return Compiler_State {
		constants = make([dynamic]ObjectBase, 0, varena),
		globals = make([]ObjectBase, GLOBALS_SIZE, varena),
		symbol_table = Symbol_Table_New(varena),
		scopes = scopes,
		varena = varena,
	}
}

