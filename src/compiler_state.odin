package monkey

import "core:mem/virtual"
import "core:strings"

// compiler-state=>>begin
Compiler_State :: struct {
	vmem:         ^virtual.Arena,
	symbol_table: Symbol_Table,
	globals:      []ObjectBase,
	constants:    [dynamic]ObjectBase,
	scopes:       [dynamic]Compilation_Scope,
	sb:           strings.Builder,
	free:         proc(state: ^Compiler_State),
}

Compiler_State_New :: proc() -> Compiler_State {
	v: ^virtual.Arena = new(virtual.Arena, context.allocator)
	arena_err := virtual.arena_init_growing(v)
	ensure(arena_err == nil)
	varena := virtual.arena_allocator(v)

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
		free = free_state,
		vmem = v,
	}
}

free_state :: proc(state: ^Compiler_State) {
	virtual.arena_destroy(state.vmem)
	free(state.vmem, context.allocator) // @free-arena-ptr
} //end <<Compiler_State

