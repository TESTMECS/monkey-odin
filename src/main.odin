package monkey

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:terminal/ansi"

HELPMSG :: ` Usage: monkey-odin << repl |file <file_path>|bytes <file_path>|mexpand <file_path> |help >>
Commands:
  repl     Start the Monkey REPL.
  file     Run a << file_path >> and print the evaluation result.
	bytes    Run a << file_path >> and prettyprint bytecode.
	mexpand  Run a << file_path >> and prettyprint file with all macros expanded.
  help     Show this help message`


main :: proc() {
	v: virtual.Arena
	err := virtual.arena_init_growing(&v)
	ensure(err == nil)
	varena := virtual.arena_allocator(&v)
	defer virtual.arena_destroy(&v)

	sb := strings.builder_make(varena)
	defer strings.builder_destroy(&sb)

	if len(os.args) < 2 {
		monkey_print_help(&sb)
		err_msg :=
			ansi.CSI +
			ansi.FG_RED +
			ansi.SGR +
			"No Command Specified" +
			ansi.CSI +
			ansi.RESET +
			ansi.SGR
		monkey_err(err_msg, 1, &sb)
	}

	switch os.args[1] {
	case "repl":
		reader: bufio.Reader
		bufio.reader_init(&reader, os.stream_from_handle(os.stdin), bufio.DEFAULT_BUF_SIZE, varena)

		fmt.println(
			ansi.CSI + ansi.FG_BRIGHT_GREEN + ansi.SGR + "Monkey REPL. Type 'exit' to quit.",
			ansi.CSI + ansi.RESET + ansi.SGR,
		)
		for { 	//repl=>>begin
			fmt.print(">> ")
			// readline
			line, err := bufio.reader_read_string(&reader, '\n')
			if err != nil do monkey_err("Error reading input", 1, &sb)
			line = strings.trim_space(line)

			if line == "exit" do monkey_result(nil, &sb, true) // exit
			Monkey_Run_String(line, &sb, false)
		} //<<repl
	case "file":
		file_path := os.args[2]
		if !os.exists(file_path) do monkey_err("File does not exist", 1, &sb)

		f, err := os.open(file_path, os.O_RDONLY)
		if err != nil do monkey_err("Error opening file", 1, &sb)
		defer os.close(f)

		contents, ok := os.read_entire_file_from_handle(f)
		ensure(ok)
		str_contents := strings.clone_from_bytes(contents, varena)

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
		Monkey_Run_String(str_contents, &sb, true)
	case "mexpand":
		file_path := os.args[2]
		if !os.exists(file_path) do monkey_err("File does not exist", 1, &sb)

		f, err := os.open(file_path, os.O_RDONLY)
		if err != nil do monkey_err("Error opening file", 1, &sb)
		defer os.close(f)

		contents, ok := os.read_entire_file_from_handle(f)
		ensure(ok)
		str_contents := strings.clone_from_bytes(contents, varena)

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

		p := Parser__New__(stmts)
		defer p->free()

		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)

		expanded_program, expand_err := expand_macros(program, &v)
		if expand_err != "" do monkey_err("Error expanding macros", 1, &sb, expand_err)

		strings.builder_reset(&sb)
		ast_to_string(expanded_program, &sb)
		fmt.println(strings.to_string(sb))

	case "help":
		fmt.println(HELPMSG)
	}
}

