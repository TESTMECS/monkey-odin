package test_commons
import monkey "../src"
import "core:log"
parser_has_error :: proc(p: monkey.Parser) -> bool {
	if len(p.errors) == 0 do return false
	log.errorf("parser has %d errors", len(p.errors))
	for msg, _ in p.errors do log.errorf("parser error: %q", msg)
	return true
}

