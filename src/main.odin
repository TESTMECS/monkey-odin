package monkey
import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem/virtual"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:terminal/ansi"
/*
* Copyright (C) 2025 TESTMEE
* ./main.odin
*/
HELPMSG :: ` Usage: monkey-odin << repl |file <file_path>|bytes <file_path>|mexpand <file_path> |help >>
Commands:
  repl     Start the Monkey REPL.
  file     Run a << file_path >> and print the evaluation result.
	bytes    Run a << file_path >> and prettyprint bytecode.
	ast      Run a << file_path >> and prettyprint AST. 
	mexpand  Run a << file_path >> and prettyprint file with all macros expanded.
  help     Show this help message`
main :: proc() {
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
		cli_args := os.args[2:]

		fmt.println(
			ansi.CSI + ansi.FG_BRIGHT_GREEN + ansi.SGR + "Monkey REPL. Type 'exit' to quit.",
			ansi.CSI + ansi.RESET + ansi.SGR,
		)
		for {
			fmt.print(">> ")
			line, err := bufio.reader_read_string(&reader, '\n')
			if err != nil do monkey_err("Error reading input", 1, &sb, false, err)
			line = strings.trim_space(line)
			if line == "exit" do monkey_result(nil, &sb, true) // exit
			Monkey_Run_String(line, &sb, false, varena, cli_args, mexpand_rec) // don't exit
		}
	case "file":
		stmts, shebang_args := Monkey_Read_File(os.args[2], &sb, varena)
		all_args := make([dynamic]string, 0, varena)
		for arg in shebang_args {
			append(&all_args, arg)
		}
		if len(os.args) > 3 {
			for arg in os.args[3:] {
				append(&all_args, arg)
			}
		}
		_ = Monkey_Run_String(stmts, &sb, true, varena, all_args[:], mexpand_rec)
	case "bytes":
		stmts, _ := Monkey_Read_File(os.args[2], &sb, varena)
		p := Parser_New(stmts, varena)
		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)
		c := Compiler_New(varena, os.args[3:], 1)
		err := c->compile_program(program)
		if err != "" do monkey_err("Error compiling file", 1, &sb, true, err)
		bytecode := c->bytecode()
		fmt.println(byte_to_instruction(bytecode.instructions))
	case "ast":
		fmt.println(os.args[2])
		stmts, _ := Monkey_Read_File(os.args[2], &sb, varena)
		p := Parser_New(stmts, varena)
		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)
		ast_to_string(program, &sb)
		fmt.println(strings.to_string(sb))
	case "mexpand":
		stmts, _ := Monkey_Read_File(os.args[2], &sb, varena)
		p := Parser_New(stmts, varena)
		program := p->parse()
		if monkey_parser_has_error(p) do monkey_err("Error parsing file", 1, &sb)
		expanded_program, expand_err := expand_macros(program, mexpand_rec, varena)
		if expand_err != "" do monkey_err("Error expanding macros", 1, &sb, true, expand_err)
		strings.builder_reset(&sb)
		ast_to_string(expanded_program, &sb)
		fmt.println(strings.to_string(sb))
	case "help":
		fmt.println(HELPMSG)
	}
}

