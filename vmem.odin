package monkey
import "base:runtime"
import "core:mem"
import "core:mem/virtual"
import "core:strings"

VArena :: struct {
	arena:          virtual.Arena,
	allocator:      runtime.Allocator,
	string_builder: strings.Builder,
	init:           proc(m: ^VArena, reserved: uint = 1 * mem.Megabyte) -> mem.Allocator_Error,
	reset:          proc(m: ^VArena),
}

@(require_results)
VArena__New__ :: proc() -> VArena {
	return VArena{init = vmem_init, reset = vmem_reset}
}

@(require_results)
Vmem_Alloc :: proc(m: ^VArena, $T: typeid) -> ^T {
	ptr, err := virtual.new(&m.arena, T)
	if err != nil {
		panic("VArena Alloc failed")
	}
	return ptr
}


vmem_init :: proc(m: ^VArena, reserved: uint = 1 * mem.Megabyte) -> mem.Allocator_Error {
	err := virtual.arena_init_growing(&m.arena, reserved)
	if err != .None {
		return err
	}

	m.allocator = virtual.arena_allocator(&m.arena)

	m.string_builder = strings.builder_make(m.allocator)

	return .None
}

vmem_reset :: proc(m: ^VArena) {
	virtual.arena_destroy(&m.arena)
	m.arena = {}
	m.allocator = {}
	m.string_builder = {}
}

