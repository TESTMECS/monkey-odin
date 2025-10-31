package monkey

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"

STACK_SIZE :: 2048

GLOBALS_SIZE :: 65536

MAX_FRAMES :: 1024

VM :: struct {
	constants:              []ObjectBase,
	state:                  ^Compiler_State,
	frames:                 ^[MAX_FRAMES]Frame,
	frames_idx:             int,
	stack:                  ^[]ObjectBase,
	sp:                     int, //Top of stack is sp-1
	//%methods
	run:                    proc(v: ^VM) -> (err: string),
	stack_top:              proc(v: ^VM) -> ObjectBase,
	last_popped_stack_elem: proc(v: ^VM) -> ObjectBase,
	vmem:                   VArena,
}

