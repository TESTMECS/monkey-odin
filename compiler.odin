package monkey
/*%NOTE{{"Never use the procs in the struct like this again.
	I really like the c->method() syntax but for testing its buns ->
`+++ leak       384B @ 0x7872031FD048 [compiler.odin:166:monkey::Compiler__New__$anon-38()]`
This leak could be anywhere in the functions on the compiler, assert checking and logging is the only way to find it."}}
*/
import "core:fmt"
import "core:log"
import "core:mem"
import "core:reflect"
import "core:slice"
import "core:strings"
import "core:testing"

DEBUG :: true

//%section Compiler_State
Compiler_State :: struct {
	symbol_table: Symbol_Table,
	constants:    [dynamic]ObjectBase,
	globals:      []ObjectBase,
	scopes:       [dynamic]Compilation_Scope,
	free:         proc(state: ^Compiler_State),
	vmem:         ^VArena, // ALLOCATE ON THE HEAP so it doesn't get bye bye
}
Compiler_State__New__ :: proc() -> Compiler_State {
	v := new(VArena, context.allocator)
	v^ = VArena__New__()
	err := v->init()
	if err != nil {
		panic("Arena Allocation Failed: Evaluator_new")
	}

	// Scopes init, limit is STACK_SIZE
	scopes := make([dynamic]Compilation_Scope, 0, STACK_SIZE, v.allocator)
	main_scope := Compilation_Scope{}
	main_scope_instructions := make(Instructions, 0, v.allocator)
	main_scope.instructions = main_scope_instructions
	append(&scopes, main_scope)

	return Compiler_State {
		globals = make([]ObjectBase, GLOBALS_SIZE, v.allocator),
		symbol_table = Symbol_Table__New__(v.allocator),
		scopes = scopes,
		free = proc(state: ^Compiler_State) {
			state.vmem->reset() // scope is freed here.
			state.symbol_table->free()

			delete(state.scopes)
			// delete(state.globals)
			delete(state.constants)
			free(state.vmem, context.allocator)
		},
		vmem = v,
	}
}
//%endsection
//%section compiler typedefs
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

	//%methods
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
//%endsection
//%section Public Functions
Compiler__New__ :: proc() -> Compiler {
	return Compiler {
		compiler_state               = Compiler_State__New__(),
		scopes_idx                   = 0,
		//%methods
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
}
//%endsection
//%section: main recursive compile method
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
			if Ast__IsExpression__(s) {
				c->emit(.Pop)
			}
		}
	case Ast_Array:
		if DEBUG do log.infof("compiling array literal")
		for el in data {
			if err = c->compile(el); err != "" do return
		}
		c->emit(.Arr, len(data))
	case Ast_Hash_Table:
		keys := make([]string, len(data), c.compiler_state.vmem.allocator)
		i := 0
		for key in data {
			keys[i] = key
			i += 1
		}
		slice.reverse_sort(keys)

		for k in keys {
			if err = c->compile(k); err != "" do return
			if err = c->compile(data[k]); err != "" do return
		}
		c->emit(.Ht, len(data) * 2)
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
}
//%section: compiler methods.
compile_program :: proc(c: ^Compiler, program: Ast_Program) -> (err: string) {
	if DEBUG do log.infof("compiling program")
	err = ""
	for stmt in program {
		if err = c->compile(stmt); err != "" do return
		if Ast__IsExpression__(stmt) {
			c->emit(.Pop)
		}
	}
	return
}
emit :: proc(c: ^Compiler, op: Opcode, operands: ..int) -> int {
	//%desc{{"emits an instruction to the current scope"}}
	if DEBUG do log.infof("emitting %v", op)
	// Try to pop but scope is empty
	ins := make_instructions(c.vmem.allocator, op, ..operands)
	pos := c->add_instructions(ins[:])
	c->set_last_instruction(op, pos)
	return pos
}
bytecode :: proc(c: ^Compiler) -> Bytecode {
	//%desc{{"returns the bytecode for the current scope"}}
	return {instructions = c->current_instructions()[:], constants = c.compiler_state.constants[:]}
}
enter_scope :: proc(c: ^Compiler) {
	//%desc{{"enters a new scope"}}
	//%desc{{"TODO"}}
	if DEBUG do log.infof("entering scope %v", c.scopes_idx)
	scope := Compilation_Scope{}
	instr := make(Instructions, 0, c.compiler_state.vmem.allocator)
	scope.instructions = instr
	append(&c.scopes, scope)
	c.scopes_idx = len(c.scopes) - 1
	symbol_clone := new_clone(c.symbol_table, c.vmem.allocator)
	c.symbol_table = Symbol_Table__New__(c.vmem.allocator, outer = symbol_clone)
}
leave_scope :: proc(c: ^Compiler) -> ^Instructions {
	//%desc{{"leaves the current scope and returns the instructions"}}
	instructions := c->current_instructions()
	pop(&c.scopes)
	c.scopes_idx = len(c.scopes) - 1
	c.symbol_table = c.symbol_table.outer^
	return instructions
}
current_instructions :: proc(c: ^Compiler) -> ^Instructions {
	if DEBUG do log.infof("current_instructions %v", c.scopes[c.scopes_idx])
	return &c.scopes[c.scopes_idx].instructions
}
set_last_instruction :: proc(c: ^Compiler, op: Opcode, pos: int) {
	//%desc{{"sets the last instruction for the current scope"}}
	prev := c.scopes[c.scopes_idx].last_instruction
	last := new(Emitted_Instruction, c.vmem.allocator)
	last.op_code = op
	last.pos = pos
	c.scopes[c.scopes_idx].previous_instruction = prev
	c.scopes[c.scopes_idx].last_instruction = last
}
add_instructions :: proc(c: ^Compiler, instructions: []byte) -> int {
	//%desc{{"adds instructions to the current scope"}}
	if DEBUG do log.infof("adding instructions to scope %v", c.scopes[0])
	pos := len(c->current_instructions())
	if DEBUG do log.infof("scopes len %v, %v, %v", len(c.scopes), c.scopes[0], instructions)
	n, err := append(c->current_instructions(), ..instructions)
	if DEBUG do log.infof("%d", n)
	if err != nil {
		log.errorf("appending instructions to scope %v failed with: %v", c.scopes[0], err)
	}
	if DEBUG do log.infof("added instructions to scope %v", c.scopes[0])
	return pos
}
replace_last_pop_with_return :: proc(c: ^Compiler) {
	//%desc{{"replaces the last pop instruction with a return instruction"}}
	last_pop := c.scopes[c.scopes_idx].last_instruction.pos
	c->replace_instructions(last_pop, make_instructions(c.vmem.allocator, .Ret_V)[:])
	c.scopes[c.scopes_idx].last_instruction.op_code = .Ret_V
	unimplemented("replace_last_pop_with_return")
}
add_constant :: proc(c: ^Compiler, obj: ObjectBase) -> int {
	if DEBUG do log.infof("adding constant %v", obj)
	append(&c.compiler_state.constants, obj)
	return len(c.compiler_state.constants) - 1
}
remove_last_pop :: proc(c: ^Compiler) {
	ordered_remove(c->current_instructions(), c.scopes[c.scopes_idx].last_instruction.pos)
	c.scopes[c.scopes_idx].last_instruction = c.scopes[c.scopes_idx].previous_instruction
}
last_instruction_is :: proc(c: ^Compiler, op: Opcode) -> bool {
	//%desc{{"returns true if the last instruction is of the given type"}}
	if len(c->current_instructions()) == 0 do return false
	return c.scopes[c.scopes_idx].last_instruction.op_code == op
}
replace_instructions :: proc(c: ^Compiler, pos: int, new_instructions: []byte) {
	//%desc{{"replaces instructions at the given position with the given instructions"}}
	ins := c->current_instructions()
	for i := 0; i < len(new_instructions); i += 1 {
		ins[pos + i] = new_instructions[i]
	}
}
change_operand :: proc(c: ^Compiler, pos: int, new_operand: int) {
	//%desc{{"changes the operand of the instruction at the given position"}}
	op := Opcode(c->current_instructions()[pos])
	new_instructions := make_instructions(c.vmem.allocator, op, new_operand)
	c->replace_instructions(pos, new_instructions[:])
}
//%endsection

//%section: tests
@(test)
test_compile_integer_arithmetic :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"1; 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Pop),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"-1",
			{1},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Neg),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 + 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Add),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 - 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Sub),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 * 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Mul),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 / 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Div),
				make_instructions(context.allocator, .Pop),
			},
		},
	}

	defer free_all(context.allocator)

	run_compiler_tests(t, tests[:])
}
@(test)
test_compile_boolean_expressions :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"true",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"false",
			{},
			{
				make_instructions(context.temp_allocator, .False),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"!true",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .Not),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 > 2",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Gt),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 < 2",
			{2, 1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Gt),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 == 2",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Eq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 != 2",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Neq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"true == false",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .False),
				make_instructions(context.temp_allocator, .Eq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"true != false",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .False),
				make_instructions(context.temp_allocator, .Neq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
@(test)
test_compile_if_expression :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"if true { 10 }; 3333;",
			{10, 3333},
			{
				// 0000
				make_instructions(context.temp_allocator, .True),
				// 0001
				make_instructions(context.temp_allocator, .Jmp_If_Not, 10),
				// 0004
				make_instructions(context.temp_allocator, .Cnst, 0),
				// 0007
				make_instructions(context.temp_allocator, .Jmp, 11),
				// 0010
				make_instructions(context.temp_allocator, .Nil),
				// 0011
				make_instructions(context.temp_allocator, .Pop),
				// 0012
				make_instructions(context.temp_allocator, .Cnst, 1),
				// 0015
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"if true { 10 } else { 20 }; 3333;",
			{10, 20, 3333},
			{
				// 0000
				make_instructions(context.temp_allocator, .True),
				// 0001
				make_instructions(context.temp_allocator, .Jmp_If_Not, 10),
				// 0004
				make_instructions(context.temp_allocator, .Cnst, 0),
				// 0007
				make_instructions(context.temp_allocator, .Jmp, 13),
				// 0010
				make_instructions(context.temp_allocator, .Cnst, 1),
				// 0013
				make_instructions(context.temp_allocator, .Pop),
				// 0014
				make_instructions(context.temp_allocator, .Cnst, 2),
				// 0017
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
@(test)
test_compile_global_let_statements :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"let one = 1; let two = 2;",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Set_G, 1),
			},
		},
		{
			"let one = 1; one;",
			{1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let one = 1; let two = one; two;",
			{1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Set_G, 1),
				make_instructions(context.temp_allocator, .Get_G, 1),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
@(test)
test_compile_string_expressions :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			`"monkey"`,
			{"monkey"},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`"mon" + "key"`,
			{"mon", "key"},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Add),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
@(test)
test_compile_array_literals :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"[]",
			{},
			{
				make_instructions(context.temp_allocator, .Arr, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"[1, 2, 3]",
			{1, 2, 3},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Arr, 3),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"[1 + 2, 3 - 4, 5 * 6]",
			{1, 2, 3, 4, 5, 6},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Add),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Cnst, 3),
				make_instructions(context.temp_allocator, .Sub),
				make_instructions(context.temp_allocator, .Cnst, 4),
				make_instructions(context.temp_allocator, .Cnst, 5),
				make_instructions(context.temp_allocator, .Mul),
				make_instructions(context.temp_allocator, .Arr, 3),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
//%endsection
//%section: test helpers
@(private = "file")
Compiler_Test_Data :: union {
	int,
	string,
	[]Instructions,
}
Compiler_Test_Case :: struct {
	input:                 string,
	expected_constants:    []Compiler_Test_Data,
	expected_instructions: []Instructions,
}
test_constants :: proc(
	expected: []Compiler_Test_Data,
	actual: []ObjectBase,
	alloc: mem.Allocator,
) -> (
	err: string,
) {
	if len(expected) != len(actual) {
		return fmt.tprintf(
			"wrong number of constants. wants='%d', got='%d'",
			len(expected),
			len(actual),
		)
	}
	err = ""
	for constant, i in expected {
		t := reflect.union_variant_typeid(constant)
		switch constant_value in constant {
		case int:
			err = test_integer_object(constant_value, actual[i])
		case string:
			err = test_string_object(constant_value, actual[i])
		case []Instructions:
			fn, ok := actual[i].(ObjectCompiledFunction)
			if !ok {
				err = fmt.tprintf("not a function: '%v'", ObjectType(actual[i]))
			} else {
				err = test_instructions(constant_value, fn.instructions[:], alloc)
			}
		}
		if err != "" {
			err = fmt.tprintf("constant '%v' - testing '%v' object failed with: %v", i, t, err)
			break
		}
	}
	return
}
run_compiler_tests :: proc(t: ^testing.T, tests: []Compiler_Test_Case) {
	for test_case, i in tests {
		p := Parser__New__(test_case.input)
		defer p->free()

		program := p->parse()
		if len(program) == 0 || len(p.errors) != 0 {
			log.errorf("Parsing encountered errors on test_case[%d]", i)
			for e in p.errors {
				log.error(e)
			}
			continue
		}

		c := Compiler__New__()
		defer c->free()

		err := c->compile_program(program)
		if err != "" {
			log.errorf("Compiling encountered errors on test_case[%d]", i)
			log.error(err)
			continue
		}

		bytecode := c->bytecode()
		err = test_instructions(
			test_case.expected_instructions[:],
			bytecode.instructions,
			context.allocator,
		)
		if err != "" {
			log.errorf("Instructions for test_case[%d] failed with: %v", i, err)
			continue
		}

		err = test_constants(test_case.expected_constants, bytecode.constants, context.allocator)
		if err != "" {
			log.errorf("Constants for test_case[%d] failed with: %v", i, err)
			continue
		}
	}
}
test_instructions :: proc(
	expected: []Instructions,
	actual: []byte,
	alloc: mem.Allocator,
) -> (
	err: string,
) {
	concatenated := concat_instructions(expected)
	if (len(actual) != len(concatenated)) {
		return fmt.tprintf(
			"wrong number of instructions. wants='%v', got='%v'",
			concatenated,
			actual,
		)
	}
	for ins, i in concatenated {
		if actual[i] != ins {
			return fmt.tprintf(
				"wrong instruction at '%d'. wants='%v', got='%v'",
				i,
				concatenated,
				actual,
			)
		}
	}
	return ""
}
//%endsection

