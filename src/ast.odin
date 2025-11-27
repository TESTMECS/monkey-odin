package monkey
import "core:reflect"
/*
* Copyright (C) 2025 TESTMEE
* ./ast.odin 
* This file defines the ast for monkey-odin.
* Type-Structs<< Ast_Hash_Table, kvpair, Ast_Function, Ast_Macro >>
	* Stmt-Structs<< Ast_Program, Ast_Block, Ast_Block, Ast_Identifier, Ast_For, Ast_Call, Ast_Ternery, Ast_If >>
	* Expr-Structs<< Ast_Index, Ast_Ret, Ast_Foreach, Ast_Let, Ast_Prefix, Ast_Infix >>
* Unions<< Node >>
* Aliases<< Ast_Type_Value, Ast_Array >>
* Methods<< Ast__Type__, Ast_IsExpr  >>
*/
Ast__Type__ :: proc {
	Ast_Type_Value,
	ast_type_pointer,
}
@(private = "file")
ast_type_pointer :: proc(ast: ^Node) -> typeid {
	return reflect.union_variant_typeid(ast^)
}
Ast_Type_Value :: reflect.union_variant_typeid /* Returns typeid of union variant */
// AST Node Union, includes nil.
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
// An array of nodes, 'distinct' ensures hashable.
Ast_Array :: distinct [dynamic]Node
// A hash table of key-value pairs
kvpair :: struct {
	key:   Node,
	value: Node,
}
Ast_Hash_Table :: struct {
	pairs: [dynamic]kvpair, // key-value pairs
	table: map[string]Node, // "key": value
}
Ast_Function :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
}
Ast_Macro :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
}
// Distinct ensures hashable like Ast_Array.
Ast_Program :: distinct [dynamic]Node // A program is a list of blocks
Ast_Block :: distinct [dynamic]Node // A block is a list of Statements
Ast_Identifier :: struct {
	value: string,
}
Ast_For :: struct {
	cond: ^Node,
	body: Ast_Block,
}
Ast_Call :: struct {
	function:  ^Node,
	arguments: [dynamic]Node,
}
// Ternery's use Node because they return values
Ast_Ternery :: struct {
	condition: ^Node,
	then:      ^Node,
	orelse:    ^Node,
}
// If statements are a condition followed by one or two block statements.
Ast_If :: struct {
	condition: ^Node,
	then:      Ast_Block,
	orelse:    Ast_Block,
}
// Expressions are anything except "Node", "Let", "Ret", "Foreach"
Ast_IsExpr :: proc(ast: Node) -> bool {
	t := Ast__Type__(ast)
	return t != Node && t != Ast_Let && t != Ast_Ret && t != Ast_Foreach
}
// Index expressions are for accessing array elements
Ast_Index :: struct {
	operand: ^Node,
	index:   ^Node,
}
Ast_Ret :: struct {
	return_value: ^Node,
}
Ast_Foreach :: struct {
	itervar: string, // for "i" in
	expr:    ^Node, // "arr" or "map" do
	body:    Ast_Block,
}
Ast_Let :: struct {
	name:  string,
	value: ^Node,
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

