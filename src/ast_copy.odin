package monkey
import "core:mem"
import "core:strings"

Ast__Copy__ :: proc {
	ast_copy_idents,
	ast_copy_block,
	ast_copy_nodes,
	ast_copy_array,
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

new_clone :: proc(value: $T, allocator: mem.Allocator) -> ^T {
	ptr := new(T, allocator)
	ptr^ = value
	return ptr
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

