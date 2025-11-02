package monkey

import "core:fmt"
import "core:mem/virtual"
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
	compiler_state:         ^Compiler_State,
	constants:              []ObjectBase,
	frames:                 []Frame,
	frames_idx:             int,
	stack:                  []ObjectBase,
	sp:                     int, //Top of stack is sp-1
	vmem:                   ^virtual.Arena,
	sb:                     strings.Builder,
	free_vm:                proc(v: ^VM),
	run_vm:                 proc(v: ^VM) -> (err: string),
	stack_top:              proc(v: ^VM) -> ObjectBase,
	last_popped_stack_elem: proc(v: ^VM) -> ObjectBase,
	current_frame:          proc(v: ^VM) -> ^Frame,
	push_vm:                proc(v: ^VM, obj: ObjectBase) -> (err: string),
	pop_vm:                 proc(v: ^VM) -> ObjectBase,
	last_popped:            proc(v: ^VM) -> ObjectBase,
	exec_binary_op:         proc(v: ^VM, op: Opcode) -> (err: string),
	exec_binary_int_op:     proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string),
	exec_binary_string_op:  proc(v: ^VM, op: Opcode, left: string, right: string) -> (err: string),
	exec_compare_op:        proc(v: ^VM, op: Opcode) -> (err: string),
	exec_compare_int_op:    proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string),
	exec_not_op:            proc(v: ^VM) -> (err: string),
	exec_neg_op:            proc(v: ^VM) -> (err: string),
	exec_idx_expr:          proc(v: ^VM, operand, index: ObjectBase) -> (err: string),
	exec_arr_idx:           proc(v: ^VM, arr: ObjectArray, index: int) -> (err: string),
	exec_ht_idx:            proc(v: ^VM, ht: ObjectHashTable, key: string) -> (err: string),
	exec_call:              proc(v: ^VM, num_args: int) -> (err: string),
	build_array:            proc(v: ^VM, start, end: int) -> ObjectBase,
	build_hash_table:       proc(v: ^VM, start, end: int) -> (ObjectBase, string),
	pop_frame:              proc(v: ^VM) -> ^Frame,
	push_frame:             proc(v: ^VM, f: Frame),
}

Vm__New__ :: proc(bytecode: Bytecode, compiler_state: ^Compiler_State) -> VM {
	v: ^virtual.Arena = new(virtual.Arena, context.allocator)
	arena_err := virtual.arena_init_growing(v)
	ensure(arena_err == nil)
	varena := virtual.arena_allocator(v)

	vm := VM {
		compiler_state        = compiler_state,
		stack                 = make([]ObjectBase, STACK_SIZE, varena),
		frames                = make([]Frame, MAX_FRAMES, varena),
		frames_idx            = 0,
		constants             = bytecode.constants,
		vmem                  = v,
		sb                    = strings.builder_make(varena),
		free_vm               = free_vm,
		run_vm                = run_vm,
		current_frame         = current_frame,
		push_vm               = push_vm,
		pop_vm                = pop_vm,
		last_popped           = last_popped,
		stack_top             = stack_top,
		exec_binary_op        = exec_binary_op,
		exec_binary_int_op    = exec_binary_int_op,
		exec_binary_string_op = exec_binary_string_op,
		exec_compare_op       = exec_compare_op,
		exec_compare_int_op   = exec_compare_int_op,
		exec_not_op           = exec_not_op,
		exec_neg_op           = exec_neg_op,
		exec_idx_expr         = exec_idx_expr,
		exec_arr_idx          = exec_arr_idx,
		exec_ht_idx           = exec_ht_idx,
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

run_vm :: proc(v: ^VM) -> (err: string) {
	ip: int
	ins: []byte
	op: Opcode

	for v->current_frame().ip < len(v->current_frame().instructions) - 1 {
		v->current_frame().ip += 1

		ip = v->current_frame().ip
		ins = v->current_frame().instructions
		op = Opcode(ins[ip])

		#partial switch op {
		case .Cnst:
			const_idx := read_u16(ins[ip + 1:])
			v->current_frame().ip += 2
			if err = v->push_vm(v.constants[const_idx]); err != "" do return
		case .Arr:
			num_elems := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2
			arr := v->build_array(v.sp - num_elems, v.sp)
			v.sp = v.sp - num_elems
			if err = v->push_vm(arr); err != "" do return
		case .Ht:
			num_elems := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2
			ht: ObjectBase
			if ht, err = v->build_hash_table(v.sp - num_elems, v.sp); err != "" do return
			v.sp = v.sp - num_elems
			if err = v->push_vm(ht); err != "" do return
		case .Add, .Sub, .Mul, .Div:
			if err = v->exec_binary_op(op); err != "" do return
		case .Idx:
			index := v->pop_vm()
			operand := v->pop_vm()
			if err = v->exec_idx_expr(operand, index); err != "" do return
		case .Call:
			num_args := int(read_u8(ins[ip + 1:]))
			v->current_frame().ip += 1
			if err = v->exec_call(num_args); err != "" do return
		case .Ret_V:
			ret_val := v->pop_vm()
			frame := v->pop_frame()
			v.sp = frame.base_pointer - 1
			if err = v->push_vm(ret_val); err != "" do return
		case .Ret:
			frame := v->pop_frame()
			v.sp = frame.base_pointer - 1
			if err = v->push_vm(NULL); err != "" do return
		case .Eq, .Neq, .Gt:
			if err = v->exec_compare_op(op); err != "" do return
		case .Not:
			if err = v->exec_not_op(); err != "" do return
		case .Neg:
			if err = v->exec_neg_op(); err != "" do return
		case .Jmp:
			pos := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip = pos - 1
		case .Jmp_If_Not:
			pos := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2

			cond := v->pop_vm()
			if !object_is_truthy(cond) {
				v->current_frame().ip = pos - 1
			}
		case .Set_G:
			global_idx := read_u16(ins[ip + 1:])
			v->current_frame().ip += 2
			v.compiler_state.globals[global_idx] = v->pop_vm()
		case .Get_G:
			global_idx := read_u16(ins[ip + 1:])
			v->current_frame().ip += 2
			if err = v->push_vm(v.compiler_state.globals[global_idx]); err != "" do return
		case .Set_L:
			local_idx := read_u8(ins[ip + 1:])
			v->current_frame().ip += 1
			frame := v->current_frame()
			v.stack[frame.base_pointer + int(local_idx)] = v->pop_vm()
		case .Get_L:
			local_idx := read_u8(ins[ip + 1:])
			v->current_frame().ip += 1
			frame := v->current_frame()
			if err = v->push_vm(v.stack[frame.base_pointer + int(local_idx)]); err != "" do return
		case .Nil:
			if err = v->push_vm(NULL); err != "" do return
		case .True:
			if err = v->push_vm(true); err != "" do return
		case .False:
			if err = v->push_vm(false); err != "" do return
		case .Pop:
			v->pop_vm()
		case:
			return
		}
	}
	return ""
}

free_vm :: proc(v: ^VM) {
	virtual.arena_destroy(v.vmem) // deallocates everything in the arena
	free(v.vmem, context.allocator) // deallocates the pointer to it.
}

stack_top :: proc(v: ^VM) -> ObjectBase {
	if v.sp == 0 do return nil
	return v.stack[v.sp - 1]
}

current_frame :: proc(v: ^VM) -> ^Frame {
	return &v.frames[v.frames_idx - 1]
}

push_vm :: proc(v: ^VM, obj: ObjectBase) -> (err: string) {
	if v.sp >= STACK_SIZE {
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "stack overflow")
		return strings.to_string(v.sb)
	}
	v.stack[v.sp] = obj
	v.sp += 1
	return ""
}

pop_vm :: proc(v: ^VM) -> ObjectBase {
	o := v.stack[v.sp - 1]
	v.sp -= 1
	return o
}

last_popped :: proc(v: ^VM) -> ObjectBase {
	return v.stack[v.sp]
}

exec_binary_op :: proc(v: ^VM, op: Opcode) -> (err: string) {
	right := v->pop_vm()
	left := v->pop_vm()

	if ObjectType(right) == int && ObjectType(left) == int {
		return v->exec_binary_int_op(op, left.(int), right.(int))
	} else if ObjectType(right) == string && ObjectType(left) == string {
		return v->exec_binary_string_op(op, left.(string), right.(string))
	}
	strings.builder_reset(&v.sb)
	fmt.sbprintf(
		&v.sb,
		"unknown operator: '%s' for types '%v' and '%v'",
		op,
		ObjectType(left),
		ObjectType(right),
	)
	return strings.to_string(v.sb)
}

exec_binary_int_op :: proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string) {
	result: int

	#partial switch op {
	case .Add:
		result = left + right
	case .Sub:
		result = left - right
	case .Mul:
		result = left * right
	case .Div:
		result = left / right
	case:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown integer infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_binary_string_op :: proc(v: ^VM, op: Opcode, left: string, right: string) -> (err: string) {
	varena := virtual.arena_allocator(v.vmem)
	result: string

	#partial switch op {
	case .Add:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "%s%s", left, right)
		result = strings.clone(strings.to_string(v.sb), varena)
	case:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown string infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_compare_op :: proc(v: ^VM, op: Opcode) -> (err: string) {
	right := v->pop_vm()
	left := v->pop_vm()

	right_val, right_is_int := right.(int)
	left_val, left_is_int := left.(int)

	if right_is_int && left_is_int {
		return v->exec_compare_int_op(op, left_val, right_val)
	}
	#partial switch op {
	case .Eq:
		switch ObjectType(left) {
		case ObjectArray,
		     ObjectHashTable,
		     ObjectBuilinFunction,
		     ObjectCompiledFunction,
		     ObjectFunction:
			break
		case string:
			if left.(string) == right.(string) do return v->push_vm(true)
		case bool:
			if left.(bool) == right.(bool) do return v->push_vm(true)
		}
	case .Neq:
		switch ObjectType(left) {
		case ObjectArray,
		     ObjectHashTable,
		     ObjectBuilinFunction,
		     ObjectCompiledFunction,
		     ObjectFunction:
			break
		case string:
			if left.(string) != right.(string) do return v->push_vm(true)
		case bool:
			if left.(bool) != right.(bool) do return v->push_vm(true)
		}
	}
	strings.builder_reset(&v.sb)
	fmt.sbprintf(&v.sb, "unknown operator '%s' for types '%v' and '%v'", op, left, right)
	return strings.to_string(v.sb)
}

exec_compare_int_op :: proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string) {
	result: bool
	#partial switch op {
	case .Eq:
		result = left == right
	case .Neq:
		result = left != right
	case .Gt:
		result = left > right
	case:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown integer infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_not_op :: proc(v: ^VM) -> (err: string) {
	o := v->pop_vm()
	#partial switch operand in o {
	case bool:
		return v->push_vm(!operand)
	case ObjectNil:
		return v->push_vm(true)
	case:
		v->push_vm(false)
	}
	unreachable()
}

exec_neg_op :: proc(v: ^VM) -> (err: string) {
	o := v->pop_vm()
	operand, ok := o.(int)
	if !ok {
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown operator: '-' on type '%v'", ObjectType(o))
		return strings.to_string(v.sb)
	}
	return v->push_vm(-operand)
}

exec_idx_expr :: proc(v: ^VM, operand, index: ObjectBase) -> (err: string) {
	if ObjectType(operand) == ObjectArray && ObjectType(index) == int {
		return v->exec_arr_idx(operand.(ObjectArray), index.(int))
	} else if ObjectType(operand) == ObjectHashTable && ObjectType(index) == string {
		return v->exec_ht_idx(operand.(ObjectHashTable), index.(string))
	}

	strings.builder_reset(&v.sb)
	fmt.sbprintf(&v.sb, "index operator does not support: '%v'", ObjectType(operand))
	return strings.to_string(v.sb)
}

exec_arr_idx :: proc(v: ^VM, arr: ObjectArray, index: int) -> (err: string) {
	max := len(arr) - 1
	if index < 0 || index > max do return v->push_vm(NULL)
	return v->push_vm(arr[index])
}

exec_ht_idx :: proc(v: ^VM, ht: ObjectHashTable, key: string) -> (err: string) {
	value, key_exists := ht[key]
	if !key_exists do return v->push_vm(NULL)
	return v->push_vm(value)
}

exec_call :: proc(v: ^VM, num_args: int) -> (err: string) {
	fn, ok := v.stack[v.sp - 1 - int(num_args)].(ObjectCompiledFunction)

	if !ok {
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "not a function: '%v'", ObjectType(v.stack[v.sp - 1 - int(num_args)]))
		return strings.to_string(v.sb)
	}

	if num_args != fn.num_parameters {
		strings.builder_reset(&v.sb)
		fmt.sbprintf(
			&v.sb,
			"number of passed arguments does not match the number of needed parameters, need='%d', got='%d'",
			fn.num_parameters,
			num_args,
		)
		return strings.to_string(v.sb)
	}

	frame := frame(fn.instructions[:], v.sp - num_args)
	v->push_frame(frame)
	v.sp = frame.base_pointer + fn.num_locals
	return ""
}

build_array :: proc(v: ^VM, start, end: int) -> ObjectBase {
	varena := virtual.arena_allocator(v.vmem)
	elements := make(ObjectArray, end - start, varena)

	for i := start; i < end; i += 1 {
		append(&elements, v.stack[i])
	}
	return elements
}

build_hash_table :: proc(v: ^VM, start, end: int) -> (ObjectBase, string) {
	varena := virtual.arena_allocator(v.vmem)
	ht := make(ObjectHashTable, (end - start) / 2, varena)

	for i := start; i < end; i += 2 {
		key := v.stack[i]
		value := v.stack[i + 1]

		key_str, key_is_string := key.(string)
		if !key_is_string {
			strings.builder_reset(&v.sb)
			fmt.sbprintf(&v.sb, "key '%v' is not a string", key)
			return nil, strings.to_string(v.sb)
		}
		ht[strings.clone(key_str, varena)] = value
	}
	return ht, ""
}

pop_frame :: proc(v: ^VM) -> ^Frame {
	v.frames_idx -= 1
	return &v.frames[v.frames_idx]
}

push_frame :: proc(v: ^VM, f: Frame) {
	v.frames[v.frames_idx] = f
	v.frames_idx += 1
}

