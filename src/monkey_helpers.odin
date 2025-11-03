package monkey

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

monkey_parser_has_error :: proc(p: Parser) -> bool {
	if len(p.errors) == 0 do return false
	log.errorf("parser has %d errors", len(p.errors))
	for msg, _ in p.errors do log.errorf("parser error: %q", msg)
	return true
}

monkey_err :: proc(msg: string, status: int, sb: ^strings.Builder, xtra: ..any) {
	strings.builder_reset(sb)
	fmt.sbprintf(sb, msg, ..xtra)
	err_msg := strings.to_string(sb^)
	fmt.println(err_msg)
	os.exit(status)
}

monkey_result :: proc(return_object: Object, sb: ^strings.Builder, exit: bool, xtra: ..any) {
	strings.builder_reset(sb)

	fmt.sbprintf(sb, "=>>")
	if xtra != nil do fmt.sbprintln(sb, ..xtra)

	obj := Object(return_object)
	ObjectInspect(obj, sb)

	fmt.println(strings.to_string(sb^))
	if exit do os.exit(0)

	return
}

dbg :: proc(fstring: string, args: ..any) {
	fmt.printfln(fstring, ..args)
}

