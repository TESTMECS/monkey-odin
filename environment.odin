package monkey

Environment :: struct {
	store: map[string]ObjectBase,
	outer: ^Environment,
	// methods
	get:   proc(env: ^Environment, name: string) -> (ObjectBase, bool),
	set:   proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase,
	free:  proc(env: ^Environment),
}

Env__New__ :: proc(outer: ^Environment = nil) -> Environment {
	return {get = environment_get, set = environment_set, free = environment_free, outer = outer}
}

Env__Enclosed__ :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator := context.allocator,
) -> ^Environment {
	env := Env__New__(outer)
	env.store = make(map[string]ObjectBase, reserved, allocator)
	return new_clone(env, allocator)
}

@(private = "file")
environment_free :: proc(env: ^Environment) {
	delete(env.store)
}

@(private = "file")
environment_get :: proc(env: ^Environment, name: string) -> (ObjectBase, bool) {
	obj, ok := env.store[name]
	if !ok && env.outer != nil {obj, ok = env.outer->get(name)}

	return obj, ok
}

@(private = "file")
environment_set :: proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase {
	env.store[name] = value
	return value
}


