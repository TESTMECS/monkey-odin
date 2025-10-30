#+feature dynamic-literals
/*%desc{
{"Parser for the Monkey Language"}}
*/
package monkey
import "core:fmt"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:testing"
//%type{Parser::struct}
Parser :: struct {
	//%desc{{"reading"}}
	l:          Lexer,
	cur_token:  Token,
	peek_token: Token,
	//%desc{{"method"}}
	parse:      proc(p: ^Parser) -> Ast_Program,
	//%desc{{"mem managed"}}
	errors:     [dynamic]string,
	free:       proc(p: ^Parser),
}
//%desc{{"Creates a new Lexer"}}
Parser_New :: proc(input: string) -> Parser {
	p := Parser {
		l     = Lexer_New(input),
		parse = Parse_Program,
		free  = Parser_Free,
	}
	return p
}
//%desc{{"clears %Parser::errors::[dyn]string"}}
Parser_Free :: proc(p: ^Parser) {
	delete(p.errors)
	p.errors = {}
}
//%section::Precedence
//%desc{{"Lowest is 0, max is ab 6-7"}}
@(private = "file")
Precedence :: enum {
	Lowest,
	Equals,
	Less_Greater,
	Sum,
	Product,
	Prefix,
	Call,
	Index,
}
//%type{map::Token_Type,Precedence::}
@(rodata)
@(private = "file")
GetPrecedence := #partial [Token_Type]Precedence {
	.Plus         = .Sum,
	.Minus        = .Sum,
	.Asterisk     = .Product,
	.Slash        = .Product,
	.Less_Than    = .Less_Greater,
	.Greater_Than = .Less_Greater,
	.Equal        = .Equals,
	.Not_Equal    = .Equals,
	.Left_Paren   = .Call,
	.Left_Bracket = .Index,
}
//%desc{{"peek_precedence returns the %Precedence::enum for the %Parser::peek_token::Token."}}
@(private = "file")
peek_precedence :: proc(p: ^Parser) -> Precedence {
	return GetPrecedence[p.peek_token.type]
}
// cur_precedence return the %Precedence::enum for %Parser::cur_token::Token.
@(private = "file")
cur_precedence :: proc(p: ^Parser) -> Precedence {
	return GetPrecedence[p.cur_token.type]
}
//%endsection
//%type{proc(p:%Parser)}
@(private = "file")
prefix_parse_fn :: #type proc(p: ^Parser) -> Node
//%type{proc(p:%Parser,left:%Node)}
@(private = "file")
infix_parse_fn :: #type proc(p: ^Parser, left: Node) -> Node
//%type{map[%Token_Type]%prefix_parse_fn::proc::(%Parser)::%Node}
@(private = "file")
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
}
//%type{%map[%Token_Type]%infix_parse_fn::proc::(%Parser, %Node)::%Node}
@(private = "file")
infix_parse_fns := #partial [Token_Type]infix_parse_fn {
	.Plus         = parse_infix_expression,
	.Minus        = parse_infix_expression,
	.Asterisk     = parse_infix_expression,
	.Slash        = parse_infix_expression,
	.Less_Than    = parse_infix_expression,
	.Greater_Than = parse_infix_expression,
	.Equal        = parse_infix_expression,
	.Not_Equal    = parse_infix_expression,
	.Left_Paren   = parse_call_expression,
	.Left_Bracket = parse_index_expression,
}
//%type{%proc::%Parser::%Token_Type::bool}
current_token_is :: proc(p: ^Parser, t: Token_Type) -> bool {
	return p.cur_token.type == t
}
//%section peek
//%patttern{proc(%Parser, %Token_Type)}
@(private = "file")
peek_error :: proc(p: ^Parser, t: Token_Type) {
	msg := strings.builder_make(context.allocator)
	defer strings.builder_destroy(&msg)
	fmt.sbprintf(&msg, "expected next token: '%s', got '%s' instead.", t, p.peek_token.type)
	append(&p.errors, strings.to_string(msg))
}
@(private = "file")
peek_token_is :: proc(p: ^Parser, t: Token_Type) -> bool {
	return p.peek_token.type == t
}
@(private = "file")
expect_peek :: proc(p: ^Parser, t: Token_Type) -> bool {
	if peek_token_is(p, t) {
		next_token(p)
		return true
	}
	peek_error(p, t)
	return false
}
//%endsection
//%desc{{"Modifies %Parser::cur_token::Token and %Parser::peek_token::Token"}}
//%type{proc()->{%Parser::l::Lexer, %next_token{proc(p:%Parser)->{@self}}}
@(private = "file")
next_token :: proc(p: ^Parser) {
	p.cur_token = p.peek_token
	p.peek_token = p.l->next_token()
}
/*%section Parse
	%pattern{
		"test"::proc();
		"testee"::proc(%Parser)::%Node 
	}
*/
//%section parse identifier
@(test)
test_parse_identifier :: proc(t: ^testing.T) {
	input := "foobar;"
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 1 {
		log.errorf("Program does not contain at least 1 statement, got'%v'", len(program))
		return
	}
	identifier_is_valid(&program[0], "foobar")
}
@(private = "file")
parse_identifier :: proc(p: ^Parser) -> Node {
	return Ast_Identifier{string(p.cur_token.text_slice)}
}
//%endsection
//%section string literal
@(test)
test_parse_string_literal :: proc(t: ^testing.T) {
	input := `"hello world";`
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}
	literal, str_ok := program[0].(string)
	if !str_ok {
		log.errorf("expression is not string, got='%v'", ast_type(program[0]))
		return
	}
	if literal != "hello world" {
		log.errorf("string is not 'hello world', got='%s'", literal)
	}
}
@(private = "file")
parse_string_literal :: proc(p: ^Parser) -> Node {
	return string(p.cur_token.text_slice)
}
//%endsection
//%section integer literal
@(test)
test_integer_literal :: proc(t: ^testing.T) {
	input := "5;"
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}
	literal_value_is_valid(&program[0], 5)
}
@(private = "file")
parse_integer_literal :: proc(p: ^Parser) -> Node {
	value, ok := strconv.parse_int(string(p.cur_token.text_slice))
	if !ok {
		msg := strings.builder_make(context.allocator)
		defer strings.builder_destroy(&msg)
		fmt.sbprintf(&msg, "could not parse %s as integer", p.l.input)
		append(&p.errors, strings.to_string(msg))
		return nil
	}
	return value
}
//%endsection
//%section boolean
@(test)
test_boolean :: proc(t: ^testing.T) {
	input := "true;"
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}
	literal_value_is_valid(&program[0], true)
}
@(private = "file")
parse_boolean_literal :: proc(p: ^Parser) -> Node {
	return current_token_is(p, .True)
}
//%endsection
//%section array
@(test)
test_array :: proc(t: ^testing.T) {
	input := "[1,2*2,3+3]"
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}
	stmt, ok := program[0].(Ast_Array) // check array
	if !ok {
		log.errorf("program[0] is not Ast_Array, got='%v'", ast_type(program[0]))
		return
	}
	if len(stmt) != 3 {
		log.errorf("length of the array is not 3, got='%d'", len(stmt))
		return
	}
	literal_value_is_valid(&stmt[0], 1)
	infix_expression_is_valid(&stmt[1], 2, "*", 2)
	infix_expression_is_valid(&stmt[2], 3, "+", 3)
}
@(private = "file")
parse_array_literal :: proc(p: ^Parser) -> Node {
	result, ok := parse_expression_list(p, .Right_Bracket)
	if !ok do return nil
	return Ast_Array(result)
}
//%endsection
//%section hash table
@(test)
test_hash_table :: proc(t: ^testing.T) {
	input := `{"one": 1, "two": 2, "three": 3}`
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}
	stmt, ok := program[0].(Ast_Hash_Table)
	if !ok {
		log.errorf("program[0] is not Ast_Hash_Table, got='%v'", ast_type(program[0]))
		return
	}
	if len(stmt) != 3 {
		log.errorf("length of the hash table is not 3, got'%d'", len(stmt))
		return
	}
	expected := map[string]int {
		"one"   = 1,
		"two"   = 2,
		"three" = 3,
	}
	defer delete(expected)
	for key, ev in expected {
		value, key_exists := stmt[key]
		if !key_exists {
			log.errorf("key '%s' does not exist in the hash table", key)
			continue
		}
		literal_value_is_valid(&value, ev)
	}
}
@(private = "file")
parse_hash_table_literal :: proc(p: ^Parser) -> Node {
	result := make(Ast_Hash_Table, context.allocator)
	defer delete(result)
	for !peek_token_is(p, .Right_Brace) {
		next_token(p)
		key_expr := parse_expression(p, .Lowest)
		key, ok := key_expr.(string)
		if !ok {
			msg := strings.builder_make(context.allocator)
			defer strings.builder_destroy(&msg)
			fmt.sbprintf(&msg, "expected key to be 'string', got '%s' instead.", ast_type(key_expr))
			append(&p.errors, strings.to_string(msg))
			return nil
		}
		if !expect_peek(p, .Colon) do return nil
		next_token(p)
		value := parse_expression(p, .Lowest)
		result[key] = value
		if !peek_token_is(p, .Right_Brace) && !expect_peek(p, .Comma) do return nil
	}
	if !expect_peek(p, .Right_Brace) do return nil
	return result
}
//%endsection
//%section let
@(test)
test_let_statement :: proc(t: ^testing.T) {
	input := `
	let x = 5;
	let y = true;
	let foobar = y;
	`


	tests := [?]struct {
		expected_identifier: string,
		expected_value:      Literal,
	}{{"x", 5}, {"y", true}, {"foobar", "y"}}
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 3 {
		log.errorf("program does not contain 3 statements, got='%v'", len(program))
		return
	}
	for test_case, i in tests {
		if !stmt_is_let(program[i], test_case.expected_identifier, test_case.expected_value) {
			log.errorf("test [%d] has failed", i)
		}
	}
}
@(private = "file")
parse_let_statement :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Identifier) do return nil
	name := string(p.cur_token.text_slice)
	if !expect_peek(p, .Assign) do return nil
	next_token(p)
	value := parse_expression(p, .Lowest)
	if value == nil do return nil
	if peek_token_is(p, .Semicolon) do next_token(p)
	return Ast_Let{name = name, value = new_clone(value, context.allocator)} 
}
//%endsection
//%section return
@(test)
test_parsing_return_statement :: proc(t: ^testing.T) {
	input := `
	return 5;
	return 10;
	return 100;
	`


	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return
	if len(program) != 3 {
		log.errorf("program does not contain 3 statements, got='%v'", len(program))
		return
	}
	tests := [?]struct {
		expected_identifier: string,
	}{{"x"}, {"y"}, {"foobar"}}
	for _, i in tests {
		stmt := program[i]
		_, ok := stmt.(Ast_Ret)
		if !ok {
			log.errorf("test [%d]: stmt is not a return statement. got='%v'", i, ast_type(stmt))
		}
	}
}
@(private = "file")
parse_return_statement :: proc(p: ^Parser) -> Node {
	next_token(p)
	return_value := parse_expression(p, .Lowest)
	if return_value == nil do return nil
	if peek_token_is(p, .Semicolon) do next_token(p)
	return Ast_Ret{return_value = new_clone(return_value, context.allocator)}
}
//%endsection
//%section prefix
@(test)
test_prefix_expression :: proc(t: ^testing.T) {
	prefix_tests := [?]struct {
		input:         string,
		operator:      string,
		operand_value: Literal,
	}{{"!5;", "!", 5}, {"-15;", "-", 15}, {"!true;", "!", true}, {"!false;", "!", false}}
	defer free_all(context.allocator)
	for test_case, i in prefix_tests {
		if !prefix_test_case_is_ok(
			i,
			test_case.input,
			test_case.operator,
			test_case.operand_value,
		) {
			log.errorf("Test [%d] has failed", i)
		}
	}
}
@(private = "file")
parse_prefix_expression :: proc(p: ^Parser) -> Node {
	op := string(p.cur_token.text_slice)
	next_token(p)
	operand := parse_expression(p, .Prefix)
	if operand == nil do return nil
	return Ast_Prefix{op = op, operand = new_clone(operand, context.allocator)}
}
//%endsection
//%section infix
@(test)
test_parsing_infix :: proc(t: ^testing.T) {
	tests := []struct {
		input:       string,
		left_value:  Literal,
		operator:    string,
		right_value: Literal,
	} {
		{"5 + 5;", 5, "+", 5},
		{"5 - 5;", 5, "-", 5},
		{"5 * 5;", 5, "*", 5},
		{"5 / 5;", 5, "/", 5},
		{"5 > 5;", 5, ">", 5},
		{"5 < 5;", 5, "<", 5},
		{"5 == 5;", 5, "==", 5},
		{"5 != 5;", 5, "!=", 5},
		{"true == true", true, "==", true},
		{"true != false", true, "!=", false},
		{"false == false", false, "==", false},
	}
	defer free_all(context.allocator)
	for test_case, i in tests {
		if !infix_test_case_is_valid(
			test_case.input,
			test_case.left_value,
			test_case.operator,
			test_case.right_value,
		) {
			log.errorf("Test [%d] has failed", i)
		}
	}
}
@(private = "file")
parse_infix_expression :: proc(p: ^Parser, left: Node) -> Node {
	op := string(p.cur_token.text_slice)
	prec := cur_precedence(p)
	next_token(p)
	right := parse_expression(p, prec)
	if right == nil do return nil
	return Ast_Infix {
		op = op,
		left = new_clone(left, context.allocator),
		right = new_clone(right, context.allocator), 
	}
}
//%endsection
//%section grouped
@(private = "file")
parse_grouped_expression :: proc(p: ^Parser) -> Node {
	next_token(p)
	expr := parse_expression(p, .Lowest)
	if !expect_peek(p, .Right_Paren) do return nil
	return expr
}
//%endsection
//%section block
@(private = "file")
parse_block_statement :: proc(p: ^Parser) -> Ast_Block {
	block := make(Ast_Block, 0, 16, context.allocator)
	defer delete(block)
	next_token(p)
	for !current_token_is(p, .Right_Brace) && !current_token_is(p, .EOF) {
		stmt := parse_statement(p)
		if stmt != nil do append(&block, stmt)
		next_token(p)
	}
	return block
}
//%endsection
//%section if expression
@(private = "file")
parse_if_expression :: proc(p: ^Parser) -> Node {
	next_token(p)

	condition := parse_expression(p, .Lowest)
	if condition == nil do return nil

	if !expect_peek(p, .Left_Brace) do return nil

	then := parse_block_statement(p)

	orelse: Ast_Block = nil
	if peek_token_is(p, .Else) {
		next_token(p)
		if !expect_peek(p, .Left_Brace) do return nil
		orelse = parse_block_statement(p)
	}

	return Ast_If{condition = &condition, then = then, orelse = orelse}
}
//%endsection
//%section functions
@(private = "file")
parse_function_parameters :: proc(p: ^Parser) -> [dynamic]Ast_Identifier {
	identifiers := make([dynamic]Ast_Identifier, 0, 16, context.allocator)
	defer delete(identifiers)

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
@(private = "file")
parse_function_literal :: proc(p: ^Parser) -> Node {
	if !expect_peek(p, .Left_Paren) do return nil

	parameters := parse_function_parameters(p)

	if !expect_peek(p, .Left_Brace) do return nil

	body := parse_block_statement(p)

	return Ast_Function{body = body, parameters = parameters}
}
//%endsection
//%section expression
@(private = "file")
parse_expression_list :: proc(p: ^Parser, end: Token_Type) -> (nodelst: [dynamic]Node, ok: bool) {
	//%memerr
	args := make([dynamic]Node, 0, 16, context.allocator)
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
@(private = "file")
parse_call_expression :: proc(p: ^Parser, function: Node) -> Node {
	arguments, ok := parse_expression_list(p, .Right_Paren)
	if !ok do return nil
	f := new_clone(function, context.allocator)
	return Ast_Call{function = f, arguments = arguments}
}

@(private = "file")
parse_index_expression :: proc(p: ^Parser, operand: Node) -> Node {
	next_token(p)
	index := parse_expression(p, .Lowest)

	if !expect_peek(p, .Right_Bracket) do return nil

	o := new_clone(operand, context.allocator)
	return Ast_Index {
		operand = o,
		index = &index,
	}
}
@(private = "file")
no_prefix_parse_fn_error :: proc(p: ^Parser, t: Token_Type) {
	msg := strings.builder_make(context.allocator)
	defer strings.builder_destroy(&msg)
	fmt.sbprintf(&msg, "unexpected token '%v'", t)
	append(&p.errors, strings.to_string(msg))
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

		next_token(p)

		left_expr = infix(p, left_expr)
	}

	return left_expr
}
@(private = "file")
parse_expression_statement :: proc(p: ^Parser) -> Node {
	expr := parse_expression(p, .Lowest)
	if peek_token_is(p, .Semicolon) do next_token(p)
	return expr
}
//%endsection
//%section statement
@(private = "file")
parse_statement :: proc(p: ^Parser) -> Node {
	#partial switch p.cur_token.type {
	case .Let:
		return parse_let_statement(p)
	case .Return:
		return parse_return_statement(p)
	}
	return parse_expression_statement(p)
}
//%desc{{"calls init on the lexer with the input."}}
@(private = "file")
Parse_Program :: proc(p: ^Parser) -> Ast_Program {
	next_token(p)
	next_token(p)

	//%mem_alloc
	program := make(Ast_Program, 0, 16, context.allocator)
	defer delete(program)

	for p.cur_token.type != .EOF {
		if stmt := parse_statement(p); stmt != nil {
			append(&program, stmt)
		}
		next_token(p)
	}
	return program
}
//%endsection
//%endsection
//%section Test Helper functions
parser_has_error :: proc(p: Parser) -> bool {
	if len(p.errors) == 0 do return false

	log.errorf("parser has %d errors", len(p.errors))
	for msg, _ in p.errors {
		log.errorf("parser error: %q", msg)
	}

	return true
}

//%section literals are valid
Literal :: union {
	int,
	string,
	bool,
}
integer_literal_is_valid :: proc(il: ^Node, expected_value: int) -> bool {
	val, ok := il.(int)
	if !ok {
		log.errorf("il is not 'int', got='%v'", ast_type(il))
		return false
	}
	if val != expected_value {
		log.errorf("value is not '%d', got='%d'", expected_value, val)
		return false
	}
	return true
}
identifier_is_valid :: proc(expr: ^Node, expected_value: string) -> bool {
	ident, ok := expr.(Ast_Identifier)
	if !ok {
		log.errorf("expression is not Ast_Identifier, got='%v'", ast_type(expr))
		return false
	}

	if ident.value != expected_value {
		log.errorf("ident.value is not '%s', got='%s'", expected_value, ident.value)
		return false
	}

	return true
}
boolean_is_valid :: proc(b: ^Node, expected_value: bool) -> bool {
	blit, ok := b.(bool)
	if !ok {
		log.errorf("expression is not boolean, got='%v'", ast_type(b))
		return false
	}
	if blit != expected_value {
		log.errorf("blit is not '%v', got='%v'", expected_value, blit)
		return false
	}
	return true
}
literal_value_is_valid :: proc(lit: ^Node, expected: Literal) -> bool {
	switch v in expected {
	case int:
		return integer_literal_is_valid(lit, v)

	case string:
		return identifier_is_valid(lit, v)

	case bool:
		return boolean_is_valid(lit, v)
	}

	unreachable()
}
//%section expression is valid
infix_expression_is_valid :: proc(
	expression: ^Node,
	left_value: Literal,
	operator: string,
	right_value: Literal,
) -> bool {
	infix, ok := expression.(Ast_Infix)
	if !ok {
		log.errorf("expression is not 'Ast_Infix', got'%v'", ast_type(expression))
		return false
	}

	if infix.op != operator {
		log.errorf("wrong infix operator expected='%s', got='%s'", operator, infix.op)
		return false
	}

	if !literal_value_is_valid(infix.left, left_value) {
		log.errorf("test's left value has failed")
		return false
	}

	if !literal_value_is_valid(infix.right, right_value) {
		log.errorf("test's right value has failed")
		return false
	}
	return true
}
//%endsection
//%section statement
stmt_is_let :: proc(s: Node, name: string, expected_value: Literal) -> bool {
	let_stmt, ok := s.(Ast_Let) // check let
	if !ok {
		log.errorf("s is not a let statement. got='%v'", ast_type(s))
		return false
	}
	if let_stmt.name != name {
		log.errorf("let_stmt.name is not '%s', got='%s'", name, let_stmt.name)
		return false
	}
	return literal_value_is_valid(let_stmt.value, expected_value)
}
prefix_test_case_is_ok :: proc(
	test_number: int,
	input: string,
	operator: string,
	operand_value: Literal,
) -> bool {
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return false
	if len(program) != 1 {
		log.errorf(
			"test [%d]: program does not contain 1 statement, got='%v'",
			test_number,
			len(program),
		)
		return false
	}
	infix, ok := program[0].(Ast_Prefix) // check infix
	if !ok {
		log.errorf(
			"test [%d]: program[0] is not 'Node_Prefix_Expression', got='%v'",
			test_number,
			ast_type(program[0]),
		)
		return false
	}
	if infix.op != operator {
		log.errorf(
			"test [%d]: wrong infix operator expected='%s', got='%s'",
			test_number,
			operator,
			infix.op,
		)
		return false
	}
	if !literal_value_is_valid(infix.operand, operand_value) {
		log.errorf("test [%d]'s operand value has failed", test_number)
		return false
	}
	return true
}
infix_test_case_is_valid :: proc(
	input: string,
	left_value: Literal,
	operator: string,
	right_value: Literal,
) -> bool {
	p := Parser_New(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return false
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return false
	}
	return infix_expression_is_valid(&program[0], left_value, operator, right_value)
}
//%endsection
//%endsection test helper functions
