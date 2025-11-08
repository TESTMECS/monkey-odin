package monkey
import "core:reflect"

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
	Ast_Class,
}

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

Ast_Foreach :: struct {
	itervar: string,
	expr:    ^Node, // arr or map
	body:    Ast_Block,
}

Ast_Class :: struct {
	name:  string,
	super: [dynamic]Ast_Identifier,
	body:  Ast_Block,
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
}

Ast_Type_Value :: reflect.union_variant_typeid

Ast_IsExpr :: proc(ast: Node) -> bool {
	t := Ast__Type__(ast)
	return t != Node && t != Ast_Let && t != Ast_Ret && t != Ast_Class
}

Ast__Type__ :: proc {
	Ast_Type_Value,
	ast_type_pointer,
}

@(private = "file")
ast_type_pointer :: proc(ast: ^Node) -> typeid {
	return reflect.union_variant_typeid(ast^)
}

