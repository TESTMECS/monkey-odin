package monkey

import "core:mem"
import "core:strings"

Frame :: struct {
	instructions: []byte,
	ip:           int,
	base_pointer: int,
}

frame :: proc(instructions: []byte, base_pointer: int) -> Frame {
	return Frame{instructions, -1, base_pointer}
}

STACK_SIZE :: 2048

GLOBALS_SIZE :: 65536

MAX_FRAMES :: 1024

DEBUG_VM :: false

VM :: struct {
	varena:                 mem.Allocator,
	compiler_state:         ^Compiler_State,
	constants:              []ObjectBase,
	frames:                 []Frame,
	frames_idx:             int,
	stack:                  []ObjectBase,
	sp:                     int, //Top of stack is sp-1
	sb:                     strings.Builder,
	run_vm:                 proc(v: ^VM) -> (err: string),
	stack_top:              proc(v: ^VM) -> ObjectBase,
	last_popped_stack_elem: proc(v: ^VM) -> ObjectBase,
	current_frame:          proc(v: ^VM) -> ^Frame,
	push_vm:                proc(v: ^VM, obj: ObjectBase) -> (err: string),
	pop_vm:                 proc(v: ^VM) -> ObjectBase,
	last_popped:            proc(v: ^VM) -> ObjectBase,
	exec_binary_op:         proc(v: ^VM, op: Opcode) -> (err: string),
	exec_binary_int_op:     proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string),
	exec_binary_float_op:   proc(v: ^VM, op: Opcode, left: f64, right: f64) -> (err: string),
	exec_binary_string_op:  proc(v: ^VM, op: Opcode, left: string, right: string) -> (err: string),
	exec_compare_op:        proc(v: ^VM, op: Opcode) -> (err: string),
	exec_compare_int_op:    proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string),
	exec_compare_float_op:  proc(v: ^VM, op: Opcode, left: f64, right: f64) -> (err: string),
	exec_not_op:            proc(v: ^VM) -> (err: string),
	exec_neg_op:            proc(v: ^VM) -> (err: string),
	exec_idx_expr:          proc(v: ^VM, operand, index: ObjectBase) -> (err: string),
	exec_arr_idx:           proc(v: ^VM, arr: ObjectArray, index: int) -> (err: string),
	exec_ht_idx:            proc(v: ^VM, ht: ObjectHashTable, key: string) -> (err: string),
	exec_set_idx_expr:      proc(v: ^VM, operand, index, value: ObjectBase) -> (err: string),
	exec_arr_set_idx:       proc(
		v: ^VM,
		arr: ObjectArray,
		index: int,
		value: ObjectBase,
	) -> (
		err: string
	),
	exec_call:              proc(v: ^VM, num_args: int) -> (err: string),
	build_array:            proc(v: ^VM, start, end: int) -> ObjectBase,
	build_hash_table:       proc(v: ^VM, start, end: int) -> (ObjectBase, string),
	pop_frame:              proc(v: ^VM) -> ^Frame,
	push_frame:             proc(v: ^VM, f: Frame),
}

Vm_New :: proc(bytecode: Bytecode, compiler_state: ^Compiler_State, varena: mem.Allocator) -> VM {
	vm := VM {
		compiler_state        = compiler_state,
		stack                 = make([]ObjectBase, STACK_SIZE, varena),
		frames                = make([]Frame, MAX_FRAMES, varena),
		frames_idx            = 0,
		constants             = bytecode.constants,
		varena                = varena,
		sb                    = strings.builder_make(varena),
		run_vm                = run_vm,
		current_frame         = current_frame,
		push_vm               = push_vm,
		pop_vm                = pop_vm,
		last_popped           = last_popped,
		stack_top             = stack_top,
		exec_binary_op        = exec_binary_op,
		exec_binary_int_op    = exec_binary_int_op,
		exec_binary_float_op  = exec_binary_float_op,
		exec_binary_string_op = exec_binary_string_op,
		exec_compare_op       = exec_compare_op,
		exec_compare_int_op   = exec_compare_int_op,
		exec_compare_float_op = exec_compare_float_op,
		exec_not_op           = exec_not_op,
		exec_neg_op           = exec_neg_op,
		exec_idx_expr         = exec_idx_expr,
		exec_arr_idx          = exec_arr_idx,
		exec_ht_idx           = exec_ht_idx,
		exec_set_idx_expr     = exec_set_idx_expr,
		exec_arr_set_idx      = exec_arr_set_idx,
		exec_call             = exec_call,
		build_array           = build_array,
		build_hash_table      = build_hash_table,
		pop_frame             = pop_frame,
		push_frame            = push_frame,
	}
	main_frame := frame(bytecode.instructions[:], 0)
	vm.push_frame(&vm, main_frame)
	return vm
}

