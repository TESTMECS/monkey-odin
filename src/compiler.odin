package monkey

import "core:encoding/endian"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"

DEBUG :: false

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
	find_class_constant:          proc(c: ^Compiler, class_name: string) -> (^ObjectClass, bool),
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
		find_class_constant = find_class_constant,
	}
}

compiler_error :: proc(c: ^Compiler, msg: string, args: ..any) -> (err: string) {
	strings.builder_reset(&c.sb)
	fmt.sbprintf(&c.sb, "compiler error: %v %v", msg, args)
	err = strings.to_string(c.sb)
	return
}

compile :: proc(c: ^Compiler, ast: Node) -> (err: string) {
	err = ""
	#partial switch data in ast {
	case Ast_Ternery:
		if err = c->compile(data.condition^); err != "" do return
		jump_if_not_pos := c->emit(.Jmp_If_Not, 9999)
		if err = c->compile(data.then^); err != "" do return
		if c->last_instruction_is(.Pop) do c->remove_last_pop()
		jump_pos := c->emit(.Jmp, 9999)
		orelse_pos := len(c->current_instructions())
		c->change_operand(jump_if_not_pos, orelse_pos)
		if data.orelse == nil {
			c->emit(.Nil)
		}
		 else {
			if err = c->compile(data.orelse^); err != "" do return
			if c->last_instruction_is(.Pop) do c->remove_last_pop()
		}
		after_orelse_pos := len(c->current_instructions())
		c->change_operand(jump_pos, after_orelse_pos)
	case Ast_Class:
		superclass: ^ObjectClass = nil
		if len(data.super) > 0 {
			super_ident := data.super[0]
			super_class_obj, found := c->find_class_constant(super_ident.value)
			if found {
				superclass = super_class_obj
			}
			 else {
				err = compiler_error(c, "superclass not found or not a class", super_ident.value)
				return
			}
		}
		methods := make(ObjectHashTable)
		for stmt in data.body {
			if let_stmt, is_let := stmt.(Ast_Let); is_let {
				if err = c->compile(let_stmt.value^); err != "" do return // method function
				if c->last_instruction_is(.Cnst) {
					last_instr := c.scopes[c.scopes_idx].last_instruction
					const_idx, _ := endian.get_u16(
						c->current_instructions()[last_instr.pos + 1:],
						.Big,
					)
					method_fn := c.compiler_state.constants[int(const_idx)]
					methods[let_stmt.name] = method_fn
				}
			}
		}
		class_obj := ObjectClass {
			name       = data.name,
			methods    = methods,
			superclass = superclass,
		}
		class_const_idx := c->add_constant(class_obj)
		c->emit(.Cnst, class_const_idx)
		symbol := c.symbol_table->define(data.name, c.varena)
		c->emit(.Set_G if symbol.scope == .Global else .Set_L, symbol.index)
	case Ast_Foreach:
		if err = c->compile(data.expr^); err != "" do return
		iter_pos := c->emit(.Iter_Init)
		symbol := c.symbol_table->define(data.itervar, c.varena)
		loop_start_pos := len(c->current_instructions())
		c->emit(.Iter_Next)
		jump_if_not_pos := c->emit(.Jmp_If_Not, 9999)
		c->emit(.Iter_Get)
		c->emit(.Set_L if symbol.scope == .Local else .Set_G, symbol.index)
		for stmt in data.body {
			if err = c->compile(stmt); err != "" do return
			if Ast_IsExpr(stmt) {
				c->emit(.Pop)
			}
		}
		c->emit(.Jmp, loop_start_pos)
		after_loop_pos := len(c->current_instructions())
		c->change_operand(jump_if_not_pos, after_loop_pos)
		c->emit(.Pop)
	case Ast_Let:
		_, is_function := data.value^.(Ast_Function)
		if is_function {
			symbol := c.symbol_table->define(data.name, c.varena)
			if err = c->compile(data.value^); err != "" do return
			c->emit(.Set_G if symbol.scope == .Global else .Set_L, symbol.index)
		}
		 else {
			if err = c->compile(data.value^); err != "" do return
			symbol := c.symbol_table->define(data.name, c.varena)
			c->emit(.Set_G if symbol.scope == .Global else .Set_L, symbol.index)
		}
	case Ast_Ret:
		if err = c->compile(data.return_value^); err != "" do return
		c->emit(.Ret_V)
	case Ast_Identifier:
		if symbol, ok := c.symbol_table->resolve(data.value); !ok {
			builtin_fn := find_builtin_fn(data.value)
			if builtin_fn != nil {
				c.symbol_table->define_builtin(data.value, len(c.symbol_table.store))
				symbol, ok = c.symbol_table->resolve(data.value)
				if !ok {
					err = compiler_error(
						c,
						"failed to resolve builtin after defining it",
						data.value,
					)
					return
				}
				c->emit(.Cnst, c->add_constant(builtin_fn))
			}
			 else {
				err = compiler_error(c, "identifier is not declared", data.value)
				return
			}
		}
		 else {
			if symbol.scope == .Builtin {
				builtin_fn := find_builtin_fn(data.value)
				if builtin_fn == nil {
					err = compiler_error(c, "builtin function not found", data.value)
					return
				}
				c->emit(.Cnst, c->add_constant(builtin_fn))
			}
			 else {
				c->emit(.Get_G if symbol.scope == .Global else .Get_L, symbol.index)
			}
		}
	case Ast_Infix:
		if data.op == "=" {
			#partial switch left in data.left^ {
			case Ast_Identifier:
				// Assignment
				if err = c->compile(data.right^); err != "" do return
				symbol, ok := c.symbol_table->resolve(left.value)
				if !ok {
					err = compiler_error(c, "identifier is not declared: ", left.value)
					return
				}
				c->emit(.Set_G if symbol.scope == .Global else .Set_L, symbol.index)
				c->emit(.Get_G if symbol.scope == .Global else .Get_L, symbol.index)
			// index
			case Ast_Index:
				if err = c->compile(left.operand^); err != "" do return

				#partial switch idx_type in left.index^ {
				case Ast_Identifier:
					// a[i] AND self[x]
					idx := left.index.(Ast_Identifier)
					if err = c->compile(data.right^); err != "" do return
					if left.operand.(Ast_Identifier).value == "self" {
						c->emit(.Set_Field, c->add_constant(idx.value))
					}
					 else {
						c->emit(.Idx)
					}
				case:
					if err = c->compile(left.index^); err != "" do return
					if err = c->compile(data.right^); err != "" do return
					c->emit(.SetIdx)
				}
			}
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
		case ">=":
			c->emit(.Gte)
		case "<":
			c->emit(.Lt)
		case "<=":
			c->emit(.Lte)
		case "==":
			c->emit(.Eq)
		case "!=":
			c->emit(.Neq)
		case:
			err = compiler_error(c, "unknown infix operator", data.op)
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
			err = compiler_error(c, "unknown prefix operator", data.op)
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
		}
		 else {
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
		#partial switch idx_type in data.index^ {
		case Ast_Identifier:
			if err = c->compile(data.index^); err != "" do return
			c->emit(.Idx)
		case Ast_Method_Call:
			err = "method call cannot be used as index"
			return
		case:
			if err = c->compile(data.index^); err != "" do return
			c->emit(.Idx)
		}
	case Ast_Function:
		// Function
		c->enter_scope()
		for param in data.parameters {
			c.symbol_table->define(param.value, c.varena)
		}
		if err = c->compile(data.body); err != "" do return
		if c->last_instruction_is(.Pop) do c->replace_last_pop_with_return() // implicit return
		if !c->last_instruction_is(.Ret_V) && !c->last_instruction_is(.Ret) do c->emit(.Ret_V if len(c->current_instructions()) > 0 else .Ret) // explicit
		num_locals := len(c.symbol_table.store)
		instructions := c->leave_scope()
		instr_copy := make(Instructions, len(instructions), c.varena)
		copy(instr_copy[:], instructions[:])
		compiled_fn := ObjectCompiledFunction {
			instructions   = instr_copy,
			num_locals     = num_locals,
			num_parameters = len(data.parameters),
		}
		c->emit(.Cnst, c->add_constant(compiled_fn))
	case Ast_Call:
		// fmt.println(data.arguments)
		if err = c->compile(data.function^); err != "" do return
		for arg in data.arguments {
			if err = c->compile(arg); err != "" do return
		}
		c->emit(.Call, len(data.arguments))
	case Ast_Method_Call:
		if err = c->compile(data.object^); err != "" do return
		if method_ident, ok := data.method^.(Ast_Identifier); ok {
			c->emit(.Get_Method, c->add_constant(method_ident.value))
		}
		 else {
			err = "method name must be identifier"
			return
		}
		for arg in data.arguments {
			if err = c->compile(arg); err != "" do return
		}
		c->emit(.Call, len(data.arguments))
	case Ast_Macro:
		err = compiler_error(c, "macro encountered during compilation - should have been expanded")
		return
	case Ast_For:
		condition_start_pos := len(c->current_instructions())
		if err = c->compile(data.cond^); err != "" do return
		jump_if_not_pos := c->emit(.Jmp_If_Not, 9999)
		for s in data.body {
			if err = c->compile(s); err != "" do return
		}
		jump_back_pos := c->emit(.Jmp, 9999)
		after_loop_pos := len(c->current_instructions())
		c->change_operand(jump_if_not_pos, after_loop_pos)
		c->change_operand(jump_back_pos, condition_start_pos)
	case int:
		c->emit(.Cnst, c->add_constant(data))
	case f64:
		c->emit(.Cnst, c->add_constant(data))
	case bool:
		c->emit(.True if data else .False)
	case string:
		str_clone, _ := strings.clone(data, c.varena)
		c->emit(.Cnst, c->add_constant(str_clone))
	}
	return
} // end <<Compiler
// Compiler_helpers=>>begin
compile_program :: proc(c: ^Compiler, program: Ast_Program, mexpand_rec := 1) -> (err: string) {
	// run by main.odin, compiles all statements in the program after macro expansion
	err = ""
	expanded_program, e1 := expand_macros(program, c.mexpand_rec, c.varena) // macro expansion
	if e1 != "" {
		err = compiler_error(c, "macro expansion error:", e1)
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
	ins := make_instructions(c.varena, op, ..operands)
	pos := c->add_instructions(ins[:])
	c->set_last_instruction(op, pos)
	return pos
}

bytecode :: proc(c: ^Compiler) -> Bytecode {
	return {instructions = c->current_instructions()[:], constants = c.compiler_state.constants[:]}
}

enter_scope :: proc(c: ^Compiler) {
	scope := Compilation_Scope{}
	instr := make(Instructions, 0, c.varena)
	scope.instructions = instr
	append(&c.scopes, scope)
	c.scopes_idx = len(c.scopes) - 1
	symbol_clone := new_clone(c.symbol_table, c.varena) // Clone
	c.symbol_table = Symbol_Table_New(c.varena, outer = symbol_clone)
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
	last := new(Emitted_Instruction, c.varena)
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
	last_pop := c.scopes[c.scopes_idx].last_instruction.pos

	c->replace_instructions(last_pop, make_instructions(c.varena, .Ret_V)[:])

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
	op := Opcode(c->current_instructions()[pos])
	new_instructions := make_instructions(c.varena, op, new_operand)
	c->replace_instructions(pos, new_instructions[:])
}

find_class_constant :: proc(c: ^Compiler, class_name: string) -> (^ObjectClass, bool) {
	for i := 0; i < len(c.compiler_state.constants); i += 1 {
		const_obj := c.compiler_state.constants[i]
		if class_obj, is_class := const_obj.(ObjectClass); is_class {
			if class_obj.name == class_name {
				persistent_class := new(ObjectClass, c.varena)
				persistent_class^ = class_obj
				return persistent_class, true
			}
		}
	}
	return nil, false
} //end <<Compiler_helpers

