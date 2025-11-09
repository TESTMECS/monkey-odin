package monkey
import "core:fmt"
import "core:strings"

ast_to_string :: proc {
	ast_to_string_pointer,
	ast_to_string_value,
}

@(private = "file")
ast_to_string_value :: proc(ast: Node, sb: ^strings.Builder) {
	ast := ast
	ast_to_string_pointer(&ast, sb)
}

@(private = "file")
ast_to_string_pointer :: proc(ast: ^Node, sb: ^strings.Builder) {
	#partial switch data in ast


	{
	case bool, int, f64, string:
		fmt.sbprint(sb, data)

	case Ast_Program:
		for stmt, i in data {
			ast_to_string(stmt, sb)
			if i < len(data) - 1 do fmt.sbprint(sb, "\n")
		}

	case Ast_For:
		fmt.sbprint(sb, "for ")
		ast_to_string(data.cond, sb)
		fmt.sbprint(sb, " ")
		ast_to_string(data.body, sb)

	case Ast_Macro:
		fmt.sbprint(sb, "macro ")
		ast_to_string(data.body, sb)

	case Ast_Identifier:
		fmt.sbprint(sb, data.value)

	case Ast_Let:
		fmt.sbprint(sb, "let", data.name)
		if data.value != nil {
			fmt.sbprint(sb, " = ")
			ast_to_string(data.value, sb)
		}
		fmt.sbprint(sb, ";")

	case Ast_Ret:
		fmt.sbprint(sb, "let")
		if data.return_value != nil {
			fmt.sbprint(sb, " ")
			ast_to_string(data.return_value, sb)
		}
		fmt.sbprint(sb, ";")

	case Ast_Prefix:
		fmt.sbprintf(sb, "(%s", data.op)
		ast_to_string(data.operand, sb)
		fmt.sbprint(sb, ")")

	case Ast_Infix:
		fmt.sbprint(sb, "( ")
		ast_to_string(data.left, sb)
		fmt.sbprint(sb, " ")
		fmt.sbprint(sb, data.op)
		fmt.sbprint(sb, " ")
		ast_to_string(data.right, sb)
		fmt.sbprint(sb, " )")

	case Ast_If:
		fmt.sbprint(sb, "if ")
		ast_to_string(data.condition, sb)
		fmt.sbprint(sb, " ")
		ast_to_string(data.then, sb)

		if data.orelse != nil {
			fmt.sbprint(sb, " else ")
			ast_to_string(data.orelse, sb)
		}

	case Ast_Block:
		fmt.sbprint(sb, "{ ")
		for stmt, i in data {
			ast_to_string(stmt, sb)
			if i < len(data) - 1 do fmt.sbprint(sb, "; ")
		}
		fmt.sbprint(sb, " }")

	case Ast_Array:
		fmt.sbprint(sb, "[")
		for stmt, i in data {
			ast_to_string(stmt, sb)
			if i < len(data) - 1 do fmt.sbprint(sb, ", ")
		}
		fmt.sbprint(sb, "]")

	case Ast_Hash_Table:
		fmt.sbprint(sb, "{ ")
		i := 0
		for pair, i in data.pairs {
			ast_to_string(pair.key, sb)
			fmt.sbprint(sb, ": ")
			ast_to_string(pair.value, sb)
			if i < len(data.pairs) - 1 do fmt.sbprint(sb, ", ")
		}
		fmt.sbprint(sb, " }")

	case Ast_Index:
		fmt.sbprint(sb, "(")
		ast_to_string(data.operand, sb)
		fmt.sbprint(sb, "[")
		ast_to_string(data.index, sb)
		fmt.sbprint(sb, "]")
		fmt.sbprint(sb, ")")

	case Ast_Function:
		fmt.sbprint(sb, "Fn (")
		for param, i in data.parameters {
			fmt.sbprint(sb, param.value)

			if i < len(data.parameters) - 1 do fmt.sbprint(sb, ", ")
		}
		fmt.sbprint(sb, ") ")

		ast_to_string(data.body, sb)

	case Ast_Call:
		ast_to_string(data.function, sb)
		fmt.sbprint(sb, "(")
		for arg, i in data.arguments {
			ast_to_string(arg, sb)

			if i < len(data.arguments) - 1 do fmt.sbprint(sb, ", ")
		}
		fmt.sbprint(sb, ")")
	case Ast_Method_Call:
		ast_to_string(data.object, sb)
		fmt.sbprint(sb, "@")
		ast_to_string(data.method, sb)
		fmt.sbprint(sb, "(")
		for arg, i in data.arguments {
			ast_to_string(arg, sb)

			if i < len(data.arguments) - 1 do fmt.sbprint(sb, ", ")
		}
		fmt.sbprint(sb, ")")
	case Ast_Class:
		fmt.sbprint(sb, "Class ")
		ast_to_string(data.name, sb)
		if data.super != nil {
			fmt.sbprint(sb, "(super:")
			for super, i in data.super {
				ast_to_string(super, sb)
				if i < len(data.super) - 1 do fmt.sbprint(sb, ", ")
			}
			fmt.sbprint(sb, ")\n")
		}
		 else {fmt.sbprint(sb, "(super:nil)\n")}

		fmt.sbprint(sb, "{\n")
		for stmt, i in data.body {
			fmt.sbprint(sb, "\t")
			ast_to_string(stmt, sb)
			if i < len(data.body) - 1 do fmt.sbprint(sb, "\n")
		}
		fmt.sbprint(sb, "\n}")
	case Ast_Foreach:
		fmt.sbprint(sb, "foreach ")
		ast_to_string(data.itervar, sb)
		fmt.sbprint(sb, " in ")
		ast_to_string(data.expr, sb)
		fmt.sbprint(sb, " ")
		ast_to_string(data.body, sb)
	}
}

