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
	compiler_state:         ^Compiler_State,
	frames:                 ^[MAX_FRAMES]Frame,
	frames_idx:             int,
	stack:                  ^[]ObjectBase,
	sp:                     int, //Top of stack is sp-1
	vmem:                   VArena,
	//%methods
	run:                    proc(v: ^VM) -> (err: string),
	stack_top:              proc(v: ^VM) -> ObjectBase,
	last_popped_stack_elem: proc(v: ^VM) -> ObjectBase,
	current_frame:          proc(v: ^VM) -> ^Frame,
	push:                   proc(v: ^VM, obj: ObjectBase) -> (err: string),
	pop:                    proc(v: ^VM) -> ObjectBase,
	last_popped:            proc(v: ^VM) -> ObjectBase,
	//%method{%desc{{"exec functions"}}}
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

Vm__New__ :: proc(allocator := context.allocator) -> VM {
	//%section vm functions
	return VM {
		//%method{run::proc(v::^VM) -> (err::string)}
		run = run_vm,
		//%method{current_frame::proc(v::^VM) -> ^Frame}
		current_frame = proc(v: ^VM) -> ^Frame {
			return &v.frames[v.frames_idx - 1]
		},
		//%method{push::proc(v::^VM, obj::ObjectBase)}
		push = proc(v: ^VM, obj: ObjectBase) -> (err: string) {
			if v.sp >= STACK_SIZE {
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(sb, "stack overflow")
				return strings.to_string(sb^)
			}
			v.stack[v.sp] = obj
			v.sp += 1
			return ""
		},
		//%method{pop::proc(v::^VM) -> ObjectBase}
		pop = proc(v: ^VM) -> ObjectBase {
			o := v.stack[v.sp - 1]
			v.sp -= 1
			return o
		},
		//%method{last_popped::proc(v::^VM) -> ObjectBase}
		last_popped = proc(v: ^VM) -> ObjectBase {
			return v.stack[v.sp]
		},
		//%method{stack_top::proc(v::^VM) -> ObjectBase}
		stack_top = proc(v: ^VM) -> ObjectBase {
			if v.sp == 0 do return nil
			return v.stack[v.sp - 1]
		},
		//%method{exec_binary_op::proc(v::^VM, op:Opcode)->(err:string)}
		exec_binary_op = proc(v: ^VM, op: Opcode) -> (err: string) {
			right := v->pop()
			left := v->pop()

			if ObjectType(right) == int && ObjectType(left) == int {
				return v->exec_binary_int_op(op, left.(int), right.(int))
			} else if ObjectType(right) == string && ObjectType(left) == string {
				return v->exec_binary_string_op(op, left.(string), right.(string))
			}
			sb := &v.vmem.string_builder
			strings.builder_reset(sb)
			fmt.sbprintf(
				sb,
				"unknown operator: '%s' for types '%v' and '%v'",
				op,
				ObjectType(left),
				ObjectType(right),
			)
			return strings.to_string(sb^)
		},
		//%method{exec_binary_int_op::proc(v::^VM, op:Opcode, left:int, right:int)->(err:string)}
		exec_binary_int_op = proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string) {
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
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(sb, "unknown integer infix operator '%s'", op)
				return strings.to_string(sb^)
			}
			return v->push(result)
		},
		//%method{exec_binary_string_op::proc(v::^VM, op:Opcode, left:string, right:string)->(err:string)}
		exec_binary_string_op = proc(
			v: ^VM,
			op: Opcode,
			left: string,
			right: string,
		) -> (
			err: string,
		) {
			result: string

			#partial switch op {
			case .Add:
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(sb, "%s%s", left, right)
				result = strings.clone(strings.to_string(sb^), v.vmem.allocator)
			case:
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(sb, "unknown string infix operator '%s'", op)
				return strings.to_string(sb^)
			}
			return v->push(result)

		},
		//%method{exec_compare_op::proc(v::^VM, op:Opcode)->(err:string)}
		exec_compare_op = proc(v: ^VM, op: Opcode) -> (err: string) {
			right := v->pop()
			left := v->pop()

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
					if left.(string) == right.(string) do return v->push(true)
				case bool:
					if left.(bool) == right.(bool) do return v->push(true)
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
					if left.(string) != right.(string) do return v->push(true)
				case bool:
					if left.(bool) != right.(bool) do return v->push(true)
				}
			}
			sb := &v.vmem.string_builder
			strings.builder_reset(sb)
			fmt.sbprintf(sb, "unknown operator '%s' for types '%v' and '%v'", op, left, right)
			return strings.to_string(sb^)
		},
		//%method{exec_compare_int_op::proc(v::^VM, op:Opcode, left:int, right:int)->(err:string)}
		exec_compare_int_op = proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string) {
			result: bool
			#partial switch op {
			case .Eq:
				result = left == right
			case .Neq:
				result = left != right
			case .Gt:
				result = left > right
			case:
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(sb, "unknown integer infix operator '%s'", op)
				return strings.to_string(sb^)
			}
			return v->push(result)
		},
		//%method{exec_call::proc(v::^VM, function:ObjectBase)->(err:string)}
		exec_not_op = proc(v: ^VM) -> (err: string) {
			o := v->pop()
			#partial switch operand in o {
			case bool:
				return v->push(!operand)
			case ObjectNil:
				return v->push(true)
			case:
				v->push(false)
			}
			unreachable()
		},
		//%method{exec_neg_op::proc(v::^VM)->(err:string)}
		exec_neg_op = proc(v: ^VM) -> (err: string) {
			o := v->pop()
			operand, ok := o.(int)
			if !ok {
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(sb, "unknown operator: '-' on type '%v'", ObjectType(o))
				return strings.to_string(sb^)
			}
			return v->push(-operand)
		},
		//%method{exec_idx_expr::proc(v::^VM, operand:ObjectBase, index:ObjectBase)->(err:string)}
		exec_idx_expr = proc(v: ^VM, operand, index: ObjectBase) -> (err: string) {
			if ObjectType(operand) == ObjectArray && ObjectType(index) == int {
				return v->exec_arr_idx(operand.(ObjectArray), index.(int))
			} else if ObjectType(operand) == ObjectHashTable && ObjectType(index) == string {
				return v->exec_ht_idx(operand.(ObjectHashTable), index.(string))
			}

			sb := &v.vmem.string_builder
			strings.builder_reset(sb)
			fmt.sbprintf(sb, "index operator does not support: '%v'", ObjectType(operand))
			return strings.to_string(sb^)
		},
		//%method{exec_arr_idx::proc(v::^VM, arr:ObjectArray, index:int)->(err:string)}
		exec_arr_idx = proc(v: ^VM, arr: ObjectArray, index: int) -> (err: string) {
			max := len(arr) - 1
			if index < 0 || index > max do return v->push(NULL)
			return v->push(arr[index])
		},
		//%method{exec_ht_idx::proc(v::^VM, ht:ObjectHashTable, key:string)->(err:string)}
		exec_ht_idx = proc(v: ^VM, ht: ObjectHashTable, key: string) -> (err: string) {
			value, key_exists := ht[key]
			if !key_exists do return v->push(NULL)
			return v->push(value)
		},
		//%method{exec_call::proc(v::^VM, num_args:int)->(err:string)}
		exec_call = proc(v: ^VM, num_args: int) -> (err: string) {
			fn, ok := v.stack[v.sp - 1 - int(num_args)].(ObjectCompiledFunction)
			if !ok {
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(
					sb,
					"not a function: '%v'",
					ObjectType(v.stack[v.sp - 1 - int(num_args)]),
				)
				return strings.to_string(sb^)
			}
			if num_args != fn.num_parameters {
				sb := &v.vmem.string_builder
				strings.builder_reset(sb)
				fmt.sbprintf(
					sb,
					"number of passed arguments does not match the number of needed parameters, need='%d', got='%d'",
					fn.num_parameters,
					num_args,
				)
				return strings.to_string(sb^)
			}
			frame := frame(fn.instructions[:], v.sp - num_args)
			v->push_frame(frame)
			v.sp = frame.base_pointer + fn.num_locals
			return ""
		},
		//%method{build_array::proc(v::^VM, start:int, end:int)->ObjectBase}
		build_array = proc(v: ^VM, start, end: int) -> ObjectBase {
			elements := make(ObjectArray, end - start, v.vmem.allocator)

			for i := start; i < end; i += 1 {
				append(&elements, v.stack[i])
			}
			return elements
		},
		//%method{build_hash_table::proc(v::^VM, start:int, end:int)->(ObjectBase, string)}
		build_hash_table = proc(v: ^VM, start, end: int) -> (ObjectBase, string) {
			ht := make(ObjectHashTable, (end - start) / 2, v.vmem.allocator)

			for i := start; i < end; i += 2 {
				key := v.stack[i]
				value := v.stack[i + 1]

				key_str, key_is_string := key.(string)
				if !key_is_string {
					sb := &v.vmem.string_builder
					strings.builder_reset(sb)
					fmt.sbprintf(sb, "key '%v' is not a string", key)
					return nil, strings.to_string(sb^)
				}
				ht[strings.clone(key_str, v.vmem.allocator)] = value
			}
			return ht, ""
		},
		//%method{pop_frame::proc(v::^VM)->^Frame}
		pop_frame = proc(v: ^VM) -> ^Frame {
			v.frames_idx -= 1
			return &v.frames[v.frames_idx]
		},
		//%method{push_frame::proc(v::^VM, f:Frame)}
		push_frame = proc(v: ^VM, f: Frame) {
			v.frames[v.frames_idx] = f
			v.frames_idx += 1
		},
		//%endsection
	}
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
			if err = v->push(v.constants[const_idx]); err != "" do return
		case .Arr:
			num_elems := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2

			arr := v->build_array(v.sp - num_elems, v.sp)
			v.sp = v.sp - num_elems
			if err = v->push(arr); err != "" do return
		case .Ht:
			num_elems := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2

			ht: ObjectBase
			if ht, err = v->build_hash_table(v.sp - num_elems, v.sp); err != "" do return

			v.sp = v.sp - num_elems
			if err = v->push(ht); err != "" do return
		case .Add, .Sub, .Mul, .Div:
			if err = v->exec_binary_op(op); err != "" do return
		case .Idx:
			index := v->pop()
			operand := v->pop()
			if err = v->exec_idx_expr(operand, index); err != "" do return
		case .Call:
			num_args := int(read_u8(ins[ip + 1:]))
			v->current_frame().ip += 1
			if err = v->exec_call(num_args); err != "" do return
		case .Ret_V:
			ret_val := v->pop()
			frame := v->pop_frame()
			v.sp = frame.base_pointer - 1
			if err = v->push(ret_val); err != "" do return
		case .Ret:
			frame := v->pop_frame()
			v.sp = frame.base_pointer - 1
			if err = v->push(NULL); err != "" do return
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

			cond := v->pop()
			if !object_is_truthy(cond) {
				v->current_frame().ip = pos - 1
			}
		case .Set_G:
			global_idx := read_u16(ins[ip + 1:])
			v->current_frame().ip += 2
			v.compiler_state.globals[global_idx] = v->pop()
		case .Get_G:
			global_idx := read_u16(ins[ip + 1:])
			v->current_frame().ip += 2
			if err = v->push(v.compiler_state.globals[global_idx]); err != "" do return
		case .Set_L:
			local_idx := read_u8(ins[ip + 1:])
			v->current_frame().ip += 1
			frame := v->current_frame()
			v.stack[frame.base_pointer + int(local_idx)] = v->pop()
		case .Get_L:
			local_idx := read_u8(ins[ip + 1:])
			v->current_frame().ip += 1
			frame := v->current_frame()
			if err = v->push(v.stack[frame.base_pointer + int(local_idx)]); err != "" do return
		case .Nil:
			if err = v->push(NULL); err != "" do return
		case .True:
			if err = v->push(true); err != "" do return
		case .False:
			if err = v->push(false); err != "" do return
		case .Pop:
			v->pop()
		case:
			return
		}
	}
	return ""
}

