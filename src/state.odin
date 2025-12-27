package monkey
import "core:mem"
import "core:strings"
/*
* Copyright (C) 2025 TESTMEE
*/
// Lexer
Token_Type :: enum {
	Illegal,
	EOF,
	Identifier,
	Int,
	String,
	Assign,
	Plus,
	Minus,
	Bang,
	Asterisk,
	Slash,
	Less_Than,
	Greater_Than_Equal,
	Less_Than_Equal,
	Greater_Than,
	Equal,
	Not_Equal,
	Comma,
	Semicolon,
	Colon,
	Left_Paren,
	Right_Paren,
	Left_Brace,
	Right_Brace,
	Left_Bracket,
	Right_Bracket,
	Function,
	Let,
	True,
	False,
	If,
	Else,
	Return,
	Macro,
	For,
	Foreach,
	In,
	Question_Mark,
	Percent,
	Pipe,
	RShift,
	LShift,
	Ampersand,
	Caret,
	Lor,
	Land,
	Tilde,
	Arrow,
}
Token :: struct {
	type:       Token_Type,
	text_slice: []u8,
}
Lexer_VTable :: struct {
	next_token: proc(l: ^Lexer) -> Token,
	read_char:  proc(l: ^Lexer),
}
Lexer :: struct {
	input:        []u8, // input string
	pos:          int, // current position in input
	read_pos:     int, // l.pos + 1
	ch:           u8, // current character
	using vtable: Lexer_VTable,
}
Lexer_New :: proc(input: string) -> Lexer {
	l := Lexer {
		ch         = 0,
		input      = transmute([]u8)input,
		pos        = 0,
		read_pos   = 0,
		next_token = next_token,
		vtable     = LEXERVTABLE,
	}
	read_char(&l)
	return l
}
// Parser
Precedence :: enum {
	Lowest       = 0,
	Assign       = 1,
	Equals       = 2,
	Less_Greater = 3,
	Sum          = 4,
	Product      = 5,
	Prefix       = 6,
	Call         = 7,
	Index        = 8,
}
@(rodata)
GetPrecedence := #partial [Token_Type]Precedence {
	.Plus               = .Sum,
	.Minus              = .Sum,
	.Pipe               = .Sum,
	.Caret              = .Sum,
	.Ampersand          = .Sum,
	.Lor                = .Sum,
	.Land               = .Sum,
	.Asterisk           = .Product,
	.Slash              = .Product,
	.Percent            = .Product,
	.RShift             = .Product,
	.LShift             = .Product,
	.Less_Than          = .Less_Greater,
	.Greater_Than       = .Less_Greater,
	.Greater_Than_Equal = .Less_Greater,
	.Less_Than_Equal    = .Less_Greater,
	.Equal              = .Equals,
	.Not_Equal          = .Equals,
	.Question_Mark      = .Equals,
	.Assign             = .Assign,
	.Left_Paren         = .Call,
	.Arrow              = .Call,
	.Macro              = .Lowest,
	.Left_Bracket       = .Index,
}
Parser_VTable :: struct {
	parse:       proc(p: ^Parser) -> Ast_Program,
	advance:     proc(p: ^Parser),
	parse_error: proc(p: ^Parser, str: string, args: ..any),
}
Parser :: struct {
	l:            Lexer,
	cur_token:    Token,
	peek_token:   Token,
	varena:       mem.Allocator,
	errors:       [dynamic]string,
	sb:           strings.Builder,
	using vtable: Parser_VTable,
}
Parser_New :: proc(input: string, varena: mem.Allocator) -> Parser {
	return Parser {
		varena = varena,
		errors = make([dynamic]string, 0, varena),
		l = Lexer_New(input),
		vtable = PARSERVTABLE,
	}
}
// Evaluator
Environment :: struct {
	store: map[string]ObjectBase,
	outer: ^Environment,
	get:   proc(env: ^Environment, name: string) -> (ObjectBase, bool),
	set:   proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase,
	free:  proc(env: ^Environment),
}
Env_New :: proc(outer: ^Environment = nil, allocator: mem.Allocator) -> Environment {
	store_mem := make(map[string]ObjectBase, 0, allocator)
	return {
		get = environment_get,
		set = environment_set,
		free = environment_free,
		outer = outer,
		store = store_mem,
	}
}
Env_Enclosed :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator: mem.Allocator,
) -> ^Environment {
	env := Env_New(outer, allocator)
	env.store = make(map[string]ObjectBase, reserved, allocator)
	return new_clone(env, allocator)
}
@(private = "file")
environment_free :: proc(env: ^Environment) {
	delete(env.store)
}
@(private = "file")
environment_get :: proc(env: ^Environment, name: string) -> (ObjectBase, bool) {
	obj, ok := env.store[name]
	if !ok && env.outer != nil {obj, ok = env.outer->get(name)}

	return obj, ok
}
@(private = "file")
environment_set :: proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase {
	env.store[name] = value
	return value
}
Eval_VTable :: struct {
	eval:           proc(
		e: ^Evaluator,
		node: Ast_Program,
		allocator: mem.Allocator,
	) -> (
		ObjectBase,
		bool,
	),
	eval_new_error: proc(e: ^Evaluator, str: string, args: ..any) -> string,
}
Evaluator :: struct {
	_env:         Environment,
	varena:       mem.Allocator,
	sb:           strings.Builder,
	args:         []string,
	using vtable: Eval_VTable,
}
Evaluator_New :: proc(varena: mem.Allocator) -> Evaluator {
	return Evaluator{_env = Env_New(nil, varena), varena = varena, vtable = EVALVTABLE}
}
// Compiler
Symbol_Scope :: enum {
	Global,
	Local,
	Builtin,
}
Symbol :: struct {
	name:  string,
	scope: Symbol_Scope,
	index: int,
}
Symbol_Table :: struct {
	store:          map[string]Symbol,
	outer:          ^Symbol_Table,
	free:           proc(table: ^Symbol_Table),
	define:         proc(table: ^Symbol_Table, name: string, allocator: mem.Allocator) -> Symbol,
	define_builtin: proc(table: ^Symbol_Table, name: string, index: int),
	resolve:        proc(table: ^Symbol_Table, name: string) -> (Symbol, bool),
}
Symbol_Table_New :: proc(allocator: mem.Allocator, outer: ^Symbol_Table = nil) -> Symbol_Table {
	return Symbol_Table {
		store = make(map[string]Symbol, allocator),
		outer = outer,
		free = proc(table: ^Symbol_Table) {
			delete(table.store)
		},
		define = proc(table: ^Symbol_Table, name: string, allocator: mem.Allocator) -> Symbol {
			name_copied := strings.clone(name, allocator)
			scope: Symbol_Scope = .Global if table.outer == nil else .Local
			symbol := Symbol{name_copied, scope, len(table.store)}
			table.store[name_copied] = symbol
			return symbol
		},
		define_builtin = proc(table: ^Symbol_Table, name: string, index: int) {
			name_copied := strings.clone(name, table.store.allocator)
			symbol := Symbol{name_copied, .Builtin, index}
			table.store[name_copied] = symbol
		},
		resolve = proc(table: ^Symbol_Table, name: string) -> (Symbol, bool) {
			obj, ok := table.store[name]
			if !ok && table.outer != nil do return table.outer->resolve(name)
			return obj, ok
		},
	}
}
Compiler_VTable :: struct {
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
	symbol_table:  Symbol_Table,
	globals:       []ObjectBase,
	constants:     [dynamic]ObjectBase,
	scopes:        [dynamic]Compilation_Scope,
	cli_arguments: []string,
	mexpand_rec:   int,
	scopes_idx:    int,
	sb:            strings.Builder,
	varena:        mem.Allocator,
	using vtable:  Compiler_VTable,
}
Compiler_New :: proc(varena: mem.Allocator, cli_args: []string, mexpand_rec := 1) -> Compiler {
	scopes := make([dynamic]Compilation_Scope, 0, STACK_SIZE, varena)
	main_scope: Compilation_Scope
	main_scope_instructions := make(Instructions, 0, varena)
	main_scope.instructions = main_scope_instructions
	append(&scopes, main_scope)

	return Compiler {
		constants = make([dynamic]ObjectBase, 0, varena),
		globals = make([]ObjectBase, GLOBALS_SIZE, varena),
		cli_arguments = cli_args,
		symbol_table = Symbol_Table_New(varena),
		scopes = scopes,
		varena = varena,
		mexpand_rec = mexpand_rec,
		scopes_idx = 0,
		vtable = COMPILERVTABLE,
	}
}
Frame :: struct {
	instructions: []byte,
	ip:           int,
	base_pointer: int,
}
frame :: proc(instructions: []byte, base_pointer: int) -> Frame {
	return Frame{instructions, -1, base_pointer}
}
STACK_SIZE :: 2048
GLOBALS_SIZE :: 65536
MAX_FRAMES :: 1024
VM :: struct {
	varena:                 mem.Allocator,
	compiler_state:         ^Compiler,
	constants:              []ObjectBase,
	frames:                 []Frame,
	frames_idx:             int,
	stack:                  []ObjectBase,
	sp:                     int, //Top of stack is sp-1
	sb:                     strings.Builder,
	run_vm:                 proc(v: ^VM) -> (err: string),
	stack_top:              proc(v: ^VM) -> ObjectBase,
	last_popped_stack_elem: proc(v: ^VM) -> ObjectBase,
	current_frame:          proc(v: ^VM) -> ^Frame,
	push_vm:                proc(v: ^VM, obj: ObjectBase) -> (err: string),
	pop_vm:                 proc(v: ^VM) -> ObjectBase,
	last_popped:            proc(v: ^VM) -> ObjectBase,
	exec_binary_op:         proc(v: ^VM, op: Opcode) -> (err: string),
	exec_binary_int_op:     proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string),
	exec_binary_float_op:   proc(v: ^VM, op: Opcode, left: f64, right: f64) -> (err: string),
	exec_binary_string_op:  proc(v: ^VM, op: Opcode, left: string, right: string) -> (err: string),
	exec_compare_op:        proc(v: ^VM, op: Opcode) -> (err: string),
	exec_compare_int_op:    proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string),
	exec_compare_float_op:  proc(v: ^VM, op: Opcode, left: f64, right: f64) -> (err: string),
	exec_not_op:            proc(v: ^VM) -> (err: string),
	exec_neg_op:            proc(v: ^VM) -> (err: string),
	exec_idx_expr:          proc(v: ^VM, operand, index: ObjectBase) -> (err: string),
	exec_arr_idx:           proc(v: ^VM, arr: ObjectArray, index: int) -> (err: string),
	exec_ht_idx:            proc(v: ^VM, ht: ObjectHashTable, key: string) -> (err: string),
	exec_set_idx_expr:      proc(v: ^VM, operand, index, value: ObjectBase) -> (err: string),
	exec_arr_set_idx:       proc(
		v: ^VM,
		arr: ObjectArray,
		index: int,
		value: ObjectBase,
	) -> (
		err: string
	),
	exec_call:              proc(v: ^VM, num_args: int) -> (err: string),
	build_array:            proc(v: ^VM, start, end: int) -> ObjectBase,
	build_hash_table:       proc(v: ^VM, start, end: int) -> (ObjectBase, string),
	pop_frame:              proc(v: ^VM) -> ^Frame,
	push_frame:             proc(v: ^VM, f: Frame),
}
Vm_New :: proc(bytecode: Bytecode, compiler: ^Compiler, varena: mem.Allocator) -> VM {
	vm := VM {
		compiler_state        = compiler,
		stack                 = make([]ObjectBase, STACK_SIZE, varena),
		frames                = make([]Frame, MAX_FRAMES, varena),
		frames_idx            = 0,
		constants             = bytecode.constants,
		varena                = varena,
		sb                    = strings.builder_make(varena),
		run_vm                = run_vm,
		current_frame         = current_frame,
		push_vm               = push_vm,
		pop_vm                = pop_vm,
		last_popped           = last_popped,
		stack_top             = stack_top,
		exec_binary_op        = exec_binary_op,
		exec_binary_int_op    = exec_binary_int_op,
		exec_binary_float_op  = exec_binary_float_op,
		exec_binary_string_op = exec_binary_string_op,
		exec_compare_op       = exec_compare_op,
		exec_compare_int_op   = exec_compare_int_op,
		exec_compare_float_op = exec_compare_float_op,
		exec_not_op           = exec_not_op,
		exec_neg_op           = exec_neg_op,
		exec_idx_expr         = exec_idx_expr,
		exec_arr_idx          = exec_arr_idx,
		exec_ht_idx           = exec_ht_idx,
		exec_set_idx_expr     = exec_set_idx_expr,
		exec_arr_set_idx      = exec_arr_set_idx,
		exec_call             = exec_call,
		build_array           = build_array,
		build_hash_table      = build_hash_table,
		pop_frame             = pop_frame,
		push_frame            = push_frame,
	}
	main_frame := frame(bytecode.instructions[:], 0)
	vm.push_frame(&vm, main_frame)
	return vm
}

