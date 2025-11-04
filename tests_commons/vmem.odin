package test_commons
import "core:mem/virtual"

Vmem :: struct {
	a:    ^virtual.Arena,
	free: proc(this: ^Vmem),
}

new_vmem :: proc() -> Vmem {
	arena: ^virtual.Arena = new(virtual.Arena, context.allocator)
	err := virtual.arena_init_growing(arena)
	ensure(err == nil)

	return Vmem{a = arena, free = proc(this: ^Vmem) {
			virtual.arena_destroy(this.a)
			free_all(context.allocator)
		}}
}

