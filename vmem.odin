package monkey
import "base:runtime"
import "core:mem"
import "core:mem/virtual"
import "core:strings"
//%desc{{"A simple memory pool with an arena allocator and optional registry"}}
VArena :: struct {
	arena:          virtual.Arena,
	allocator:      runtime.Allocator,
	string_builder: strings.Builder,
	registered:     bool,
	//%methods
	init:           proc(m: ^VArena, reserved: uint = 1 * mem.Megabyte) -> mem.Allocator_Error,
	reset:          proc(m: ^VArena),
}
//%section public functions
//%desc{{"Returns a new VArena Obj"}}
@(require_results)
VArena__New__ :: proc() -> VArena {
	return VArena{init = vmem_init, reset = vmem_reset}
}
//{{"Allocate any type from this arena"}}
@(require_results)
Vmem__Alloc__ :: proc(m: ^VArena, $T: typeid) -> ^T {
	if !m.registered {
		panic("VmemAlloc: allocator is invalid (arena destroyed)")
	}
	ptr, err := virtual.new(&m.arena, T)
	if err != nil {
		panic("VArena Alloc failed")
	}
	return ptr
}
//%endsection
//%desc{{"Initialize the manager"}}
vmem_init :: proc(m: ^VArena, reserved: uint = 1 * mem.Megabyte) -> mem.Allocator_Error {
	err := virtual.arena_init_growing(&m.arena, reserved)
	if err != .None {
		return err
	}

	m.allocator = virtual.arena_allocator(&m.arena)

	m.string_builder = strings.builder_make(m.allocator)

	m.registered = true

	return .None
}
//%desc{{"Reset the entire memory pool (destroys everything allocated inside)"}}
vmem_reset :: proc(m: ^VArena) {
	virtual.arena_destroy(&m.arena)
	m.arena = {}
	m.allocator = {}
	m.string_builder = {}
	m.registered = false
}

