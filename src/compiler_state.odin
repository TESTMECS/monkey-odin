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

Compiler_State_New :: proc(
	varena: mem.Allocator,
	cli_args: []string,
	mexpand_rec := 1,
) -> Compiler_State {
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

Emitted_Instruction :: struct {
	op_code: Opcode,
	pos:     int,
}

Bytecode :: struct {
	instructions: []byte,
	constants:    []ObjectBase,
}

Compilation_Scope :: struct {
	instructions:         Instructions,
	last_instruction:     ^Emitted_Instruction,
	previous_instruction: ^Emitted_Instruction,
}

Compiler :: struct {
	using compiler_state:         Compiler_State,
	scopes_idx:                   int, // lowkey should be in compiler state
	compile_program:              proc(
		c: ^Compiler,
		node: Ast_Program,
		mexpand_rec := 1,
	) -> (
		err: string
	),
	compile:                      proc(c: ^Compiler, node: Node) -> (err: string),
	emit:                         proc(c: ^Compiler, op: Opcode, operands: ..int) -> int,
	bytecode:                     proc(c: ^Compiler) -> Bytecode,
	enter_scope:                  proc(c: ^Compiler),
	leave_scope:                  proc(c: ^Compiler) -> ^Instructions,
	current_instructions:         proc(c: ^Compiler) -> ^Instructions,
	set_last_instruction:         proc(c: ^Compiler, op: Opcode, pos: int),
	add_instructions:             proc(c: ^Compiler, instructions: []byte) -> int,
	replace_last_pop_with_return: proc(c: ^Compiler),
	add_constant:                 proc(c: ^Compiler, obj: ObjectBase) -> int,
	remove_last_pop:              proc(c: ^Compiler),
	last_instruction_is:          proc(c: ^Compiler, op: Opcode) -> bool,
	replace_instructions:         proc(c: ^Compiler, pos: int, new_instructions: []byte),
	change_operand:               proc(c: ^Compiler, pos: int, new_operand: int),
}

Compiler_New :: proc(varena: mem.Allocator, cli_args: []string, mexpand_rec := 1) -> Compiler {
	return Compiler {
		compiler_state = Compiler_State_New(varena, cli_args, mexpand_rec),
		scopes_idx = 0,
		compile_program = compile_program,
		compile = compile,
		emit = emit,
		bytecode = bytecode,
		enter_scope = enter_scope,
		leave_scope = leave_scope,
		current_instructions = current_instructions,
		set_last_instruction = set_last_instruction,
		add_instructions = add_instructions,
		replace_last_pop_with_return = replace_last_pop_with_return,
		add_constant = add_constant,
		remove_last_pop = remove_last_pop,
		last_instruction_is = last_instruction_is,
		replace_instructions = replace_instructions,
		change_operand = change_operand,
	}
}

