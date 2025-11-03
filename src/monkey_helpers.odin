package monkey

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "core:terminal/ansi"

monkey_parser_has_error :: proc(p: Parser) -> bool {
	if len(p.errors) == 0 do return false
	log.errorf("parser has %d errors", len(p.errors))
	for msg, _ in p.errors do log.errorf("parser error: %q", msg)
	return true
}

monkey_err :: proc(msg: string, status: int, sb: ^strings.Builder, xtra: ..any) {
	strings.builder_reset(sb)
	fmt.sbprintf(sb, msg)
	if xtra != nil do fmt.sbprintln(sb, ..xtra)
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

monkey_print_help :: proc(sb: ^strings.Builder) {
	strings.builder_reset(sb)
	green_greeting :=
		ansi.CSI + ansi.FG_GREEN + ansi.SGR + HELPMSG + ansi.CSI + ansi.RESET + ansi.SGR
	fmt.sbprintfln(sb, green_greeting)
	fmt.println(strings.to_string(sb^))
}

dbg :: proc(fstring: string, args: ..any) {
	fmt.printfln(fstring, ..args)
}

