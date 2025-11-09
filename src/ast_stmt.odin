package monkey

Ast_Program :: distinct [dynamic]Node

Ast_Block :: distinct [dynamic]Node

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

Ast_Ternery :: struct {
	condition: ^Node,
	then:      ^Node,
	orelse:    ^Node,
}

Ast_If :: struct {
	condition: ^Node,
	then:      Ast_Block,
	orelse:    Ast_Block,
}

