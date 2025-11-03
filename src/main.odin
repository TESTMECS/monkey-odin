package monkey

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:strings"

HELPMSG :: ` Usage: monkey-odin <<repl |file <file_path>|bytes <file_path>|mexpand <file_path> |help>>
Commands:
  repl     Start the Monkey REPL.
  file     Run a << file_path >> and print the evaluation result.
	bytes    Run a << file_path >> and prettyprint bytecode.
	mexpand  Run a << file_path >> and prettyprint file with all macros expanded.
  help     Show this help message`


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

main :: proc() {
	if len(os.args) < 2 {
		fmt.println(HELPMSG)
		return
	}

	v: virtual.Arena
	err := virtual.arena_init_growing(&v)
	ensure(err == nil)
	varena := virtual.arena_allocator(&v)
	defer virtual.arena_destroy(&v)

	sb := strings.builder_make(varena)
	defer strings.builder_destroy(&sb)

	evaluator := Evaluator_New()
	defer evaluator->free()

	switch os.args[1] {
	case "repl":
		reader: bufio.Reader
		bufio.reader_init(&reader, os.stream_from_handle(os.stdin), bufio.DEFAULT_BUF_SIZE, varena)

		fmt.println("Monkey REPL. Type 'exit' to quit.")
		for {
			fmt.print(">> ")
			line, err := bufio.reader_read_string(&reader, '\n')
			if err != nil do monkey_err("Error reading input", 1, &sb)
			line = strings.trim_space(line)
			if line == "exit" do monkey_result(nil, &sb, true)

			p := Parser__New__(line)
			program := p->parse()
			defer p->free()

			if monkey_parser_has_error(p) do continue

			result, ok := evaluator.eval(&evaluator, program, varena)
			if !ok do monkey_err("Error evaluating expression", 1, &sb)
			if ok do monkey_result(result, &sb, false)
		}
	case "file":
		file_path := os.args[2]
		if !os.exists(file_path) do monkey_err("File does not exist", 1, &sb)
		dbg("file_path=%v", file_path)

		f, err := os.open(file_path, os.O_RDONLY)
		if err != nil do monkey_err("Error opening file", 1, &sb)
		defer os.close(f)

		contents, ok := os.read_entire_file_from_handle(f)
		ensure(ok)
		str_contents := strings.clone_from_bytes(contents, varena)

		// --- Skip shebang line if present ---
		if strings.starts_with(str_contents, "#!") {
			if idx := strings.index_byte(str_contents, '\n'); idx >= 0 {
				str_contents = str_contents[idx + 1:]
			} else {
				str_contents = ""
			}
		} else {
			str_contents = strings.trim_space(str_contents)
		}
		stmts := str_contents
		dbg("stmts=%v", str_contents)

		p := Parser__New__(stmts)
		defer p->free()

		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)
		// dbg("program=%v", program)

		c := Compiler__New__()
		defer c->free()
		compile_err := c->compile_program(program)
		if compile_err != "" do monkey_err("Error compiling file", 1, &sb, compile_err)

		bytecode := c->bytecode()
		// dbg("bytecode=%v", bytecode)

		vm := Vm_New(bytecode, &c.compiler_state)
		defer vm->free_vm()

		vm_err := vm->run_vm()
		if vm_err != "" do monkey_err("Error running file: <<%v>>", 1, &sb, vm_err)

		last_popped := vm->last_popped()
		monkey_result(last_popped, &sb, true)
	case "help":
		fmt.println(HELPMSG)
	}
}

