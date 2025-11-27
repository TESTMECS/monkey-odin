package monkey
import "core:fmt"
import "core:os"
import "core:strings"
/*
* Copyright (C) 2025 TESTMEE
* ./builtins_io.odin
* This file defines the builtin io functions for monkey-odin.
* << b_printf, b_puts, b_readf, b_writef >>
*/
b_printf :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Print obj">>
				printf(format, obj)
				$ format :: str of "%d", "%s", "%f", "%v"
				$ obj :: obj of int, str, float, any
				Usage: printf("%d", 1)=>>1<<`


	if len(args) < 1 {
		return eval_new_error(
				e,
				"'printf' function error: wrong number of arguments, wants=<<Greater than or equal to 1>>, got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	format_str, ok := args[0].(string)
	if !ok {
		return eval_new_error(
				e,
				"'printf' function error: first argument must be a valid format string, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	strings.builder_reset(&e.sb)
	specifier_count := 0
	for i := 0; i < len(format_str); i += 1 {
		if format_str[i] == '%' {
			if i + 1 >= len(format_str) {break}
			if format_str[i + 1] != '%' {
				specifier_count += 1
			}
			 else {
				i += 1
			}
		}
	}
	if specifier_count != len(args) - 1 {
		return eval_new_error(
				e,
				"'printf' function error: format string expects %d arguments, got %d.%s",
				specifier_count,
				len(args) - 1,
				usage,
			),
			false
	}
	fmt_args := make([]any, len(args) - 1, e.varena)
	for i in 1 ..< len(args) {
		fmt_args[i - 1] = args[i]
	}
	fmt.sbprintf(&e.sb, format_str, ..fmt_args)
	fmt.println(strings.to_string(e.sb))
	return strings.to_string(e.sb), true
}
b_args :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get args">>
				args()
				$ none
				Usage: args()=>>["arg1", "arg2"]<<`


	if len(args) != 0 {
		return eval_new_error(
				e,
				"'args' function error: wrong number of arguments, wants='0', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	args_array := make([dynamic]ObjectBase, 0, e.varena)
	for arg in e.args {
		arg_clone := strings.clone(arg, e.varena)
		append(&args_array, arg_clone)
	}
	return ObjectArray(args_array), true
}
b_puts :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Print obj">>
				puts(arr)
				$ arr :: obj   
				Usage: puts([1,2,3])=>>[1,2,3]<<`


	strings.builder_reset(&e.sb)
	for arg in args {
		ObjectInspect(arg, &e.sb)
		fmt.sbprintln(&e.sb)
	}
	fmt.println(strings.to_string(e.sb)) // also print for multiple statements.
	return strings.to_string(e.sb), true
}
b_readf :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"read file"
				readf(file)
				$ file :: str
				Usage: readf("file.txt")=>>"line1\nline2\n"<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'readf' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	file, ok := args[0].(string)
	if !ok {
		return eval_new_error(
				e,
				"'readf' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	file_content, okk := os.read_entire_file(file)
	if !okk do return eval_new_error(e, "'readf' function error: cannot read file '%s'.%s", file, usage), false
	return string(file_content), true
}
b_writef :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Write obj to file">>
				writef(file, obj)
				$ file :: str
				$ obj :: obj
				Usage: writef("file.txt", "hello monkey")=>>true|false<<`


	if len(args) != 2 {
		return eval_new_error(
				e,
				"'writef' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	file, ok := args[0].(string)
	if !ok {
		return eval_new_error(
				e,
				"'writef' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	str_obj, okk := args[1].(string)
	if !okk {
		return eval_new_error(
				e,
				"'writef' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	okkk := os.write_entire_file(file, transmute([]u8)str_obj)
	if !okkk do return eval_new_error(e, "'writef' function error: cannot write file '%s'.%s", file, usage), false
	return true, true
}

