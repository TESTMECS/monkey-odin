package monkey
//%type{Environment::struct}
Environment :: struct {
	store: map[string]ObjectBase,
	//%note:"recursive env"
	outer: ^Environment,
	init:  proc(env: ^Environment),
	get:   proc(env: ^Environment, name: string) -> (ObjectBase, bool),
	set:   proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase,
	free:  proc(env: ^Environment),
	vmem:  VArena,
}

EnvNew :: proc(outer: ^Environment = nil) -> Environment {
	return Environment{get = EnvGet, set = EnvSet, free = EnvFree, outer = outer, init = init_mem}
}

init_mem :: proc(e: ^Environment) {
	err := MM_New(&e.vmem)
	if err != .None {
		panic("Failed to initialize environment memory manager")
	}
}

EnvEnclosed :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator := context.allocator,
) -> Environment {
	env := EnvNew(outer)
	store := MemAlloc(&env.vmem, map[string]ObjectBase)
	return new_clone(env, allocator)^
}

@(private = "file")
EnvFree :: proc(e: ^Environment) {
	delete(e.store)
}

@(private = "file")
EnvGet :: proc(e: ^Environment, name: string) -> (ObjectBase, bool) {
	obj, ok := e.store[name]
	if !ok && e.outer != nil {obj, ok = e.outer->get(name)}
	return obj, ok
}

EnvSet :: proc(e: ^Environment, name: string, value: ObjectBase) -> ObjectBase {
	e.store[name] = value
	return value
}

