package monkey

import "core:fmt"
import "core:mem"
import "core:strings"
//%note:"literal for now"
Evaluator :: struct {
	_env: Environment,
	eval: proc(
		e: ^Evaluator,
		node: Ast_Program,
		allocator := context.allocator,
	) -> (
		MonkeyObject,
		bool,
	),
	init: proc(e: ^Evaluator, allocator := context.allocator),
	free: proc(e: ^Evaluator),
	vmem: VArena,
}

