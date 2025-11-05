package monkey

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:strings"

Macro_Expansion_Result :: struct {
	expanded: Node,
	error:    string,
}

expand_macros :: proc(
	program: Ast_Program,
	macro_rec := 1,
	varena: mem.Allocator,
) -> (
	Node,
	string,
) {
	if macro_rec <= 0 {
		return program, ""
	}
	macros := make(map[string]ObjectMacro, varena)

	for stmt in program {
		if let_stmt, ok := stmt.(Ast_Let); ok {
			if macro_lit, ok := let_stmt.value^.(Ast_Macro); ok {
				macro_obj := ObjectMacro {
					parameters = macro_lit.parameters,
					body       = macro_lit.body,
					env        = nil, // Will be set during evaluation
				}
				macros[let_stmt.name] = macro_obj
			}
		}
	}

	// Second pass: expand macro calls
	expanded_program := make(Ast_Program, 0, len(program), varena)
	for stmt in program {
		if let_stmt, ok := stmt.(Ast_Let); ok {
			if _, is_macro := macros[let_stmt.name]; is_macro {
				continue
			}
		}
		expanded_stmt, err := expand_node(stmt, macros, varena)
		if err != "" do return nil, err
		append(&expanded_program, expanded_stmt)
	}


	// Third pass: evaluate any remaining quote/unquote calls
	final_program := make(Ast_Program, 0, len(expanded_program), varena)
	for stmt in expanded_program {
		final_stmt, err := evaluate_remaining_quotes(stmt, varena)
		if err != "" do return nil, err
		append(&final_program, final_stmt)
	}

	// Recursive macro expansion with limit
	if macro_rec > 1 {
		return expand_macros(final_program, macro_rec - 1, varena)
	}

	return final_program, ""
}

expand_node :: proc(
	node: Node,
	macros: map[string]ObjectMacro,
	varena: mem.Allocator,
) -> (
	Node,
	string,
) {
	#partial switch data in node {
	case Ast_Call:
		if ident, ok := data.function^.(Ast_Identifier); ok {
			if macro, is_macro := macros[ident.value]; is_macro {
				return expand_macro_call(macro, data.arguments, varena)
			}
		}

		// Not a macro call, expand arguments recursively
		expanded_args := make([dynamic]Node, 0, len(data.arguments), varena)
		for arg in data.arguments {
			expanded_arg, err := expand_node(arg, macros, varena)
			if err != "" do return nil, err
			append(&expanded_args, expanded_arg)
		}

		expanded_function, err := expand_node(data.function^, macros, varena)
		if err != "" do return nil, err

		return Ast_Call {
				function = new_clone(expanded_function, varena),
				arguments = expanded_args,
			},
			""

	case Ast_Program:
		expanded := make(Ast_Program, 0, len(data), varena)
		for stmt in data {
			expanded_stmt, err := expand_node(stmt, macros, varena)
			if err != "" do return nil, err
			append(&expanded, expanded_stmt)
		}
		return expanded, ""

	case Ast_Block:
		expanded := make(Ast_Block, 0, len(data), varena)
		for stmt in data {
			expanded_stmt, err := expand_node(stmt, macros, varena)
			if err != "" do return nil, err
			append(&expanded, expanded_stmt)
		}
		return expanded, ""

	case Ast_Array:
		expanded := make(Ast_Array, 0, len(data), varena)
		for elem in data {
			expanded_elem, err := expand_node(elem, macros, varena)
			if err != "" do return nil, err
			append(&expanded, expanded_elem)
		}
		return expanded, ""

	case Ast_Hash_Table:
		expanded_pairs := make([dynamic]kvpair, 0, len(data.pairs), varena)
		for pair in data.pairs {
			expanded_key, key_err := expand_node(pair.key, macros, varena)
			if key_err != "" do return nil, key_err
			expanded_value, value_err := expand_node(pair.value, macros, varena)
			if value_err != "" do return nil, value_err
			append(&expanded_pairs, kvpair{key = expanded_key, value = expanded_value})
		}
		return Ast_Hash_Table{pairs = expanded_pairs}, ""

	case Ast_Let:
		expanded_value, err := expand_node(data.value^, macros, varena)
		if err != "" do return nil, err
		return Ast_Let{name = data.name, value = new_clone(expanded_value, varena)}, ""

	case Ast_Ret:
		expanded_value, err := expand_node(data.return_value^, macros, varena)
		if err != "" do return nil, err
		return Ast_Ret{return_value = new_clone(expanded_value, varena)}, ""

	case Ast_Prefix:
		expanded_operand, err := expand_node(data.operand^, macros, varena)
		if err != "" do return nil, err
		return Ast_Prefix{op = data.op, operand = new_clone(expanded_operand, varena)}, ""

	case Ast_Infix:
		expanded_left, left_err := expand_node(data.left^, macros, varena)
		if left_err != "" do return nil, left_err
		expanded_right, right_err := expand_node(data.right^, macros, varena)
		if right_err != "" do return nil, right_err
		return Ast_Infix {
				op = data.op,
				left = new_clone(expanded_left, varena),
				right = new_clone(expanded_right, varena),
			},
			""

	case:
		return node, ""
	}

	return node, ""
}

expand_macro_call :: proc(
	macro: ObjectMacro,
	args: [dynamic]Node,
	varena: mem.Allocator,
) -> (
	Node,
	string,
) {
	if len(args) != len(macro.parameters) {
		return nil, fmt.tprintf(
			"wrong number of arguments: want=%d, got=%d",
			len(macro.parameters),
			len(args),
		)
	}

	extended_env := Env_New(nil, varena)

	// Bind arguments to parameters
	for i in 0 ..< len(macro.parameters) {
		param := macro.parameters[i]
		arg_obj, err := eval_node_to_object(args[i], varena)
		if err != "" do return nil, err
		extended_env.set(&extended_env, param.value, arg_obj)
	}

	result, err := evaluate_macro_body(macro.body, &extended_env, varena)
	if err != "" do return nil, err

	return result, ""
}

eval_node_to_object :: proc(node: Node, varena: mem.Allocator) -> (ObjectBase, string) {
	#partial switch data in node {
	case int:
		return data, ""
	case bool:
		return data, ""
	case string:
		return strings.clone(data, varena), ""
	case:
		return nil, "unsupported node type for macro argument"
	}
}

evaluate_macro_body :: proc(
	body: Ast_Block,
	env: ^Environment,
	varena: mem.Allocator,
) -> (
	Node,
	string,
) {
	for stmt in body {
		if call, ok := stmt.(Ast_Call); ok {
			if ident, ok := call.function^.(Ast_Identifier); ok {
				if ident.value == "quote" && len(call.arguments) > 0 {
					// Check if the argument contains unquote calls and expand them
					expanded_arg, err := expand_unquote_calls(call.arguments[0], env, varena)
					if err != "" do return nil, err
					return expanded_arg, ""
				}
			}
		}
	}
	return nil, "macro body must contain a quote expression"
}

expand_unquote_calls :: proc(
	node: Node,
	env: ^Environment,
	varena: mem.Allocator,
) -> (
	Node,
	string,
) {
	#partial switch data in node {
	case Ast_Call:
		if ident, ok := data.function^.(Ast_Identifier); ok {
			if ident.value == "unquote" && len(data.arguments) > 0 {
				if ident_arg, ok := data.arguments[0].(Ast_Identifier); ok {
					if obj, ok := env.get(env, ident_arg.value); ok {
						if int_val, ok := obj.(int); ok {
							return int_val, ""
						}
					}
				} else if infix_expr, ok := data.arguments[0].(Ast_Infix); ok {
					return evaluate_simple_expression(infix_expr, env, varena)
				}
			}
		}

		// Check if this is an unquote call - if so, handle it and don't recurse further
		if ident, ok := data.function^.(Ast_Identifier); ok {
			if ident.value == "unquote" && len(data.arguments) > 0 {
				if ident_arg, ok := data.arguments[0].(Ast_Identifier); ok {
					if obj, ok := env.get(env, ident_arg.value); ok {
						if int_val, ok := obj.(int); ok {
							return int_val, ""
						}
					}
				} else if infix_expr, ok := data.arguments[0].(Ast_Infix); ok {
					return evaluate_simple_expression(infix_expr, env, varena)
				}
			}
		}

		expanded_function, err := expand_unquote_calls(data.function^, env, varena)
		if err != "" do return nil, err

		expanded_args := make([dynamic]Node, 0, len(data.arguments), varena)
		for arg in data.arguments {
			expanded_arg, arg_err := expand_unquote_calls(arg, env, varena)
			if arg_err != "" do return nil, arg_err
			append(&expanded_args, expanded_arg)
		}

		return Ast_Call {
				function = new_clone(expanded_function, varena),
				arguments = expanded_args,
			},
			""

	case Ast_Infix:
		expanded_left, left_err := expand_unquote_calls(data.left^, env, varena)
		if left_err != "" do return nil, left_err
		expanded_right, right_err := expand_unquote_calls(data.right^, env, varena)
		if right_err != "" do return nil, right_err

		return Ast_Infix {
				op = data.op,
				left = new_clone(expanded_left, varena),
				right = new_clone(expanded_right, varena),
			},
			""

	case Ast_For:
		expanded_condition, cond_err := expand_unquote_calls(data.cond^, env, varena)
		if cond_err != "" do return nil, cond_err

		expanded_body := make(Ast_Block, 0, len(data.body), varena)
		for stmt in data.body {
			expanded_stmt, stmt_err := expand_unquote_calls(stmt, env, varena)
			if stmt_err != "" do return nil, stmt_err
			append(&expanded_body, expanded_stmt)
		}

		return Ast_For{cond = new_clone(expanded_condition, varena), body = expanded_body}, ""

	case Ast_If:
		expanded_condition, cond_err := expand_unquote_calls(data.condition^, env, varena)
		if cond_err != "" do return nil, cond_err

		expanded_then, then_err := expand_unquote_calls(data.then, env, varena)
		if then_err != "" do return nil, then_err

		expanded_orelse: Ast_Block
		if data.orelse != nil {
			expanded_orelse_node, orelse_err := expand_unquote_calls(data.orelse, env, varena)
			if orelse_err != "" do return nil, orelse_err
			expanded_orelse = expanded_orelse_node.(Ast_Block)
		}

		return Ast_If {
				condition = new_clone(expanded_condition, varena),
				then = expanded_then.(Ast_Block),
				orelse = expanded_orelse,
			},
			""

	case:
		return node, ""
	}
	return node, ""
}

evaluate_simple_expression :: proc(
	expr: Ast_Infix,
	env: ^Environment,
	varena: mem.Allocator,
) -> (
	Node,
	string,
) {
	if left_int, ok := expr.left^.(int); ok {
		if right_int, ok := expr.right^.(int); ok {
			switch expr.op {
			case "+":
				return left_int + right_int, ""
			case "-":
				return left_int - right_int, ""
			case "*":
				return left_int * right_int, ""
			case "/":
				return left_int / right_int, ""
			}
		}
	}

	return nil, "unsupported expression in unquote"
}

evaluate_remaining_quotes :: proc(node: Node, varena: mem.Allocator) -> (Node, string) {
	#partial switch data in node {
	case Ast_Call:
		if ident, ok := data.function^.(Ast_Identifier); ok {
			if ident.value == "quote" && len(data.arguments) > 0 {
				return data.arguments[0], ""
			} else if ident.value == "unquote" && len(data.arguments) > 0 {
				return data.arguments[0], ""
			}
		}

		expanded_function, err := evaluate_remaining_quotes(data.function^, varena)
		if err != "" do return nil, err

		expanded_args := make([dynamic]Node, 0, len(data.arguments), varena)
		for arg in data.arguments {
			expanded_arg, arg_err := evaluate_remaining_quotes(arg, varena)
			if arg_err != "" do return nil, arg_err
			append(&expanded_args, expanded_arg)
		}

		return Ast_Call {
				function = new_clone(expanded_function, varena),
				arguments = expanded_args,
			},
			""

	case Ast_Program:
		expanded := make(Ast_Program, 0, len(data), varena)
		for stmt in data {
			expanded_stmt, err := evaluate_remaining_quotes(stmt, varena)
			if err != "" do return nil, err
			append(&expanded, expanded_stmt)
		}
		return expanded, ""

	case Ast_Block:
		expanded := make(Ast_Block, 0, len(data), varena)
		for stmt in data {
			expanded_stmt, err := evaluate_remaining_quotes(stmt, varena)
			if err != "" do return nil, err
			append(&expanded, expanded_stmt)
		}
		return expanded, ""

	case:
		return node, ""
	}
}

is_quote_call :: proc(node: Node) -> bool {
	if call, ok := node.(Ast_Call); ok {
		if ident, ok := call.function^.(Ast_Identifier); ok {
			return ident.value == "quote"
		}
	}
	return false
}

is_unquote_call :: proc(node: Node) -> bool {
	if call, ok := node.(Ast_Call); ok {
		if ident, ok := call.function^.(Ast_Identifier); ok {
			return ident.value == "unquote"
		}
	}
	return false
}

