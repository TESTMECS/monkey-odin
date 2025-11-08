package monkey
import "core:mem"

Environment :: struct
{
	store: map[string]ObjectBase,
	outer: ^Environment,
	get:   proc(env: ^Environment, name: string) -> (ObjectBase, bool),
	set:   proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase,
	free:  proc(env: ^Environment),
}

Env_New :: proc(outer: ^Environment = nil, allocator: mem.Allocator) -> Environment
{
	store_mem := make(map[string]ObjectBase, 0, allocator)

	return {
		get = environment_get,
		set = environment_set,
		free = environment_free,
		outer = outer,
		store = store_mem,
	}
}

Env_Enclosed :: proc(
	outer: ^Environment,
	reserved: uint,
	allocator: mem.Allocator,
) -> ^Environment
{
	env := Env_New(outer, allocator)
	env.store = make(map[string]ObjectBase, reserved, allocator)
	return new_clone(env, allocator)
}

@(private = "file")
environment_free :: proc(env: ^Environment)
{
	delete(env.store)
}

@(private = "file")
environment_get :: proc(env: ^Environment, name: string) -> (ObjectBase, bool)
{
	obj, ok := env.store[name]
	if !ok && env.outer != nil
	{obj, ok = env.outer->get(name)}

	return obj, ok
}

@(private = "file")
environment_set :: proc(env: ^Environment, name: string, value: ObjectBase) -> ObjectBase
{
	env.store[name] = value
	return value
}

