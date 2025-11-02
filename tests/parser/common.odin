package tests

import m "../.."
import "core:log"

Literal :: union {
	int,
	string,
	bool,
}

parser_has_error :: m.parser_has_error 

integer_literal_is_valid :: proc(il: ^m.Node, expected_value: int) -> bool {
	val, ok := il.(int)
	if !ok {
		log.errorf("il is not 'int', got='%v'", m.ast_type(il))
		return false
	}
	if val != expected_value {
		log.errorf("value is not '%d', got='%d'", expected_value, val)
		return false
	}
	return true
}

identifier_is_valid :: proc(expr: ^m.Node, expected_value: string) -> bool {
	ident, ok := expr.(m.Ast_Identifier)
	if !ok {
		log.errorf("expression is not Ast_Identifier, got='%v'", m.ast_type(expr))
		return false
	}

	if ident.value != expected_value {
		log.errorf("ident.value is not '%s', got='%s'", expected_value, ident.value)
		return false
	}

	return true
}

boolean_is_valid :: proc(b: ^m.Node, expected_value: bool) -> bool {
	blit, ok := b.(bool)
	if !ok {
		log.errorf("expression is not boolean, got='%v'", m.ast_type(b))
		return false
	}
	if blit != expected_value {
		log.errorf("blit is not '%v', got='%v'", expected_value, blit)
		return false
	}
	return true
}

literal_value_is_valid :: proc(lit: ^m.Node, expected: Literal) -> bool {
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

infix_expression_is_valid :: proc(
	expression: ^m.Node,
	left_value: Literal,
	operator: string,
	right_value: Literal,
) -> bool {
	infix, ok := expression.(m.Ast_Infix)
	if !ok {
		log.errorf("expression is not 'Ast_Infix', got'%v'", m.ast_type(expression))
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

stmt_is_let :: proc(s: m.Node, name: string, expected_value: Literal) -> bool {
	let_stmt, ok := s.(m.Ast_Let)
	if !ok {
		log.errorf("s is not a let statement. got='%v'", m.ast_type(s))
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
	p := m.Parser__New__(input)
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

	infix, ok := program[0].(m.Ast_Prefix) // check infix
	if !ok {
		log.errorf(
			"test [%d]: program[0] is not 'Node_Prefix_Expression', got='%v'",
			test_number,
			m.ast_type(program[0]),
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
	p := m.Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return false
	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return false
	}

	return infix_expression_is_valid(&program[0], left_value, operator, right_value)
}
