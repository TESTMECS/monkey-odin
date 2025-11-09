package monkey

Ast_IsExpr :: proc(ast: Node) -> bool {
	t := Ast__Type__(ast)
	return t != Node && t != Ast_Let && t != Ast_Ret && t != Ast_Class && t != Ast_Foreach
}

Ast_Index :: struct {
	operand: ^Node,
	index:   ^Node,
}

Ast_Ret :: struct {
	return_value: ^Node,
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

