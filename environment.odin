package monkey
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
	env := Environment{}
	v := VArena__New__()
	err := v->init()
	if err != .None {
		panic("Failed to initialize environment memory manager")
	}
	env.store = make(map[string]ObjectBase, 0, v.allocator)
	env.get = env_get
	env.set = env_set
	env.free = env_free
	env.outer = outer
	env.vmem = v
	return env
}
Env__Enclosed__ :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator := context.allocator,
) -> Environment {
	env := Env_New(outer)
	env.store = make(map[string]ObjectBase, reserved, allocator)
	return env
}
env_set :: proc(e: ^Environment, name: string, value: ObjectBase) -> ObjectBase {
	e.store[name] = value
	return value
}
@(private = "file")
env_free :: proc(e: ^Environment) {
	e.vmem->reset()
	delete(e.store)
}
@(private = "file")
env_get :: proc(e: ^Environment, name: string) -> (ObjectBase, bool) {
	obj, ok := e.store[name]
	if !ok && e.outer != nil {obj, ok = e.outer->get(name)}
	return obj, ok
}

