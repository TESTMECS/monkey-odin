package monkey

import "core:fmt"
import "core:log"
import "core:strings"

DEBUG :: false

// compiler-state=>>begin
Compiler_State :: struct {
	vmem:         ^VArena,
	symbol_table: Symbol_Table,
	globals:      []ObjectBase,
	constants:    [dynamic]ObjectBase,
	scopes:       [dynamic]Compilation_Scope,
	free:         proc(state: ^Compiler_State),
}

Compiler_State__New__ :: proc() -> Compiler_State {
	v := new(VArena, context.allocator) // @free-arena-ptr
	v^ = VArena__New__()
	err := v->init()
	if err != nil {
		panic("Arena Allocation Failed: Evaluator_new")
	}

	scopes := make([dynamic]Compilation_Scope, 0, STACK_SIZE, v.allocator) // $vm::STACK_SIZE
	main_scope := Compilation_Scope{}
	main_scope_instructions := make(Instructions, 0, v.allocator)
	main_scope.instructions = main_scope_instructions
	append(&scopes, main_scope)

	return Compiler_State {
		constants = make([dynamic]ObjectBase, 0, v.allocator),
		globals = make([]ObjectBase, GLOBALS_SIZE, v.allocator),
		symbol_table = __New__Symbol_Table(v.allocator),
		scopes = scopes,
		free = free_state,
		vmem = v,
	}
}

free_state :: proc(state: ^Compiler_State) {
	state.vmem->reset()
	state.symbol_table->free()
	free(state.vmem, context.allocator) // @free-arena-ptr
} //end <<Compiler_State
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

Compiler__New__ :: proc() -> Compiler {
	return Compiler {
		compiler_state = Compiler_State__New__(),
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

compile :: proc(c: ^Compiler, ast: Node) -> (err: string) {
	err = ""
	#partial switch data in ast {
	case Ast_Let:
		if err = c->compile(data.value^); err != "" do return
		symbol := c.symbol_table->define(data.name, c.vmem.allocator)
		c->emit(.Set_G if symbol.scope == .Global else .Set_L, symbol.index)
	case Ast_Ret:
		if err = c->compile(data.return_value^); err != "" do return
		c->emit(.Ret_V)
	case Ast_Identifier:
		symbol, ok := c.symbol_table->resolve(data.value)
		if !ok {
			sb := &c.compiler_state.vmem.string_builder
			strings.builder_reset(sb)
			fmt.sbprintf(sb, "identifier '%s' is not declared", data.value)
			err = strings.to_string(sb^)
			return
		}
		c->emit(.Get_G if symbol.scope == .Global else .Get_L, symbol.index)
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
			sb := &c.compiler_state.vmem.string_builder
			strings.builder_reset(sb)
			fmt.sbprintf(sb, "unknown infix operator '%s'", data.op)
			err = strings.to_string(sb^)
		}
	case Ast_Prefix:
		if err = c->compile(data.operand^); err != "" do return
		switch data.op {
		case "!":
			c->emit(.Not)
		case "-":
			c->emit(.Neg)
		case:
			sb := &c.compiler_state.vmem.string_builder
			strings.builder_reset(sb)
			fmt.sbprintf(sb, "unknown prefix operator '%s'", data.op)
			err = strings.to_string(sb^)
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
		// if DEBUG do log.infof("compiling array literal")
		for el in data {
			if err = c->compile(el); err != "" do return
		}
		c->emit(.Arr, len(data))
	case Ast_Hash_Table:
		if DEBUG do log.infof("compiling hash table literal")

		// Compile in the same order the user wrote in source
		for pair in data.pairs {
			if DEBUG do log.infof("compiling key")
			if err = c->compile(pair.key); err != "" do return

			if DEBUG do log.infof("compiling value")
			if err = c->compile(pair.value); err != "" do return
		}

		// Emit hash-table construction instruction.
		// Each pair contributes 2 items (key + value)
		c->emit(.Ht, len(data.pairs) * 2)
	case Ast_Index:
		if err = c->compile(data.operand^); err != "" do return
		if err = c->compile(data.index^); err != "" do return
		c->emit(.Idx)
	//%NOTE: gonna need to fix this.
	case Ast_Function:
		c->enter_scope()
		for param in data.parameters {
			c.symbol_table->define(param.value, c.vmem.allocator)
		}
		if err = c->compile(data.body); err != "" do return
		if c->last_instruction_is(.Pop) do c->replace_last_pop_with_return()
		if !c->last_instruction_is(.Ret_V) do c->emit(.Ret_V)
		num_locals := len(c.symbol_table.store)

		instructions := c->leave_scope()
		// Probably wrong.
		instr := make(Instructions, len(instructions), c.compiler_state.vmem.allocator)

		compiled_fn := ObjectCompiledFunction {
			instructions   = &instr,
			num_locals     = num_locals,
			num_parameters = len(data.parameters),
		}
		if len(instructions) > 0 {
			inject_at(compiled_fn.instructions, 0, ..instructions[:])
		}
		c->emit(.Cnst, c->add_constant(compiled_fn))
	case Ast_Call:
		if err = c->compile(data.function^); err != "" do return
		for arg in data.arguments {
			if err = c->compile(arg); err != "" do return
		}
		c->emit(.Call, len(data.arguments))
	case int:
		c->emit(.Cnst, c->add_constant(data)) // returns 0
	case bool:
		c->emit(.True if data else .False)
	case string:
		str_clone, _ := strings.clone(data, c.compiler_state.vmem.allocator)
		c->emit(.Cnst, c->add_constant(str_clone))
	}
	return
} // end <<Compiler
// Compiler_helpers=>>begin
compile_program :: proc(c: ^Compiler, program: Ast_Program) -> (err: string) {
	if DEBUG do log.infof("compiling program")
	err = ""
	for stmt in program {
		if err = c->compile(stmt); err != "" do return
		if Ast_IsExpr(stmt) {
			c->emit(.Pop)
		}
	}
	return
}

emit :: proc(c: ^Compiler, op: Opcode, operands: ..int) -> int {
	if DEBUG do log.infof("emitting %v", op)
	ins := make_instructions(c.vmem.allocator, op, ..operands)
	pos := c->add_instructions(ins[:])
	c->set_last_instruction(op, pos)
	return pos
}

bytecode :: proc(c: ^Compiler) -> Bytecode {
	return {instructions = c->current_instructions()[:], constants = c.compiler_state.constants[:]}
}

enter_scope :: proc(c: ^Compiler) {
	if DEBUG do log.infof("entering scope %v", c.scopes_idx)
	scope := Compilation_Scope{}
	instr := make(Instructions, 0, c.compiler_state.vmem.allocator)
	scope.instructions = instr
	append(&c.scopes, scope)
	c.scopes_idx = len(c.scopes) - 1
	symbol_clone := new_clone(c.symbol_table, c.vmem.allocator)
	c.symbol_table = __New__Symbol_Table(c.vmem.allocator, outer = symbol_clone)
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
	prev := c.scopes[c.scopes_idx].last_instruction
	last := new(Emitted_Instruction, c.vmem.allocator)
	last.op_code = op
	last.pos = pos
	c.scopes[c.scopes_idx].previous_instruction = prev
	c.scopes[c.scopes_idx].last_instruction = last
}

add_instructions :: proc(c: ^Compiler, instructions: []byte) -> int {
	// if DEBUG do log.infof("adding instructions to scope %v", c.scopes[0])
	pos := len(c->current_instructions())
	// if DEBUG do log.infof("scopes len %v, %v, %v", len(c.scopes), c.scopes[0], instructions)
	n, err := append(c->current_instructions(), ..instructions)
	// if DEBUG do log.infof("%d", n)
	if err != nil {
		log.errorf("appending instructions to scope %v failed with: %v", c.scopes[0], err)
	}
	// if DEBUG do log.infof("added instructions to scope %v", c.scopes[0])
	return pos
}

replace_last_pop_with_return :: proc(c: ^Compiler) {
	last_pop := c.scopes[c.scopes_idx].last_instruction.pos
	c->replace_instructions(last_pop, make_instructions(c.vmem.allocator, .Ret_V)[:])
	c.scopes[c.scopes_idx].last_instruction.op_code = .Ret_V
	unimplemented("replace_last_pop_with_return")
}

add_constant :: proc(c: ^Compiler, obj: ObjectBase) -> int {
	// if DEBUG do log.infof("adding constant %v", obj)
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
	op := Opcode(c->current_instructions()[pos])
	new_instructions := make_instructions(c.vmem.allocator, op, new_operand)
	c->replace_instructions(pos, new_instructions[:])
} //end <<Compiler_helpers

