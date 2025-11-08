package monkey

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:terminal/ansi"

Monkey_Run_String :: proc(
	stmts: string,
	sb: ^strings.Builder,
	exit: bool,
	varena: mem.Allocator,
	cli_args: []string,
	mexpand_rec := 1,
) -> Object
{
	// string -> ast -> compiler -> bytecode -> vm -> checks last popped object.
	p := Parser_New(stmts, varena)
	program := p->parse()
	if monkey_parser_has_error(p)
	{
		monkey_err("Error parsing file: ", 1, sb, exit, p.errors)
		return nil
	}
	c := Compiler_New(varena, cli_args, mexpand_rec)
	compile_err := c->compile_program(program, mexpand_rec) // pass in macro constant here.
	if compile_err != ""
	{
		monkey_err("Error compiling file: ", 1, sb, exit, compile_err)
		return nil
	}
	bytecode := c->bytecode()
	vm := Vm_New(bytecode, &c.compiler_state, varena)
	vm_err := vm->run_vm()
	if vm_err != ""
	{
		monkey_err("Error running file: ", 1, sb, exit, vm_err)
		return nil
	}
	last_popped := vm->last_popped()
	obj := monkey_result(last_popped, sb, exit)
	return obj
}

Monkey_Read_File :: proc(
	file_path: string,
	sb: ^strings.Builder,
	varena: mem.Allocator,
) -> (
	stmts: string,
	cli_args: []string,
)
{
	// Read file path and return its string contents.
	if !os.exists(file_path) do monkey_err("File does not exist: ", 1, sb)

	f, err := os.open(file_path, os.O_RDONLY)
	if err != nil do monkey_err("Error opening file: ", 1, sb)
	defer os.close(f)

	contents, ok := os.read_entire_file_from_handle(f)
	ensure(ok)
	str_contents := strings.clone_from_bytes(contents, varena)

	// Skip Shebang, parse args here.
	cli_args = []string{}
	if strings.starts_with(str_contents, "#!")
	{
		// Extract the first line (shebang)
		if idx := strings.index_byte(str_contents, '\n'); idx >= 0
		{
			shebang_line := str_contents[:idx]
			str_contents = str_contents[idx + 1:]

			// Parse arguments from shebang line
			// Look for "--" to extract arguments after it
			if double_dash_idx := strings.index(shebang_line, "--"); double_dash_idx >= 0
			{
				args_part := strings.trim_space(shebang_line[double_dash_idx + 2:])
				if args_part != ""
				{
					// Split by spaces to get individual arguments
					args_split := strings.split(args_part, " ")
					cli_args = make([]string, len(args_split), varena)
					copy(cli_args[:], args_split[:])
				}
			}
		}
		 else
		{
			str_contents = ""
		}
	}
	 else
	{
		str_contents = strings.trim_space(str_contents)
	}

	return str_contents, cli_args
}

monkey_parser_has_error :: proc(p: Parser) -> bool
{
	if len(p.errors) == 0 do return false
	log.errorf("parser has %d errors", len(p.errors))

	for msg, _ in p.errors do log.errorf("parser error: %q", msg)
	return true
}

monkey_err :: proc(msg: string, status: int, sb: ^strings.Builder, exit := true, xtra: ..any)
{
	strings.builder_reset(sb)

	fmt.sbprintf(sb, msg)
	if xtra != nil do fmt.sbprintln(sb, ..xtra)

	err_msg := strings.to_string(sb^)
	fmt.println(err_msg)

	if exit do os.exit(status)
}

monkey_result :: proc(
	return_object: Object,
	sb: ^strings.Builder,
	exit: bool,
	xtra: ..any,
) -> Object
{
	strings.builder_reset(sb)

	fmt.sbprintf(sb, "=>>")
	if xtra != nil do fmt.sbprintln(sb, ..xtra)

	obj := Object(return_object)
	ObjectInspect(obj, sb)

	fmt.println(strings.to_string(sb^))
	if exit do os.exit(0)
	return obj
}

monkey_print_help :: proc(sb: ^strings.Builder)
{
	strings.builder_reset(sb)
	green_greeting :=
		ansi.CSI + ansi.FG_GREEN + ansi.SGR + HELPMSG + ansi.CSI + ansi.RESET + ansi.SGR
	fmt.sbprintfln(sb, green_greeting)
	fmt.println(strings.to_string(sb^))
}

dbg :: proc(fstring: string, args: ..any)
{
	fmt.printfln(fstring, ..args)
}

