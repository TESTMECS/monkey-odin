//%Usage{
// ```odin
// main :: proc() {
//     using m := Simple_Mem_Manager{}
//     err := mem_manager_init(&m)
//     if err != .None {
//         panic("Failed to initialize memory manager")
//     }
//
//     arr := mem_alloc(&m, [dynamic]int)
//     append(arr, 1, 2, 3)
//
//     // Track it if you want to free elements manually later
//     mem_register(&m, arr)
//
//     m.string_builder.write_string("Hello from internal builder\n")
//
//     // ... do work ...
//
//     mem_manager_reset(&m) // frees everything at once
// }}```
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
}
//{{"Initialize the manager"}}
MM_New :: proc(m: ^VArena, reserved: uint = 1 * mem.Megabyte) -> mem.Allocator_Error {
	err := vmem.arena_init_growing(&m.arena, reserved)
	if err != .None {
		return err
	}

	m.allocator = vmem.arena_allocator(&m.arena)

	m.string_builder = st.builder_make(m.allocator)
	m.registry = make([dynamic]rawptr, 0, 32, m.allocator)

	return .None
}
//{{"Allocate any type from this arena"}}
MemAlloc :: proc(m: ^VArena, $T: typeid) -> ^T {
	return new(T, m.allocator)
}
//%desc{{"Register something manually (optional, for cleanup tracking)"}}
MemRegister :: proc(m: ^VArena, ptr: rawptr) {
	append(&m.registry, ptr)
}
//%desc{{"Reset the entire memory pool (destroys everything allocated inside)"}}
MemMangerReset :: proc(m: ^VArena) {
	delete(m.registry)
	m.registry = {}

	vmem.arena_destroy(&m.arena)
	m.arena = {}
	m.allocator = {}
	m.string_builder = {}
}

