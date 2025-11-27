package monkey
import "core:mem"
import "core:strings"
/*
* Copyright (C) 2025 TESTMEE
* ./state.odin
* One-stop-shop for all State
* Sections: << Lexer >> << Parser >> << Evaluator >> << Compiler >> << VM >>
*/
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
GetPrecedence: [Token_Type]Precedence
init_precedences :: proc() {
	GetPrecedence = #partial {
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
	init_precedences()
	return Parser {
		varena = varena,
		errors = make([dynamic]string, 0, varena),
		l = Lexer_New(input),
		vtable = PARSERVTABLE,
	}
}
// Compiler
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
	varena:        mem.Allocator,
	symbol_table:  Symbol_Table,
	globals:       []ObjectBase,
	constants:     [dynamic]ObjectBase,
	scopes:        [dynamic]Compilation_Scope,
	cli_arguments: []string,
	sb:            strings.Builder,
	mexpand_rec:   int,
	scopes_idx:    int,
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

