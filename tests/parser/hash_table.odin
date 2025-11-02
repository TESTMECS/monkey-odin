#+feature dynamic-literals
package parser_tests

import m "../.."
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"

@(test)
test_hash_table :: proc(t: ^testing.T) {
	input := `{"one": 1, "two": 2, "three": 3};`

	p := m.Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	stmt, ok := program[0].(m.Ast_Hash_Table)
	if !ok {
		log.errorf("program[0] is not Ast_Hash_Table, got='%v'", m.Ast__Type__(program[0]))
		return
	} else if len(stmt.table) != 3 {
		log.errorf("length of the hash table is not 3, got'%d'", len(stmt.table))
		return
	}

	expected := map[string]int {
		"one"   = 1,
		"two"   = 2,
		"three" = 3,
	}
	defer delete(expected)

	for key, ev in expected {
		value, key_exists := stmt.table[key]
		if !key_exists {
			log.errorf("key '%s' does not exist in the hash table", key)
			continue
		}
		literal_value_is_valid(&value, ev)
	}

}

