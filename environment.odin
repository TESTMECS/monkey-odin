package monkey
//%type{Environment::struct}
Environment :: struct {
	store: map[string]ObjectBase,
	//%note:"recursive env"
	outer: ^Environment,
	get:   proc(env: ^Environment, name: string) -> (ObjectBase, bool),
	set:   proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase,
	free:  proc(env: ^Environment),
	vmem:  VArena,
}
Env_New :: proc(outer: ^Environment = nil) -> Environment {
	e := Environment {
		get   = env_get,
		set   = Env_Set,
		free  = env_free,
		outer = outer,
	}
	v := VArena__New__()
	err := v->init()
	if err != .None {
		panic("Failed to initialize environment memory manager")
	}
	e.vmem = v
	return e
}
Env__Enclosed__ :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator := context.allocator,
) -> Environment {
	env := Env_New(outer)
	store := Vmem__Alloc__(&outer.vmem, map[string]ObjectBase)
	return new_clone(env, allocator)^
}
Env_Set :: proc(e: ^Environment, name: string, value: ObjectBase) -> ObjectBase {
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

