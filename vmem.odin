package monkey
import "core:mem"
import vmem "core:mem/virtual"
import st "core:strings"
//%desc{{"A simple memory pool with an arena allocator and optional registry"}}
VArena :: struct {
	//%desc{{"Areana stores the allocations"}}
	arena:          vmem.Arena,
	//%desc{{"Allocator is the reserved allocator for `@self`"}}
	allocator:      mem.Allocator,
	//%desc{{"string_builder for easier string building attached to `@self`"}}
	string_builder: st.Builder,
	//%desc{{"Optional: track dynamic arrays, maps, etc. for manual `free`"}}
	registry:       [dynamic]rawptr,
	registered:     bool,
}
//{{"Initialize the manager"}}
Vmem_New :: proc(m: ^VArena, reserved: uint = 1 * mem.Megabyte) -> mem.Allocator_Error {
	err := vmem.arena_init_growing(&m.arena, reserved)
	if err != .None {
		return err
	}

	m.allocator = vmem.arena_allocator(&m.arena)

	m.string_builder = st.builder_make(m.allocator)
	m.registry = make([dynamic]rawptr, 0, 32, m.allocator)
	m.registered = true

	return .None
}
//{{"Allocate any type from this arena"}}
//MemAlloc
VmemAlloc :: proc(m: ^VArena, $T: typeid) -> ^T {
	if !m.registered {
		panic("VmemAlloc: allocator is invalid (arena destroyed)")
	}
	return new(T, m.allocator)
}
//%desc{{"Register something manually (optional, for cleanup tracking)"}}
VmemRegister :: proc(m: ^VArena, ptr: rawptr) {
	append(&m.registry, ptr)
}
//%desc{{"Reset the entire memory pool (destroys everything allocated inside)"}}
VmemReset :: proc(m: ^VArena) {
	delete(m.registry)
	m.registry = {}

	vmem.arena_destroy(&m.arena)
	m.arena = {}
	m.allocator = {}
	m.string_builder = {}
	m.registered = false
}

