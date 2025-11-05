package monkey

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem/virtual"
import "core:os"
import "core:strconv"
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
	// Arena for the whole program.
	v: virtual.Arena
	err := virtual.arena_init_growing(&v)
	ensure(err == nil)
	varena := virtual.arena_allocator(&v)
	defer virtual.arena_destroy(&v)

	mexpand_rec, ok := strconv.parse_int(os.get_env("BANANAS"))
	if !ok do mexpand_rec = 1

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
		cli_args := os.args[2:] // added as constants in the compiler

		fmt.println(
			ansi.CSI + ansi.FG_BRIGHT_GREEN + ansi.SGR + "Monkey REPL. Type 'exit' to quit.",
			ansi.CSI + ansi.RESET + ansi.SGR,
		)
		for { 	//repl
			fmt.print(">> ")
			// readline
			line, err := bufio.reader_read_string(&reader, '\n')
			if err != nil do monkey_err("Error reading input", 1, &sb, false, err)
			line = strings.trim_space(line)
			if line == "exit" do monkey_result(nil, &sb, true) // exit
			// Run
			Monkey_Run_String(line, &sb, false, varena, cli_args, mexpand_rec) // don't exit
		}
	case "file":
		stmts, shebang_args := Monkey_Read_File(os.args[2], &sb, varena)
		// Combine shebang args with command line args (os.args[3:])
		all_args := make([dynamic]string, 0, varena)
		for arg in shebang_args {
			append(&all_args, arg)
		}
		if len(os.args) > 3 {
			// Append command line args after the file path
			for arg in os.args[3:] {
				append(&all_args, arg)
			}
		}
		Monkey_Run_String(stmts, &sb, true, varena, all_args[:], mexpand_rec)
	case "mexpand":
		stmts, _ := Monkey_Read_File(os.args[2], &sb, varena)
		// Parse file
		p := Parser_New(stmts, varena)
		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)
		//expand macros
		expanded_program, expand_err := expand_macros(program, mexpand_rec, varena)
		if expand_err != "" do monkey_err("Error expanding macros", 1, &sb, true, expand_err)
		//print expanded program
		strings.builder_reset(&sb)
		ast_to_string(expanded_program, &sb)
		fmt.println(strings.to_string(sb))
	case "help":
		fmt.println(HELPMSG)
	}
}

