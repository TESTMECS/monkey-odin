#+feature dynamic-literals
package monkey
import "core:fmt"
import "core:strconv"
import "core:strings"
// Entry Point for the Parser
@(private = "file")
parse_program :: proc(p: ^Parser) -> Ast_Program {
	p->advance()
	p->advance()
	program := make(Ast_Program, 0, 16, p.varena)
	for p.cur_token.type != .EOF {
		if stmt := parse_statement(p); stmt != nil {
			append(&program, stmt)
		}
		p->advance()
	}
	return program
}
@(private = "file")
advance :: proc(p: ^Parser) {
	p.cur_token = p.peek_token
	p.peek_token = p.l->next_token()
}
@(private = "file")
parse_statement :: proc(p: ^Parser) -> Node {
	#partial switch p.cur_token.type {
	case .Let:
		return parse_let_statement(p)
	case .Return:
		return parse_return_statement(p)
	case .Foreach:
		return parse_foreach_statement(p)
	}
	return parse_expression_statement(p)
}
@(private = "file")
no_prefix_parse_fn_error :: proc(p: ^Parser, t: Token_Type) {
	p->parse_error("unexpected token '%v'", t)
}
@(private = "file")
current_token_is :: proc(p: ^Parser, t: Token_Type) -> bool {
	return p.cur_token.type == t
}
@(private = "file")
peek_token_is :: proc(p: ^Parser, t: Token_Type) -> bool {
	return p.peek_token.type == t
}
@(private = "file")
expect_peek :: proc(p: ^Parser, t: Token_Type) -> bool {
	if peek_token_is(p, t) {
		p->advance()
		return true
	}
	peek_error(p, t)
	return false
}
@(private = "file")
peek_precedence :: proc(p: ^Parser) -> Precedence {
	return GetPrecedence[p.peek_token.type]
}
@(private = "file")
cur_precedence :: proc(p: ^Parser) -> Precedence {
	return GetPrecedence[p.cur_token.type]
}
@(private = "file")
parse_identifier :: proc(p: ^Parser) -> Node {
	return Ast_Identifier{string(p.cur_token.text_slice)}
}
@(private = "file")
parse_string_literal :: proc(p: ^Parser) -> Node {
	return string(p.cur_token.text_slice)
}
@(private = "file")
parse_integer_literal :: proc(p: ^Parser) -> Node {
	text := string(p.cur_token.text_slice)
	if strings.contains(text, ".") {
		value, ok := strconv.parse_f64(text)
		if !ok {
			p->parse_error("could not parse %s as float", p.l.input)
			return nil
		}
		return value
	}
	value, ok := strconv.parse_int(text)
	if !ok {
		p->parse_error("could not parse %s as integer", p.l.input)
		return nil
	}
	return value
}
@(private = "file")
parse_boolean_literal :: proc(p: ^Parser) -> Node {
	return current_token_is(p, .True)
}
@(private = "file")
parse_array_literal :: proc(p: ^Parser) -> Node {
	result, ok := parse_expression_list(p, .Right_Bracket)
	if !ok do return nil
	return Ast_Array(result)
}
@(private = "file")
parse_hash_table_literal :: proc(p: ^Parser) -> Node {
	result := Ast_Hash_Table {
		pairs = make([dynamic]kvpair, 0, p.varena),
		table = make(map[string]Node, p.varena),
	}
	p->advance()
	for !current_token_is(p, .Right_Brace) {
		key_expr := parse_expression(p, .Lowest)
		key_str_node, ok := key_expr.(string)
		if !ok {
			p->parse_error(
				"expected hash key to be a string literal, got '%s' instead.",
				Ast__Type__(key_expr),
			)
			return nil
		}
		key_str := key_str_node
		if !expect_peek(p, .Colon) do return nil
		p->advance()
		value_expr := parse_expression(p, .Lowest)
		if key_str in result.table {
			p->parse_error("duplicate key '%s' in hash literal", key_str)
			return nil
		}
		new_pair := kvpair {
			key   = key_expr,
			value = value_expr,
		}
		append(&result.pairs, new_pair)
		result.table[key_str] = value_expr
		if peek_token_is(p, .Comma) {
			p->advance()
			p->advance()
		}
		 else {
			break
		}
	}
	if current_token_is(p, .Right_Brace) {
	}
	 else {
		if !expect_peek(p, .Right_Brace) do return nil
	}
	return result
}
@(private = "file")
parse_prefix_expression :: proc(p: ^Parser) -> Node {
	op := string(p.cur_token.text_slice)
	p->advance()
	operand_expr := parse_expression(p, .Prefix)
	if operand_expr == nil do return nil
	operand := new_clone(operand_expr, p.varena)
	return Ast_Prefix{op = op, operand = operand}
}
@(private = "file")
parse_infix_expression :: proc(p: ^Parser, left: Node) -> Node {
	op := string(p.cur_token.text_slice)
	prec := cur_precedence(p)
	p->advance()
	right := parse_expression(p, prec)
	if right == nil do return nil
	new_right := new_clone(right, p.varena)
	new_left := new_clone(left, p.varena)
	return Ast_Infix{op = op, left = new_left, right = new_right}
}
@(private = "file")
parse_grouped_expression :: proc(p: ^Parser) -> Node {
	p->advance()
	expr := parse_expression(p, .Lowest)
	if !expect_peek(p, .Right_Paren) do return nil
	return expr
}
@(private = "file")
parse_if_expression :: proc(p: ^Parser) -> Node {
	p->advance()
	condition_expr := parse_expression(p, .Lowest)
	if condition_expr == nil do return nil
	if !expect_peek(p, .Left_Brace) do return nil
	then := parse_block_statement(p)
	orelse: Ast_Block = nil
	if peek_token_is(p, .Else) {
		p->advance()
		if !expect_peek(p, .Left_Brace) do return nil
		orelse = parse_block_statement(p)
	}
	condition := new_clone(condition_expr, p.varena)
	return Ast_If{condition = condition, then = then, orelse = orelse}
}
@(private = "file")
parse_function_literal :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Left_Paren) do return nil
	parameters := parse_function_parameters(p)
	if !expect_peek(p, .Left_Brace) do return nil
	body := parse_block_statement(p)
	return Ast_Function{body = body, parameters = parameters}
}
@(private = "file")
parse_function_parameters :: proc(p: ^Parser) -> [dynamic]Ast_Identifier {
	identifiers := make([dynamic]Ast_Identifier, 0, 16, p.varena)
	if peek_token_is(p, .Right_Paren) {
		p->advance()
		return identifiers
	}
	p->advance()
	append(&identifiers, Ast_Identifier{value = string(p.cur_token.text_slice)})
	for peek_token_is(p, .Comma) {
		p->advance()
		p->advance()
		append(&identifiers, Ast_Identifier{value = string(p.cur_token.text_slice)})
	}
	if !expect_peek(p, .Right_Paren) do return nil
	return identifiers
}
@(private = "file")
parse_expression_list :: proc(p: ^Parser, end: Token_Type) -> (nodelst: [dynamic]Node, ok: bool) {
	args := make([dynamic]Node, 0, 16, p.varena)
	defer delete(args)
	if peek_token_is(p, end) {
		p->advance()
		return args, true
	}
	p->advance()
	arg := parse_expression(p, .Lowest)
	append(&args, arg)
	for peek_token_is(p, .Comma) {
		p->advance()
		p->advance()
		arg1 := parse_expression(p, .Lowest)
		if arg1 == nil do return nil, false
		append(&args, arg1)
	}
	if !expect_peek(p, end) do return nil, false
	return args, true
}
@(private = "file")
parse_arrow_call_expression :: proc(p: ^Parser, function: Node) -> Node { 	// TODO: fix this
	p->advance()
	expr := parse_expression(p, .Lowest)
	if expr == nil do return nil
	new_expr := new_clone(expr, p.varena)
	new_function := new_clone(function, p.varena)
	return Ast_Call{function = new_function, arguments = [dynamic]Node{new_expr^}}
}
@(private = "file")
parse_call_expression :: proc(p: ^Parser, function: Node) -> Node {
	arguments, ok := parse_expression_list(p, .Right_Paren)
	if !ok do return nil
	f := new_clone(function, p.varena)
	return Ast_Call{function = f, arguments = arguments}
}
@(private = "file")
parse_index_expression :: proc(p: ^Parser, operand: Node) -> Node {
	p->advance()
	index := parse_expression(p, .Lowest)
	if !expect_peek(p, .Right_Bracket) do return nil
	new_op := new_clone(operand, p.varena)
	new_index := new_clone(index, p.varena)
	return Ast_Index{operand = new_op, index = new_index}
}
@(private = "file")
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
		p->advance()
		left_expr = infix(p, left_expr)
	}
	return left_expr
}
@(private = "file")
parse_macro_expression :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Left_Paren) do return nil
	parameters := parse_function_parameters(p)
	if !expect_peek(p, .Left_Brace) do return nil
	body := parse_block_statement(p)
	return Ast_Macro{parameters = parameters, body = body}
}
@(private = "file")
parse_for_expression :: proc(p: ^Parser) -> Node {
	p->advance()
	cond_expr := parse_expression(p, .Lowest)
	if cond_expr == nil do return nil
	if !expect_peek(p, .Left_Brace) do return nil
	body := parse_block_statement(p)
	condition := new_clone(cond_expr, p.varena)
	return Ast_For{cond = condition, body = body}
}
@(private = "file")
parse_foreach_expression :: proc(p: ^Parser) -> Node {
	p->advance()
	if !expect_peek(p, .Identifier) do return nil
	name := string(p.cur_token.text_slice)
	if !expect_peek(p, .In) do return nil
	p->advance()
	expr := parse_expression(p, .Lowest)
	if expr == nil do return nil
	new_expr := new_clone(expr, p.varena)
	if !expect_peek(p, .Left_Brace) do return nil
	body := parse_block_statement(p)
	return Ast_Foreach{itervar = name, expr = new_expr, body = body}
}
@(private = "file")
parse_ternary_expression :: proc(p: ^Parser, left: Node) -> Node {
	p->advance()
	then_expr := parse_expression(p, .Lowest)
	if then_expr == nil do return nil
	if !expect_peek(p, .Colon) do return nil
	p->advance()
	else_expr := parse_expression(p, .Lowest)
	if else_expr == nil do return nil
	new_left := new_clone(left, p.varena)
	new_then := new_clone(then_expr, p.varena)
	new_else := new_clone(else_expr, p.varena)
	return Ast_Ternery{condition = new_left, then = new_then, orelse = new_else}
}
@(private = "file")
parse_let_statement :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Identifier) do return nil
	name := string(p.cur_token.text_slice)
	if !expect_peek(p, .Assign) do return nil
	p->advance()
	value_expr := parse_expression(p, .Lowest)
	if value_expr == nil do return nil
	value := new_clone(value_expr, p.varena)
	if peek_token_is(p, .Semicolon) do p->advance()
	return Ast_Let{name = name, value = value}
}
@(private = "file")
parse_return_statement :: proc(p: ^Parser) -> Node {
	p->advance()
	return_value_expr := parse_expression(p, .Lowest)
	if return_value_expr == nil do return nil
	if peek_token_is(p, .Semicolon) do p->advance()
	return_value := new_clone(return_value_expr, p.varena)
	return Ast_Ret{return_value = return_value}
}
@(private = "file")
parse_block_statement :: proc(p: ^Parser) -> Ast_Block {
	block := make(Ast_Block, 0, 16, p.varena)
	p->advance()
	for !current_token_is(p, .Right_Brace) && !current_token_is(p, .EOF) {
		stmt := parse_statement(p)
		if stmt != nil do append(&block, stmt)
		p->advance()
	}
	return block
}
@(private = "file")
parse_foreach_statement :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Identifier) do return nil
	itervar := string(p.cur_token.text_slice)
	if !expect_peek(p, .In) do return nil
	p->advance()
	expr := parse_expression(p, .Lowest)
	if expr == nil do return nil
	new_expr := new_clone(expr, p.varena)
	if !expect_peek(p, .Left_Brace) do return nil
	body := parse_block_statement(p)
	if peek_token_is(p, .Semicolon) do p->advance()
	return Ast_Foreach{itervar = itervar, expr = new_expr, body = body}
}
@(private = "file")
parse_expression_statement :: proc(p: ^Parser) -> Node {
	expr := parse_expression(p, .Lowest)
	if peek_token_is(p, .Semicolon) do p->advance()
	return expr
}
@(private = "file")
parser_new_error :: proc(p: ^Parser, str: string, args: ..any) {
	strings.builder_reset(&p.sb)
	fmt.sbprintf(&p.sb, str, ..args)
	err := strings.to_string(p.sb)
	append(&p.errors, err)
	return
}
@(private = "file")
peek_error :: proc(p: ^Parser, t: Token_Type) {
	p->parse_error("expected next token: '%s', got '%s' instead.", t, p.peek_token.type)
}
prefix_parse_fn :: #type proc(p: ^Parser) -> Node
infix_parse_fn :: #type proc(p: ^Parser, left: Node) -> Node
@(rodata)
prefix_parse_fns := #partial [Token_Type]prefix_parse_fn {
	.Identifier   = parse_identifier,
	.Int          = parse_integer_literal,
	.String       = parse_string_literal,
	.Minus        = parse_prefix_expression,
	.Bang         = parse_prefix_expression,
	.Tilde        = parse_prefix_expression,
	.Left_Paren   = parse_grouped_expression,
	.Left_Bracket = parse_array_literal,
	.Left_Brace   = parse_hash_table_literal,
	.Function     = parse_function_literal,
	.True         = parse_boolean_literal,
	.False        = parse_boolean_literal,
	.If           = parse_if_expression,
	.Macro        = parse_macro_expression,
	.For          = parse_for_expression,
	.Foreach      = parse_foreach_expression,
}
@(rodata)
infix_parse_fns := #partial [Token_Type]infix_parse_fn {
	.Plus               = parse_infix_expression,
	.Minus              = parse_infix_expression,
	.Asterisk           = parse_infix_expression,
	.Slash              = parse_infix_expression,
	.Percent            = parse_infix_expression,
	.Pipe               = parse_infix_expression,
	.RShift             = parse_infix_expression,
	.LShift             = parse_infix_expression,
	.Ampersand          = parse_infix_expression,
	.Caret              = parse_infix_expression,
	.Lor                = parse_infix_expression,
	.Land               = parse_infix_expression,
	.Less_Than          = parse_infix_expression,
	.Greater_Than       = parse_infix_expression,
	.Greater_Than_Equal = parse_infix_expression,
	.Less_Than_Equal    = parse_infix_expression,
	.Equal              = parse_infix_expression,
	.Not_Equal          = parse_infix_expression,
	.Assign             = parse_infix_expression,
	.Left_Paren         = parse_call_expression,
	.Arrow              = parse_arrow_call_expression,
	.Left_Bracket       = parse_index_expression,
	.Question_Mark      = parse_ternary_expression,
}
@(rodata)
PARSERVTABLE := Parser_VTable {
	parse       = parse_program,
	advance     = advance,
	parse_error = parser_new_error,
}

