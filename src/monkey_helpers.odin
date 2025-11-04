package monkey

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:terminal/ansi"


Monkey_Run_String :: proc(stmts: string, sb: ^strings.Builder, exit: bool, varena: mem.Allocator) {
	// string -> ast -> compiler -> bytecode -> vm -> checks last popped object.
	p := Parser_New(stmts, varena)

	program := p->parse()
	if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, sb)

	c := Compiler__New__()
	defer c->free()
	compile_err := c->compile_program(program)
	if compile_err != "" do monkey_err("Error compiling file", 1, sb, compile_err)

	bytecode := c->bytecode()

	vm := Vm_New(bytecode, &c.compiler_state)
	defer vm->free_vm()

	vm_err := vm->run_vm()
	if vm_err != "" do monkey_err("Error running file: <<%v>>", 1, sb, vm_err)

	last_popped := vm->last_popped()
	monkey_result(last_popped, sb, exit) // true for file, false for repl.
}

Monkey_Read_File :: proc(
	file_path: string,
	sb: ^strings.Builder,
	allocator: mem.Allocator,
) -> (
	stmts: string,
) {
	// Read file path and return its string contents.
	if !os.exists(file_path) do monkey_err("File does not exist", 1, sb)

	f, err := os.open(file_path, os.O_RDONLY)
	if err != nil do monkey_err("Error opening file", 1, sb)
	defer os.close(f)

	contents, ok := os.read_entire_file_from_handle(f)
	ensure(ok)
	str_contents := strings.clone_from_bytes(contents, allocator)

	if strings.starts_with(str_contents, "#!") {
		if idx := strings.index_byte(str_contents, '\n'); idx >= 0 {
			str_contents = str_contents[idx + 1:]
		} else {
			str_contents = ""
		}
	} else {
		str_contents = strings.trim_space(str_contents)
	}
	return str_contents
}

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

