#+feature dynamic-literals
package monkey
import "core:fmt"
import "core:mem/virtual"
import "core:strconv"
import "core:strings"

Parser :: struct {
	l:          Lexer,
	cur_token:  Token,
	peek_token: Token,
	errors:     [dynamic]string,
	vmem:       ^virtual.Arena,
	sb:         strings.Builder,
	parse:      proc(p: ^Parser) -> Ast_Program,
	free:       proc(p: ^Parser),
}

Parser__New__ :: proc(input: string) -> Parser {
	v: ^virtual.Arena = new(virtual.Arena, context.allocator)
	arena_err := virtual.arena_init_growing(v)
	ensure(arena_err == nil)
	varena := virtual.arena_allocator(v)

	// Initialize precedences
	init_precedences()

	p := Parser {
		vmem   = v,
		errors = make([dynamic]string, 0, varena),
		l      = Lexer_New(input),
		parse  = parse_program,
		free   = free_parser,
	}
	return p
}

free_parser :: proc(p: ^Parser) {
	virtual.arena_destroy(p.vmem)
	free(p.vmem, context.allocator)
}

parse_program :: proc(p: ^Parser) -> Ast_Program {
	varena := virtual.arena_allocator(p.vmem)
	next_token(p)
	next_token(p)

	program := make(Ast_Program, 0, 16, varena)
	defer delete(program)

	for p.cur_token.type != .EOF {
		if stmt := parse_statement(p); stmt != nil {
			append(&program, stmt)
		}
		next_token(p)
	}
	return program
}

parser_new_error :: proc(p: ^Parser, str: string, args: ..any) {
	strings.builder_reset(&p.sb)
	fmt.sbprintf(&p.sb, str, ..args)
	err := strings.to_string(p.sb)
	append(&p.errors, err)
	return
}

// Parse_Helpers=>>begin
peek_error :: proc(p: ^Parser, t: Token_Type) {
	parser_new_error(p, "expected next token: '%s', got '%s' instead.", t, p.peek_token.type)
}

no_prefix_parse_fn_error :: proc(p: ^Parser, t: Token_Type) {
	parser_new_error(p, "unexpected token '%v'", t)
}

current_token_is :: proc(p: ^Parser, t: Token_Type) -> bool {
	return p.cur_token.type == t
}

peek_token_is :: proc(p: ^Parser, t: Token_Type) -> bool {
	return p.peek_token.type == t
}

expect_peek :: proc(p: ^Parser, t: Token_Type) -> bool {
	if peek_token_is(p, t) {
		next_token(p)
		return true
	}
	peek_error(p, t)
	return false
}

next_token :: proc(p: ^Parser) {
	p.cur_token = p.peek_token
	p.peek_token = p.l->next_token()
} //end <<Parse_Helpers
// Precedence=>>begin
Precedence :: enum {
	Lowest, // 0
	Assign, // Assignment precedence
	Equals,
	Less_Greater,
	Sum,
	Product,
	Prefix,
	Call,
	Index, // 8
}

GetPrecedence: [Token_Type]Precedence
/* 
 All suitable procedures marked in this way by @(init) will then be called at the start of the program before main is called. The exact order in which all such intialization functions are called is deterministic and hence reliable. The order is determined by a topological sort of the import graph and then in alphabetical file order within the package and then top down within the file.
 */
@(init) //wonder if this does bad things.
init_precedences :: proc() {
	GetPrecedence = {
		.Plus          = .Sum,
		.Minus         = .Sum,
		.Asterisk      = .Product,
		.Slash         = .Product,
		.Less_Than     = .Less_Greater,
		.Greater_Than  = .Less_Greater,
		.Equal         = .Equals,
		.Not_Equal     = .Equals,
		.Assign        = .Assign, // Assignment has lowest precedence
		.Left_Paren    = .Call,
		.Left_Bracket  = .Index,
		// Default cases for tokens that don't have precedence
		.Illegal       = .Lowest,
		.EOF           = .Lowest,
		.Identifier    = .Lowest,
		.Int           = .Lowest,
		.String        = .Lowest,
		.Bang          = .Lowest,
		.Comma         = .Lowest,
		.Semicolon     = .Lowest,
		.Colon         = .Lowest,
		.Right_Paren   = .Lowest,
		.Left_Brace    = .Lowest,
		.Right_Brace   = .Lowest,
		.Right_Bracket = .Lowest,
		.Function      = .Lowest,
		.Let           = .Lowest,
		.True          = .Lowest,
		.False         = .Lowest,
		.If            = .Lowest,
		.Else          = .Lowest,
		.Return        = .Lowest,
		.Macro         = .Lowest,
		.For           = .Lowest,
	}
}

peek_precedence :: proc(p: ^Parser) -> Precedence {
	return GetPrecedence[p.peek_token.type]
}

cur_precedence :: proc(p: ^Parser) -> Precedence {
	return GetPrecedence[p.cur_token.type]
}
//end <<Precedence

// Expressions_types=>>begin
prefix_parse_fn :: #type proc(p: ^Parser) -> Node

infix_parse_fn :: #type proc(p: ^Parser, left: Node) -> Node

prefix_parse_fns := #partial [Token_Type]prefix_parse_fn {
	.Identifier   = parse_identifier,
	.Int          = parse_integer_literal,
	.String       = parse_string_literal,
	.Minus        = parse_prefix_expression,
	.Bang         = parse_prefix_expression,
	.Left_Paren   = parse_grouped_expression,
	.Left_Bracket = parse_array_literal,
	.Left_Brace   = parse_hash_table_literal,
	.Function     = parse_function_literal,
	.True         = parse_boolean_literal,
	.False        = parse_boolean_literal,
	.If           = parse_if_expression,
	.Macro        = parse_macro_expression,
	.For          = parse_for_expression,
}

infix_parse_fns := #partial [Token_Type]infix_parse_fn {
	.Plus         = parse_infix_expression,
	.Minus        = parse_infix_expression,
	.Asterisk     = parse_infix_expression,
	.Slash        = parse_infix_expression,
	.Less_Than    = parse_infix_expression,
	.Greater_Than = parse_infix_expression,
	.Equal        = parse_infix_expression,
	.Not_Equal    = parse_infix_expression,
	.Assign       = parse_infix_expression,
	.Left_Paren   = parse_call_expression,
	.Left_Bracket = parse_index_expression,
}
// end <<Expressions_types

// Literals=>>begin
parse_identifier :: proc(p: ^Parser) -> Node {
	return Ast_Identifier{string(p.cur_token.text_slice)}
}

parse_string_literal :: proc(p: ^Parser) -> Node {
	return string(p.cur_token.text_slice)
}

parse_integer_literal :: proc(p: ^Parser) -> Node {
	// trying to parse as float first.
	text := string(p.cur_token.text_slice)
	if strings.contains(text, ".") {
		value, ok := strconv.parse_f64(text)
		if !ok {
			parser_new_error(p, "could not parse %s as float", p.l.input)
			return nil
		}
		return value
	}
	value, ok := strconv.parse_int(text)
	if !ok {
		parser_new_error(p, "could not parse %s as integer", p.l.input)
		return nil
	}
	return value
}

parse_boolean_literal :: proc(p: ^Parser) -> Node {
	return current_token_is(p, .True)
}

parse_array_literal :: proc(p: ^Parser) -> Node {
	result, ok := parse_expression_list(p, .Right_Bracket)
	if !ok do return nil
	return Ast_Array(result)
}

parse_hash_table_literal :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	result := Ast_Hash_Table {
		pairs = make([dynamic]kvpair, 0, varena),
		table = make(map[string]Node, varena),
	}

	next_token(p)

	for !current_token_is(p, .Right_Brace) {
		key_expr := parse_expression(p, .Lowest)

		key_str_node, ok := key_expr.(string)
		if !ok {
			parser_new_error(
				p,
				"expected hash key to be a string literal, got '%s' instead.",
				Ast__Type__(key_expr),
			)
			return nil
		}

		key_str := key_str_node

		if !expect_peek(p, .Colon) do return nil
		next_token(p)

		value_expr := parse_expression(p, .Lowest)

		if key_str in result.table {
			parser_new_error(p, "duplicate key '%s' in hash literal", key_str)
			return nil
		}
		new_pair := kvpair {
			key   = key_expr,
			value = value_expr,
		}
		// TODO: Store stringified key in the kvpair for "foo" and foo to be different.
		// Cache identifiers as well.
		append(&result.pairs, new_pair)
		result.table[key_str] = value_expr

		if peek_token_is(p, .Comma) {
			next_token(p)
			next_token(p)
		} else {
			break
		}
	}

	if current_token_is(p, .Right_Brace) {
	} else {
		if !expect_peek(p, .Right_Brace) do return nil
	}

	return result
} // end << Literals
// Expressions=>>begin
parse_prefix_expression :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	op := string(p.cur_token.text_slice)

	next_token(p)

	operand_expr := parse_expression(p, .Prefix)
	if operand_expr == nil do return nil
	operand := new_clone(operand_expr, varena)

	return Ast_Prefix{op = op, operand = operand}
}

parse_infix_expression :: proc(p: ^Parser, left: Node) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	op := string(p.cur_token.text_slice)
	prec := cur_precedence(p)

	next_token(p)

	right := parse_expression(p, prec)
	if right == nil do return nil

	new_right := new_clone(right, varena)
	new_left := new_clone(left, varena)

	return Ast_Infix{op = op, left = new_left, right = new_right}
}

parse_grouped_expression :: proc(p: ^Parser) -> Node {
	next_token(p)
	expr := parse_expression(p, .Lowest)

	if !expect_peek(p, .Right_Paren) do return nil
	return expr
}

parse_if_expression :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	next_token(p)

	condition_expr := parse_expression(p, .Lowest)
	if condition_expr == nil do return nil

	if !expect_peek(p, .Left_Brace) do return nil

	then := parse_block_statement(p)

	orelse: Ast_Block = nil
	if peek_token_is(p, .Else) {
		next_token(p)
		if !expect_peek(p, .Left_Brace) do return nil
		orelse = parse_block_statement(p)
	}
	condition := new_clone(condition_expr, varena)

	return Ast_If{condition = condition, then = then, orelse = orelse}
}

parse_function_literal :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Left_Paren) do return nil

	parameters := parse_function_parameters(p)

	if !expect_peek(p, .Left_Brace) do return nil

	body := parse_block_statement(p)

	return Ast_Function{body = body, parameters = parameters}
}

parse_function_parameters :: proc(p: ^Parser) -> [dynamic]Ast_Identifier {
	varena := virtual.arena_allocator(p.vmem)
	identifiers := make([dynamic]Ast_Identifier, 0, 16, varena)

	if peek_token_is(p, .Right_Paren) {
		next_token(p)
		return identifiers
	}

	next_token(p)

	append(&identifiers, Ast_Identifier{value = string(p.cur_token.text_slice)})

	for peek_token_is(p, .Comma) {
		next_token(p)
		next_token(p)
		append(&identifiers, Ast_Identifier{value = string(p.cur_token.text_slice)})
	}

	if !expect_peek(p, .Right_Paren) do return nil

	return identifiers
}

parse_expression_list :: proc(p: ^Parser, end: Token_Type) -> (nodelst: [dynamic]Node, ok: bool) {
	varena := virtual.arena_allocator(p.vmem)
	args := make([dynamic]Node, 0, 16, varena)
	defer delete(args)

	if peek_token_is(p, end) {
		next_token(p)
		return args, true
	}

	next_token(p)
	arg := parse_expression(p, .Lowest)

	append(&args, arg)
	for peek_token_is(p, .Comma) {
		next_token(p)
		next_token(p)

		arg1 := parse_expression(p, .Lowest)
		if arg1 == nil do return nil, false

		append(&args, arg1)
	}

	if !expect_peek(p, end) do return nil, false

	return args, true
}

parse_call_expression :: proc(p: ^Parser, function: Node) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	arguments, ok := parse_expression_list(p, .Right_Paren)
	if !ok do return nil
	f := new_clone(function, varena)
	return Ast_Call{function = f, arguments = arguments}
}

parse_index_expression :: proc(p: ^Parser, operand: Node) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	next_token(p)
	index := parse_expression(p, .Lowest)

	if !expect_peek(p, .Right_Bracket) do return nil

	new_op := new_clone(operand, varena)
	new_index := new_clone(index, varena)

	return Ast_Index{operand = new_op, index = new_index}
}

parse_expression :: proc(p: ^Parser, prec: Precedence) -> Node {
	prefix := prefix_parse_fns[p.cur_token.type]

	if prefix == nil {
		no_prefix_parse_fn_error(p, p.cur_token.type)
		return nil
	}

	left_expr := prefix(p)

	for !peek_token_is(p, .Semicolon) && prec < peek_precedence(p) {

		infix := infix_parse_fns[p.peek_token.type]
		if infix == nil do return left_expr

		next_token(p)

		left_expr = infix(p, left_expr)
	}
	return left_expr
}
parse_macro_expression :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	if !expect_peek(p, .Left_Paren) do return nil

	parameters := parse_function_parameters(p)
	if !expect_peek(p, .Left_Brace) do return nil

	body := parse_block_statement(p)

	return Ast_Macro{parameters = parameters, body = body}
}
parse_for_expression :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	next_token(p)

	cond_expr := parse_expression(p, .Lowest)
	if cond_expr == nil do return nil

	if !expect_peek(p, .Left_Brace) do return nil
	body := parse_block_statement(p)

	condition := new_clone(cond_expr, varena)

	return Ast_For{cond = condition, body = body}
} // end <<Expressions
// Statements=>>begin
parse_let_statement :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)
	if !expect_peek(p, .Identifier) do return nil
	name := string(p.cur_token.text_slice)

	if !expect_peek(p, .Assign) do return nil
	next_token(p)

	value_expr := parse_expression(p, .Lowest)
	if value_expr == nil do return nil
	value := new_clone(value_expr, varena)

	if peek_token_is(p, .Semicolon) do next_token(p)
	return Ast_Let{name = name, value = value}
}

parse_return_statement :: proc(p: ^Parser) -> Node {
	varena := virtual.arena_allocator(p.vmem)

	next_token(p)

	return_value_expr := parse_expression(p, .Lowest)
	if return_value_expr == nil do return nil

	if peek_token_is(p, .Semicolon) do next_token(p)
	return_value := new_clone(return_value_expr, varena)

	return Ast_Ret{return_value = return_value}
}

parse_block_statement :: proc(p: ^Parser) -> Ast_Block {
	varena := virtual.arena_allocator(p.vmem)
	block := make(Ast_Block, 0, 16, varena)

	next_token(p)

	for !current_token_is(p, .Right_Brace) && !current_token_is(p, .EOF) {
		stmt := parse_statement(p)
		if stmt != nil do append(&block, stmt)
		next_token(p)
	}

	return block
}
parse_expression_statement :: proc(p: ^Parser) -> Node {
	expr := parse_expression(p, .Lowest)
	if peek_token_is(p, .Semicolon) do next_token(p)

	return expr
}
parse_statement :: proc(p: ^Parser) -> Node {
	#partial switch p.cur_token.type {
	case .Let:
		return parse_let_statement(p)
	case .Return:
		return parse_return_statement(p)
	}
	return parse_expression_statement(p)
} // end <<Statements

