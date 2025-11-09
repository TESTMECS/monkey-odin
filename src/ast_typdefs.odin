package monkey
import "core:reflect"

Ast__Type__ :: proc {
	Ast_Type_Value,
	ast_type_pointer,
}

@(private = "file")
ast_type_pointer :: proc(ast: ^Node) -> typeid {
	return reflect.union_variant_typeid(ast^)
}

Ast_Type_Value :: reflect.union_variant_typeid

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
	Ast_Foreach,
	Ast_Ternery,
}
// arr
Ast_Array :: distinct [dynamic]Node

// map
kvpair :: struct {
	key:   Node,
	value: Node,
}
Ast_Hash_Table :: struct {
	pairs: [dynamic]kvpair,
	table: map[string]Node,
}

// fn
Ast_Function :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
}

// macro
Ast_Macro :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
}

