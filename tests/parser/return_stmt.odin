package tests
import m "../.."
import "core:testing"
import "core:log"

@(test)
test_parsing_return_statement :: proc(t: ^testing.T) {
	input := `
	return 5;
	return 10;
	return 100;
	`

	p := m.Parser__New__(input)
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
		_, ok := stmt.(m.Ast_Ret)
		if !ok {
			log.errorf("test [%d]: stmt is not a return statement. got='%v'", i, m.ast_type(stmt))
		}
	}
}
