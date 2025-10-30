package monkey
import "core:fmt"
import "core:strings"
//%type{Environment::struct}
Environment :: struct {
	store: map[string]ObjectBase,
	outer: ^Environment,
	//%methods
	get:   proc(env: ^Environment, name: string) -> (ObjectBase, bool),
	set:   proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase,
	free:  proc(env: ^Environment),
	vmem:  VArena,
}
Env_New :: proc(outer: ^Environment = nil) -> Environment {
	v := VArena__New__()
	err := v->init()
	if err != .None {
		panic("Failed to initialize environment memory manager")
	}
	//Store is still empty
	return Environment{get = env_get, set = env_set, free = env_free, outer = outer, vmem = v}
}
Env__Enclosed__ :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator := context.allocator,
) -> Environment {
	env := Env_New(outer)
	env.store = make(map[string]ObjectBase, reserved, allocator)
	env_clone := new_clone(env, allocator)^
	return env_clone
}
env_set :: proc(e: ^Environment, name: string, value: ObjectBase) -> ObjectBase {
	e.store[name] = value
	return value
}
@(private = "file")
env_free :: proc(e: ^Environment) {
	e.vmem->reset()
}
@(private = "file")
env_get :: proc(e: ^Environment, name: string) -> (ObjectBase, bool) {
	obj, ok := e.store[name]
	if !ok && e.outer != nil {obj, ok = e.outer->get(name)}
	return obj, ok
}

