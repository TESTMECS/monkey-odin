package monkey

import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:strings"

DEBUG :: false

// Compiler=>>begin
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
	scopes_idx:                   int,
	compile_program:              proc(c: ^Compiler, node: Ast_Program) -> (err: string),
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

define_builtins :: proc(c: ^Compiler) {
	// Don't pre-add builtins to the symbol table.
	// They will be added when they're actually referenced.
}

Compiler__New__ :: proc() -> Compiler {
	compiler := Compiler {
		compiler_state               = Compiler_State_New(),
		scopes_idx                   = 0,
		compile_program              = compile_program,
		compile                      = compile,
		emit                         = emit,
		bytecode                     = bytecode,
		enter_scope                  = enter_scope,
		leave_scope                  = leave_scope,
		current_instructions         = current_instructions,
		set_last_instruction         = set_last_instruction,
		add_instructions             = add_instructions,
		replace_last_pop_with_return = replace_last_pop_with_return,
		add_constant                 = add_constant,
		remove_last_pop              = remove_last_pop,
		last_instruction_is          = last_instruction_is,
		replace_instructions         = replace_instructions,
		change_operand               = change_operand,
	}
	define_builtins(&compiler)
	return compiler
}

compiler_error :: proc(c: ^Compiler, msg: string, args: ..any) -> (err: string) {
	strings.builder_reset(&c.sb)
	fmt.sbprintf(&c.sb, "compiler error: %s", msg, args)
	err = strings.to_string(c.sb)
	return
}

compile :: proc(c: ^Compiler, ast: Node) -> (err: string) {
	err = ""
	varena := virtual.arena_allocator(c.vmem)
	#partial switch data in ast {
	case Ast_Let:
		if err = c->compile(data.value^); err != "" do return
		symbol := c.symbol_table->define(data.name, varena)
		c->emit(.Set_G if symbol.scope == .Global else .Set_L, symbol.index)
	case Ast_Ret:
		if err = c->compile(data.return_value^); err != "" do return
		c->emit(.Ret_V)
	case Ast_Identifier:
		if symbol, ok := c.symbol_table->resolve(data.value); !ok {
			// Check if this is a builtin that hasn't been defined yet
			builtin_fn := find_builtin_fn(data.value)
			if builtin_fn != nil {
				// Add this builtin to the symbol table
				c.symbol_table->define_builtin(data.value, len(c.symbol_table.store))
				symbol, ok = c.symbol_table->resolve(data.value)
				if !ok {
					err = compiler_error(c, "failed to resolve builtin '%s' after defining it", data.value)
					return
				}
				c->emit(.Cnst, c->add_constant(builtin_fn))
			} else {
				err = compiler_error(c, "identifier '%s' is not declared", data.value)
				return
			}
		} else {
			if symbol.scope == .Builtin {
				builtin_fn := find_builtin_fn(data.value)
				if builtin_fn == nil {
					err = compiler_error(c, "builtin function '%s' not found", data.value)
					return
				}
				c->emit(.Cnst, c->add_constant(builtin_fn))
			} else {
				c->emit(.Get_G if symbol.scope == .Global else .Get_L, symbol.index)
			}
		}
	case Ast_Infix:
		if data.op == "<" {
			if err = c->compile(data.right^); err != "" do return
			if err = c->compile(data.left^); err != "" do return
			c->emit(.Gt)
			return
		}
		if err = c->compile(data.left^); err != "" do return
		if err = c->compile(data.right^); err != "" do return
		switch data.op {
		case "+":
			c->emit(.Add)
		case "-":
			c->emit(.Sub)
		case "*":
			c->emit(.Mul)
		case "/":
			c->emit(.Div)
		case ">":
			c->emit(.Gt)
		case "==":
			c->emit(.Eq)
		case "!=":
			c->emit(.Neq)
		case:
			err = compiler_error(c, "unknown infix operator '%s'", data.op)
			return
		}
	case Ast_Prefix:
		if err = c->compile(data.operand^); err != "" do return
		switch data.op {
		case "!":
			c->emit(.Not)
		case "-":
			c->emit(.Neg)
		case:
			err = compiler_error(c, "unknown prefix operator '%s'", data.op)
			return
		}
	case Ast_If:
		if err = c->compile(data.condition^); err != "" do return

		jump_if_not_pos := c->emit(.Jmp_If_Not, 9999)

		if err = c->compile(data.then); err != "" do return

		if c->last_instruction_is(.Pop) do c->remove_last_pop()
		jump_pos := c->emit(.Jmp, 9999)

		orelse_pos := len(c->current_instructions())
		c->change_operand(jump_if_not_pos, orelse_pos)

		if data.orelse == nil {
			c->emit(.Nil)
		} else {
			if err = c->compile(data.orelse); err != "" do return
			if c->last_instruction_is(.Pop) do c->remove_last_pop()
		}

		after_orelse_pos := len(c->current_instructions())
		c->change_operand(jump_pos, after_orelse_pos)
	case Ast_Block:
		for s in data {
			if err = c->compile(s); err != "" do return
			if Ast_IsExpr(s) {
				c->emit(.Pop)
			}
		}
	case Ast_Array:
		for el in data {
			if err = c->compile(el); err != "" do return
		}
		c->emit(.Arr, len(data))
	case Ast_Hash_Table:
		for pair in data.pairs {
			if err = c->compile(pair.key); err != "" do return
			if err = c->compile(pair.value); err != "" do return
		}
		c->emit(.Ht, len(data.pairs) * 2)
	case Ast_Index:
		if err = c->compile(data.operand^); err != "" do return
		if err = c->compile(data.index^); err != "" do return
		c->emit(.Idx)
	case Ast_Function:
		c->enter_scope()
		for param in data.parameters {
			c.symbol_table->define(param.value, varena)
		}
		if err = c->compile(data.body); err != "" do return
		if c->last_instruction_is(.Pop) do c->replace_last_pop_with_return()
		if !c->last_instruction_is(.Ret_V) && !c->last_instruction_is(.Ret) do c->emit(.Ret_V if len(c->current_instructions()) > 0 else .Ret)
		num_locals := len(c.symbol_table.store)
		instructions := c->leave_scope()

		// Create a deep copy of instructions for the function
		varena := virtual.arena_allocator(c.vmem)
		instr_copy := make(Instructions, len(instructions), varena)
		copy(instr_copy[:], instructions[:])

		compiled_fn := ObjectCompiledFunction {
			instructions   = instr_copy,
			num_locals     = num_locals,
			num_parameters = len(data.parameters),
		}

		c->emit(.Cnst, c->add_constant(compiled_fn))
	case Ast_Call:
		if err = c->compile(data.function^); err != "" do return
		for arg in data.arguments {
			if err = c->compile(arg); err != "" do return
		}
		c->emit(.Call, len(data.arguments))
	case Ast_Macro:
		// Macros are handled during expansion, so we shouldn't reach here
		err = compiler_error(c, "macro encountered during compilation - should have been expanded")
		return
	case int:
		c->emit(.Cnst, c->add_constant(data)) // returns 0
	case bool:
		c->emit(.True if data else .False)
	case string:
		str_clone, _ := strings.clone(data, varena)
		c->emit(.Cnst, c->add_constant(str_clone))
	}
	return
} // end <<Compiler
// Compiler_helpers=>>begin
compile_program :: proc(c: ^Compiler, program: Ast_Program) -> (err: string) {
	err = ""
	
	// Expand macros before compilation
	expanded_program, expand_err := expand_macros(program, c.vmem)
	if expand_err != "" {
		err = compiler_error(c, "macro expansion error: %s", expand_err)
		return
	}
	
	for stmt in expanded_program.(Ast_Program) {
		if err = c->compile(stmt); err != "" do return
		if Ast_IsExpr(stmt) {
			c->emit(.Pop)
		}
	}
	return
}

emit :: proc(c: ^Compiler, op: Opcode, operands: ..int) -> int {
	varena := virtual.arena_allocator(c.vmem)
	ins := make_instructions(varena, op, ..operands)
	pos := c->add_instructions(ins[:])
	c->set_last_instruction(op, pos)
	return pos
}

bytecode :: proc(c: ^Compiler) -> Bytecode {
	return {instructions = c->current_instructions()[:], constants = c.compiler_state.constants[:]}
}

enter_scope :: proc(c: ^Compiler) {
	varena := virtual.arena_allocator(c.vmem)
	scope := Compilation_Scope{}
	instr := make(Instructions, 0, varena)
	scope.instructions = instr
	append(&c.scopes, scope)
	c.scopes_idx = len(c.scopes) - 1
	symbol_clone := new_clone(c.symbol_table, varena) // Clone
	c.symbol_table = Symbol_Table_New(varena, outer = symbol_clone)
}

leave_scope :: proc(c: ^Compiler) -> ^Instructions {
	instructions := c->current_instructions()
	pop(&c.scopes)
	c.scopes_idx = len(c.scopes) - 1
	c.symbol_table = c.symbol_table.outer^
	return instructions
}

current_instructions :: proc(c: ^Compiler) -> ^Instructions {
	return &c.scopes[c.scopes_idx].instructions
}

set_last_instruction :: proc(c: ^Compiler, op: Opcode, pos: int) {
	varena := virtual.arena_allocator(c.vmem)
	prev := c.scopes[c.scopes_idx].last_instruction
	last := new(Emitted_Instruction, varena)
	last.op_code = op
	last.pos = pos
	c.scopes[c.scopes_idx].previous_instruction = prev
	c.scopes[c.scopes_idx].last_instruction = last
}

add_instructions :: proc(c: ^Compiler, instructions: []byte) -> int {
	pos := len(c->current_instructions())
	n, err := append(c->current_instructions(), ..instructions)
	if err != nil {
		log.errorf("appending instructions to scope %v failed with: %v", c.scopes[0], err)
	}
	return pos
}

replace_last_pop_with_return :: proc(c: ^Compiler) {
	varena := virtual.arena_allocator(c.vmem)

	last_pop := c.scopes[c.scopes_idx].last_instruction.pos
	if DEBUG do fmt.printf("replacing last pop with return at %v\n", last_pop)

	c->replace_instructions(last_pop, make_instructions(varena, .Ret_V)[:])

	c.scopes[c.scopes_idx].last_instruction.op_code = .Ret_V
}

add_constant :: proc(c: ^Compiler, obj: ObjectBase) -> int {
	append(&c.compiler_state.constants, obj)
	return len(c.compiler_state.constants) - 1
}

remove_last_pop :: proc(c: ^Compiler) {
	ordered_remove(c->current_instructions(), c.scopes[c.scopes_idx].last_instruction.pos)
	c.scopes[c.scopes_idx].last_instruction = c.scopes[c.scopes_idx].previous_instruction
}

last_instruction_is :: proc(c: ^Compiler, op: Opcode) -> bool {
	if len(c->current_instructions()) == 0 do return false
	return c.scopes[c.scopes_idx].last_instruction.op_code == op
}

replace_instructions :: proc(c: ^Compiler, pos: int, new_instructions: []byte) {
	ins := c->current_instructions()
	for i := 0; i < len(new_instructions); i += 1 {
		ins[pos + i] = new_instructions[i]
	}
}

change_operand :: proc(c: ^Compiler, pos: int, new_operand: int) {
	varena := virtual.arena_allocator(c.vmem)
	op := Opcode(c->current_instructions()[pos])
	new_instructions := make_instructions(varena, op, new_operand)
	c->replace_instructions(pos, new_instructions[:])
} //end <<Compiler_helpers

