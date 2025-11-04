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
	// Some memory allocation
	// Ideally I could just use this for everything no cap frfr
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
			Monkey_Run_String(line, &sb, false, varena)
		} //<<repl
	case "file":
		stmts := Monkey_Read_File(os.args[2], &sb, varena)
		Monkey_Run_String(stmts, &sb, true, varena)
	case "mexpand":
		stmts := Monkey_Read_File(os.args[2], &sb, varena)
		// Parse file
		p := Parser_New(stmts, varena)
		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)
		//expand macros
		expanded_program, expand_err := expand_macros(program, &v)
		if expand_err != "" do monkey_err("Error expanding macros", 1, &sb, expand_err)
		//print expanded program
		strings.builder_reset(&sb)
		ast_to_string(expanded_program, &sb)
		fmt.println(strings.to_string(sb))
	case "help":
		fmt.println(HELPMSG)
	}
}

