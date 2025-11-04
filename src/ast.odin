package monkey

import "core:fmt"
import "core:mem"
import "core:reflect"
import "core:strings"

Node :: union {
	f64,
	int,
	bool,
	string,
	Ast_Program,
	Ast_Let,
	Ast_Ret,
	Ast_Block,
	Ast_Identifier,
	Ast_Prefix,
	Ast_Infix,
	Ast_If,
	Ast_Array,
	Ast_Hash_Table,
	Ast_Function,
	Ast_Call,
	Ast_Index,
	Ast_Macro,
	Ast_For,
}
// @Ast=>>begin
Ast_Program :: distinct [dynamic]Node

Ast_Block :: distinct [dynamic]Node

Ast_Array :: distinct [dynamic]Node

Ast_For :: struct {
	cond: ^Node,
	body: Ast_Block,
}

Ast_Call :: struct {
	function:  ^Node,
	arguments: [dynamic]Node,
}

Ast_Hash_Table :: struct {
	pairs: [dynamic]kvpair,
	table: map[string]Node,
}

Ast_Function :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
}

Ast_Let :: struct {
	name:  string,
	value: ^Node,
}

Ast_Ret :: struct {
	return_value: ^Node,
}

Ast_Identifier :: struct {
	value: string,
}

Ast_Prefix :: struct {
	op:      string,
	operand: ^Node,
}

Ast_Infix :: struct {
	op:    string,
	left:  ^Node,
	right: ^Node,
}

Ast_If :: struct {
	condition: ^Node,
	then:      Ast_Block,
	orelse:    Ast_Block,
}

kvpair :: struct {
	key:   Node,
	value: Node,
}

Ast_Index :: struct {
	operand: ^Node,
	index:   ^Node,
}

Ast_Macro :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
} // end <<@Ast

Ast_IsExpr :: proc(ast: Node) -> bool {
	t := Ast__Type__(ast)
	return t != Node && t != Ast_Let && t != Ast_Ret
}

Ast__Type__ :: proc {
	Ast_Type_Value,
	ast_type_pointer,
}

Ast_Type_Value :: reflect.union_variant_typeid

@(private = "file")
ast_type_pointer :: proc(ast: ^Node) -> typeid {
	return reflect.union_variant_typeid(ast^)
}

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
	#partial switch data in ast {
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
		fmt.sbprint(sb, "(")
		ast_to_string(data.left, sb)
		fmt.sbprint(sb, data.op)
		ast_to_string(data.right, sb)
		fmt.sbprint(sb, ")")

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
	}
}

ast_copy_array :: proc(ast: ^Ast_Array, dst: ^Ast_Array, allocator: mem.Allocator) {
	for &stmt in ast {
		append(dst, ast_copy(&stmt, allocator))
	}
}

@(private = "file")
ast_copy_idents :: proc(
	ast: ^[dynamic]Ast_Identifier,
	dst: ^[dynamic]Ast_Identifier,
	allocator: mem.Allocator,
) {
	for stmt in ast {
		append(dst, Ast_Identifier{value = strings.clone(stmt.value, allocator)})
	}
}

@(private = "file")
ast_copy_block :: proc(ast: ^Ast_Block, dst: ^Ast_Block, allocator: mem.Allocator) {
	for &stmt in ast {
		append(dst, ast_copy(&stmt, allocator))
	}
}

@(private = "file")
ast_copy_nodes :: proc(ast: ^[dynamic]Node, dst: ^[dynamic]Node, allocator: mem.Allocator) {
	for &stmt in ast {
		append(dst, ast_copy(&stmt, allocator))
	}
}
// @AstCopy=>>begin
new_clone :: proc(value: $T, allocator: mem.Allocator) -> ^T {
	ptr := new(T, allocator)
	ptr^ = value
	return ptr
}

Ast__Copy__ :: proc {
	ast_copy_idents,
	ast_copy_block,
	ast_copy_nodes,
	ast_copy_array,
}

ast_copy :: proc(ast: ^Node, allocator: mem.Allocator) -> Node {
	#partial switch &data in ast {
	case int, bool, f64:
		return data

	case string:
		return strings.clone(data, allocator)

	case Ast_Identifier:
		return Ast_Identifier{value = strings.clone(data.value, allocator)}

	case Ast_Let:
		return Ast_Let {
			name = strings.clone(data.name, allocator),
			value = new_clone(ast_copy(data.value, allocator), allocator),
		}

	case Ast_Ret:
		return Ast_Ret{return_value = new_clone(ast_copy(data.return_value, allocator), allocator)}

	case Ast_Prefix:
		return Ast_Prefix {
			op = strings.clone(data.op, allocator),
			operand = new_clone(ast_copy(data.operand, allocator), allocator),
		}

	case Ast_Infix:
		return Ast_Infix {
			op = strings.clone(data.op, allocator),
			left = new_clone(ast_copy(data.left, allocator), allocator),
			right = new_clone(ast_copy(data.right, allocator), allocator),
		}

	case Ast_If:
		then := make(Ast_Block, 0, len(data.then), allocator)
		Ast__Copy__(&data.then, &then, allocator)

		orelse: Ast_Block
		if data.orelse != nil {
			then = make(Ast_Block, 0, len(data.orelse), allocator)
			Ast__Copy__(&data.orelse, &orelse, allocator)
		}

		return Ast_If {
			condition = new_clone(ast_copy(data.condition, allocator), allocator),
			then = then,
			orelse = orelse,
		}

	case Ast_Array:
		arr_copy := make(Ast_Array, 0, len(data), allocator)
		Ast__Copy__(&data, &arr_copy, allocator)
		return arr_copy

	case Ast_Hash_Table:
		hash_copy := Ast_Hash_Table {
			pairs = make([dynamic]kvpair, 0, len(data.pairs), allocator),
			table = make(map[string]Node),
		}

		n := len(data.pairs)
		for ; n > 0; n -= 1 {
			if n > 0 {
				e: kvpair = pop(&data.pairs)
				ast_copy(&e.key, allocator)
				ast_copy(&e.value, allocator)
				append(&hash_copy.pairs, e)
			}
		}

		for key, &value in data.table {
			key_clone := strings.clone(key, allocator)
			hash_copy.table[key_clone] = ast_copy(&value, allocator)
		}

		return hash_copy
	case Ast_Function:
		parameters := make([dynamic]Ast_Identifier, 0, len(data.parameters), allocator)
		Ast__Copy__(&data.parameters, &parameters, allocator)

		body := make(Ast_Block, 0, len(data.body), allocator)
		Ast__Copy__(&data.body, &body, allocator)

		return Ast_Function{parameters = parameters, body = body}

	case Ast_Call:
		arguments := make([dynamic]Node, 0, len(data.arguments), allocator)
		Ast__Copy__(&data.arguments, &arguments, allocator)

		return Ast_Call {
			function = new_clone(ast_copy(data.function, allocator), allocator),
			arguments = arguments,
		}

	case Ast_Index:
		return Ast_Index {
			operand = new_clone(ast_copy(data.operand, allocator), allocator),
			index = new_clone(ast_copy(data.index, allocator), allocator),
		}

	case Ast_For:
		return Ast_For {
			cond = new_clone(ast_copy(data.cond, allocator), allocator),
			body = make(Ast_Block, 0, len(data.body), allocator),
		}

	case Ast_Macro:
		parameters := make([dynamic]Ast_Identifier, 0, len(data.parameters), allocator)
		Ast__Copy__(&data.parameters, &parameters, allocator)

		body := make(Ast_Block, 0, len(data.body), allocator)
		Ast__Copy__(&data.body, &body, allocator)

		return Ast_Function{parameters = parameters, body = body}

	}
	unimplemented()
}
// @AstCopy=>>end

