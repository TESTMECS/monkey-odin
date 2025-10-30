package monkey
import "core:fmt"
import "core:mem"
import "core:strings"
//%note:"literal for now"
Evaluator :: struct {
	_env: Environment,
	//%note:"What allocator to use"
	eval: proc(
		e: ^Evaluator,
		node: Ast_Program,
		allocator := context.allocator,
	) -> (
		ObjectBase,
		bool,
	),
	free: proc(e: ^Evaluator),
	vmem: VArena,
}
Evaluator_New :: proc() -> Evaluator {
	new_env := Env_New()

	e := Evaluator {
		_env = new_env,
		eval = eval_statements,
		free = eval_free,
	}

	evaluator_mem_init(&e)

	return e
}
evaluator_mem_init :: proc(e: ^Evaluator) {
	err := Vmem_New(&e.vmem)
	if err != .None {
		panic("Failed to initialize environment memory manager")
	}
}
eval_statements :: proc(
	e: ^Evaluator,
	node: Ast_Program,
	allocator := context.allocator,
) -> (
	ObjectBase,
	bool,
) {
	unreachable()
}
eval_free :: proc(e: ^Evaluator) {
	VmemReset(&e.vmem)
}

