package monkey

import "core:fmt"
import "core:mem"
import "core:reflect"
import "core:strings"

Frame :: struct
{
	instructions: []byte,
	ip:           int,
	base_pointer: int,
}

frame :: proc(instructions: []byte, base_pointer: int) -> Frame
{
	return Frame{instructions, -1, base_pointer}
}

STACK_SIZE :: 2048

GLOBALS_SIZE :: 65536

MAX_FRAMES :: 1024

DEBUG_VM :: false

VM :: struct
{
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

Vm_New :: proc(bytecode: Bytecode, compiler_state: ^Compiler_State, varena: mem.Allocator) -> VM
{
	vm := VM \
	{
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

run_vm :: proc(v: ^VM) -> (err: string)
{
	ip: int
	ins: []byte
	op: Opcode

	for v->current_frame().ip < len(v->current_frame().instructions) - 1
	{
		v->current_frame().ip += 1

		ip = v->current_frame().ip
		ins = v->current_frame().instructions
		op = Opcode(ins[ip])

		switch op
		{
		case .New_Instance:
			class_obj := v->pop_vm()
			#partial switch &cls in class_obj


			
			{
			case ObjectClass:
				// Create new instance with empty fields
				fields := make(ObjectHashTable)
				instance := new(ObjectInstance, v.varena)
				instance^ = ObjectInstance \
				{
					class  = &cls,
					fields = fields,
				}
				if err = v->push_vm(instance); err != "" do return
			case:
				err = fmt.sbprintf(&v.sb, "new instance: expected class, got %v", class_obj)
				return
			}
		case .Iter_Init:
			collection := v->pop_vm()
			#partial switch coll in collection


			
			{
			case ObjectArray:
				// Create iterator for array
				iter := ObjectIterator \
				{
					collection = &collection,
					index      = 0,
					is_array   = true,
				}
				if err = v->push_vm(iter); err != "" do return
			case ObjectHashTable:
				// Create iterator for hash table - extract keys first
				keys := make([dynamic]string, v.varena)
				for key, _ in coll
				{
					append(&keys, key)
				}
				iter := ObjectIterator \
				{
					collection = &collection,
					index      = 0,
					keys       = keys,
					is_array   = false,
				}
				if err = v->push_vm(iter); err != "" do return
			case:
				err = fmt.sbprintf(&v.sb, "iter init: unsupported type %v", collection)
				return
			}
		case .Iter_Next:
			iterator := v->stack_top()
			#partial switch iter in iterator


			
			{
			case ObjectIterator:
				has_next := false
				if iter.is_array
				{
					// Array iteration
					#partial switch arr in iter.collection^


					
					{
					case ObjectArray:
						has_next = iter.index < len(arr)
					}
				}
				 else
				{
					// Hash table iteration
					has_next = iter.index < len(iter.keys)
				}
				if err = v->push_vm(has_next); err != "" do return
			case:
				err = fmt.sbprintf(&v.sb, "iter next: expected iterator, got %v", iterator)
				return
			}
		case .Iter_Get:
			iterator := v->stack_top()
			#partial switch &iter in iterator


			
			{
			case ObjectIterator:
				value := ObjectBase(NULL)
				if iter.is_array
				{
					// Array iteration
					#partial switch &arr in iter.collection^


					
					{
					case ObjectArray:
						if iter.index < len(arr)
						{
							value = arr[iter.index]
							updated_iter := iter
							updated_iter.index += 1
							v.stack[v.sp - 1] = updated_iter
						}
					}
				}
				 else
				{
					// Hash table iteration
					// NOTE: only does Values, no support for `foreach k,v in d` , but can use `for k in keys(d)`
					#partial switch ht in iter.collection^


					
					{
					case ObjectHashTable:
						if iter.index < len(iter.keys)
						{
							key := iter.keys[iter.index]
							value = ht[key]
							updated_iter := iter
							updated_iter.index += 1
							v.stack[v.sp - 1] = updated_iter
						}
					}
				}
				// Push value (iterator stays on stack below the new value)
				if err = v->push_vm(value); err != "" do return
			case:
				err = fmt.sbprintf(&v.sb, "iter get: expected iterator, got %v", iterator)
				return
			}
		case .Set_Method:
			// Set a method on a class
			method_name_idx := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2
			method_name_obj := v.constants[method_name_idx]
			method_name, ok := method_name_obj.(string)
			if !ok
			{
				err = fmt.sbprintf(&v.sb, "set method: method name must be string")
				return
			}
			method := v->pop_vm()
			class_obj := v->pop_vm()
			#partial switch &cls in class_obj


			
			{
			case ObjectClass:
				cls.methods[method_name] = method
				if err = v->push_vm(method); err != "" do return
			case:
				err = fmt.sbprintf(&v.sb, "set method: expected class, got %v", class_obj)
				return
			}
		case .Super_Call:
			// Super method call - not implemented yet
			err = "super method calls not yet implemented"
			return
		case .Get_Field:
			// Get a field from an instance
			field_name_idx := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2

			field_name_obj := v.constants[field_name_idx]
			field_name, ok := field_name_obj.(string)

			if !ok
			{err = fmt.sbprintf(&v.sb, "get field: field name must be string"); return}
			instance := v->pop_vm()

			#partial switch inst in instance


			
			{
			case ^ObjectInstance:
				if value, exists := inst.fields[field_name]; exists
				{
					// if DEBUG_VM do fmt.printf("Iter_Get: pushing value %v, current sp=%d\n", value, v.sp)
					if err = v->push_vm(value); err != "" do return
					// if DEBUG_VM do fmt.printf("Iter_Get: after push, sp=%d, stack top=%v\n", v.sp, v->stack_top())
				}
				 else
				{
					// Field not found, return nil
					if err = v->push_vm(NULL); err != "" do return
				}
			case:
				err = fmt.sbprintf(&v.sb, "get field: expected instance, got %v", instance)
				return
			}
		case .Set_Field:
			// Set a field on an instance
			field_name_idx := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2

			field_name_obj := v.constants[field_name_idx]
			field_name, ok := field_name_obj.(string)
			if !ok
			{err = fmt.sbprintf(&v.sb, "set field: field name must be string"); return}

			value := v->pop_vm()
			instance := v->pop_vm()

			#partial switch inst in instance


			
			{
			case ^ObjectInstance:
				inst.fields[field_name] = value
				if err = v->push_vm(value); err != "" do return
			case:
				err = fmt.sbprintf(&v.sb, "set field: expected instance, got %v", instance)
				return
			}
		case .Get_Method:
			// Get a method from a class or instance
			method_name_idx := int(read_u16(ins[ip + 1:]))
			v->current_frame().ip += 2

			method_name_obj := v.constants[method_name_idx]
			method_name, ok := method_name_obj.(string)
			if !ok
			{err = fmt.sbprintf(&v.sb, "get method: method name must be string"); return}

			obj := v->pop_vm()
			// if DEBUG_VM do fmt.printf("DEBUG: Get_Method looking for '%s' on object %v (type %T)\n", method_name, obj, obj)

			if obj_class, ok := obj.(ObjectClass); ok
			{
				if method, method_ok := obj_class.methods[method_name]; method_ok
				{
					// For class method calls, push the method only, instance seperate
					if err = v->push_vm(method); err != "" do return
				}
				 else
				{
					if err = v->push_vm(NULL); err != "" do return
				}
			}
			 else if obj_instance, ok := obj.(^ObjectInstance); ok
			{
				class := obj_instance.class
				method_found := false
				for class != nil
				{
					if method, method_ok := class.methods[method_name]; method_ok
					{
						// For instance method calls, we need self as first parameter. So push the instance back, then the method
						if err = v->push_vm(obj_instance); err != "" do return // self
						if err = v->push_vm(method); err != "" do return // method
						method_found = true
						break
					}
					class = class.superclass // Handles lookup in superclasses when actually implemented, right now just breaks since super is nil
				}
				if !method_found
				{if err = v->push_vm(NULL); err != "" do return}
			}
			 else
			{
				err = fmt.sbprintf(&v.sb, "get method: expected class or instance, got %v", obj)
				return
			}
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
		case .SetIdx:
			value := v->pop_vm()
			index := v->pop_vm()
			operand := v->pop_vm()
			if err = v->exec_set_idx_expr(operand, index, value); err != "" do return
		case .Call:
			num_args := int(read_u8(ins[ip + 1:]))
			v->current_frame().ip += 1
			if err = v->exec_call(num_args); err != "" do return
		case .Ret_V:
			ret_val := v->pop_vm()
			if DEBUG_VM do fmt.printf("DEBUG: Ret_V returning %v (type %T)\n", ret_val, ret_val)
			frame := v->pop_frame()
			v.sp = frame.base_pointer - 1
			if err = v->push_vm(ret_val); err != "" do return
		case .Ret:
			frame := v->pop_frame()
			v.sp = frame.base_pointer - 1
			if err = v->push_vm(NULL); err != "" do return
		case .Eq, .Neq, .Gt, .Lt, .Gte, .Lte:
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
			if !object_is_truthy(cond)
			{
				v->current_frame().ip = pos - 1
			}
		case .Set_G:
			global_idx := read_u16(ins[ip + 1:])
			v->current_frame().ip += 2
			value := v->pop_vm()
			v.compiler_state.globals[global_idx] = value
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

stack_top :: proc(v: ^VM) -> ObjectBase
{
	if v.sp == 0 do return nil
	return v.stack[v.sp - 1]
}

current_frame :: proc(v: ^VM) -> ^Frame
{
	return &v.frames[v.frames_idx - 1]
}

push_vm :: proc(v: ^VM, obj: ObjectBase) -> (err: string)
{
	if v.sp >= STACK_SIZE
	{
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "stack overflow")
		return strings.to_string(v.sb)
	}
	v.stack[v.sp] = obj
	v.sp += 1
	return ""
}

pop_vm :: proc(v: ^VM) -> ObjectBase
{
	o := v.stack[v.sp - 1]
	v.sp -= 1
	return o
}

last_popped :: proc(v: ^VM) -> ObjectBase
{
	if v.sp < 0 do return nil
	return v.stack[v.sp]
}

exec_binary_op :: proc(v: ^VM, op: Opcode) -> (err: string)
{
	right := v->pop_vm()
	left := v->pop_vm()

	_, left_is_int := left.(int)
	_, right_is_int := right.(int)
	_, left_is_float := left.(f64)
	_, right_is_float := right.(f64)
	_, left_is_string := left.(string)
	_, right_is_string := right.(string)

	if left_is_int && right_is_int
	{
		return v->exec_binary_int_op(op, left.(int), right.(int))
	}
	 else if left_is_float && right_is_float
	{
		return v->exec_binary_float_op(op, left.(f64), right.(f64))
	}
	 else if left_is_int && right_is_float
	{
		// Promote int to float
		return v->exec_binary_float_op(op, f64(left.(int)), right.(f64))
	}
	 else if left_is_float && right_is_int
	{
		// Promote int to float
		return v->exec_binary_float_op(op, left.(f64), f64(right.(int)))
	}
	 else if left_is_string && right_is_string
	{
		return v->exec_binary_string_op(op, left.(string), right.(string))
	}
	strings.builder_reset(&v.sb)
	fmt.sbprintf(
		&v.sb,
		"unknown operator: '%s' for types '%v' and '%v'",
		op,
		reflect.union_variant_typeid(left),
		reflect.union_variant_typeid(right),
	)
	return strings.to_string(v.sb)
}

exec_binary_int_op :: proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string)
{
	result: int

	#partial switch op
	{
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

exec_binary_float_op :: proc(v: ^VM, op: Opcode, left: f64, right: f64) -> (err: string)
{
	result: f64

	#partial switch op
	{
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
		fmt.sbprintf(&v.sb, "unknown float infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_binary_string_op :: proc(v: ^VM, op: Opcode, left: string, right: string) -> (err: string)
{
	result: string

	#partial switch op
	{
	case .Add:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "%s%s", left, right)
		result = strings.clone(strings.to_string(v.sb), v.varena)
	case:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown string infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_compare_op :: proc(v: ^VM, op: Opcode) -> (err: string)
{
	right := v->pop_vm()
	left := v->pop_vm()

	right_val, right_is_int := right.(int)
	left_val, left_is_int := left.(int)
	right_val_f, right_is_float := right.(f64)
	left_val_f, left_is_float := left.(f64)

	if right_is_int && left_is_int
	{
		return v->exec_compare_int_op(op, left_val, right_val)
	}
	 else if right_is_float && left_is_float
	{
		return v->exec_compare_float_op(op, left_val_f, right_val_f)
	}
	 else if right_is_int && left_is_float
	{
		// Promote int to float
		return v->exec_compare_float_op(op, left_val_f, f64(right_val))
	}
	 else if right_is_float && left_is_int
	{
		// Promote int to float
		return v->exec_compare_float_op(op, f64(left_val), right_val_f)
	}
	#partial switch op
	{
	case .Eq:
		_, left_is_array := left.(ObjectArray)
		_, left_is_ht := left.(ObjectHashTable)
		_, left_is_builtin := left.(ObjectBuilinFunction)
		_, left_is_compiled := left.(ObjectCompiledFunction)
		_, left_is_function := left.(^ObjectFunction)
		_, left_is_string := left.(string)
		_, left_is_bool := left.(bool)
		_, left_is_macro := left.(ObjectMacro)
		_, left_is_quote := left.(ObjectQuote)

		if left_is_array ||
		   left_is_ht ||
		   left_is_builtin ||
		   left_is_compiled ||
		   left_is_function ||
		   left_is_macro ||
		   left_is_quote
		{
			return v->push_vm(false)
		}
		 else if left_is_string
		{
			return v->push_vm(left.(string) == right.(string))
		}
		 else if left_is_bool
		{
			return v->push_vm(left.(bool) == right.(bool))
		}
		 else if left_val_f, left_is_float := left.(f64); left_is_float
		{
			if right_val_f, right_is_float := right.(f64); right_is_float
			{
				return v->push_vm(left_val_f == right_val_f)
			}
			 else if right_val, right_is_int := right.(int); right_is_int
			{
				return v->push_vm(left_val_f == f64(right_val))
			}
		}
		 else if left_val, left_is_int := left.(int); left_is_int
		{
			if right_val_f, right_is_float := right.(f64); right_is_float
			{
				return v->push_vm(f64(left_val) == right_val_f)
			}
		}
		return v->push_vm(false)
	case .Neq:
		_, left_is_array := left.(ObjectArray)
		_, left_is_ht := left.(ObjectHashTable)
		_, left_is_builtin := left.(ObjectBuilinFunction)
		_, left_is_compiled := left.(ObjectCompiledFunction)
		_, left_is_function := left.(^ObjectFunction)
		_, left_is_string := left.(string)
		_, left_is_bool := left.(bool)
		_, left_is_macro := left.(ObjectMacro)
		_, left_is_quote := left.(ObjectQuote)

		if left_is_array ||
		   left_is_ht ||
		   left_is_builtin ||
		   left_is_compiled ||
		   left_is_function ||
		   left_is_macro ||
		   left_is_quote
		{
			return v->push_vm(false)
		}
		 else if left_is_string
		{
			return v->push_vm(left.(string) != right.(string))
		}
		 else if left_is_bool
		{
			return v->push_vm(left.(bool) != right.(bool))
		}
		 else if left_val_f, left_is_float := left.(f64); left_is_float
		{
			if right_val_f, right_is_float := right.(f64); right_is_float
			{
				return v->push_vm(left_val_f != right_val_f)
			}
			 else if right_val, right_is_int := right.(int); right_is_int
			{
				return v->push_vm(left_val_f != f64(right_val))
			}
		}
		 else if left_val, left_is_int := left.(int); left_is_int
		{
			if right_val_f, right_is_float := right.(f64); right_is_float
			{
				return v->push_vm(f64(left_val) != right_val_f)
			}
		}
		return v->push_vm(false)
	}
	strings.builder_reset(&v.sb)
	fmt.sbprintf(&v.sb, "unknown operator '%s' for types '%v' and '%v'", op, left, right)
	return strings.to_string(v.sb)
}

exec_compare_int_op :: proc(v: ^VM, op: Opcode, left: int, right: int) -> (err: string)
{
	result: bool
	#partial switch op
	{
	case .Eq:
		result = left == right
	case .Neq:
		result = left != right
	case .Gt:
		result = left > right
	case .Lt:
		result = left < right
	case .Gte:
		result = left >= right
	case .Lte:
		result = left <= right
	case:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown integer infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_compare_float_op :: proc(v: ^VM, op: Opcode, left: f64, right: f64) -> (err: string)
{
	result: bool
	#partial switch op
	{
	case .Eq:
		result = left == right
	case .Neq:
		result = left != right
	case .Gt:
		result = left > right
	case .Lt:
		result = left < right
	case .Gte:
		result = left >= right
	case .Lte:
		result = left <= right
	case:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "unknown float infix operator '%s'", op)
		return strings.to_string(v.sb)
	}
	return v->push_vm(result)
}

exec_not_op :: proc(v: ^VM) -> (err: string)
{
	o := v->pop_vm()
	#partial switch operand in o


	
	{
	case bool:
		return v->push_vm(!operand)
	case ObjectNil:
		return v->push_vm(true)
	case:
		return v->push_vm(false)
	}
}

exec_neg_op :: proc(v: ^VM) -> (err: string)
{
	o := v->pop_vm()
	operand, ok := o.(int)
	if !ok
	{
		operand_f, ok_f := o.(f64)
		if !ok_f
		{
			strings.builder_reset(&v.sb)
			fmt.sbprintf(&v.sb, "unknown operator: '-' on type '%v'", ObjectType(o))
			return strings.to_string(v.sb)
		}
		return v->push_vm(-operand_f)
	}
	return v->push_vm(-operand)
}

exec_idx_expr :: proc(v: ^VM, operand, index: ObjectBase) -> (err: string)
{
	// Check types using type assertions instead of ObjectType
	_, operand_is_array := operand.(ObjectArray)
	_, operand_is_ht := operand.(ObjectHashTable)
	_, index_is_int := index.(int)
	_, index_is_string := index.(string)

	if operand_is_array && index_is_int
	{
		return v->exec_arr_idx(operand.(ObjectArray), index.(int))
	}
	 else if operand_is_ht && index_is_string
	{
		return v->exec_ht_idx(operand.(ObjectHashTable), index.(string))
	}

	strings.builder_reset(&v.sb)
	fmt.sbprintf(
		&v.sb,
		"index operator not supported: operand type '%v', index type '%v'",
		reflect.union_variant_typeid(operand),
		reflect.union_variant_typeid(index),
	)
	return strings.to_string(v.sb)
}

exec_arr_idx :: proc(v: ^VM, arr: ObjectArray, index: int) -> (err: string)
{
	max := len(arr) - 1
	if index < 0 || index > max do return v->push_vm(NULL)
	return v->push_vm(arr[index])
}

exec_ht_idx :: proc(v: ^VM, ht: ObjectHashTable, key: string) -> (err: string)
{
	value, key_exists := ht[key]
	if !key_exists do return v->push_vm(NULL)
	return v->push_vm(value)
}

exec_call :: proc(v: ^VM, num_args: int) -> (err: string)
{
	if v.sp - 1 - int(num_args) < 0
	{
		err = "stack underflow in function call"
		return
	}

	callee_idx := v.sp - 1 - int(num_args)
	callee := v.stack[callee_idx]

	#partial switch fn in callee


	
	{
	case ObjectCompiledFunction:
		// Check for implicit self method call: p@foo()
		// Stack layout: [..., self, method, args...]
		is_method_call := false
		if fn.num_parameters == num_args + 1 && callee_idx > 0
		{
			if _, ok := v.stack[callee_idx - 1].(^ObjectInstance); ok
			{
				is_method_call = true
			}
		}

		if is_method_call
		{
			// It's a method call, arguments are not contiguous.
			// Rearrange stack to make them contiguous: [..., self, args...]
			for i in 0 ..< num_args
			{
				v.stack[callee_idx + i] = v.stack[callee_idx + 1 + i]
			}

			base_ptr := callee_idx - 1
			frame := frame(fn.instructions[:], base_ptr)
			v->push_frame(frame)
			v.sp = base_ptr + fn.num_locals

		}
		 else
		{
			// Regular function call, or method call with explicit self.
			if num_args != fn.num_parameters
			{
				strings.builder_reset(&v.sb)
				fmt.sbprintf(
					&v.sb,
					"number of passed arguments does not match the number of needed parameters, need='%d', got='%d'",
					fn.num_parameters,
					num_args,
				)
				return strings.to_string(v.sb)
			}
			// Arguments are already contiguous, starting after the function.
			base_ptr := callee_idx + 1
			frame := frame(fn.instructions[:], base_ptr)
			v->push_frame(frame)
			v.sp = base_ptr + fn.num_locals
		}
		return ""
	case ObjectBuilinFunction:
		args := make([dynamic]ObjectBase, 0, v.varena)
		// Extract arguments from stack
		for i := v.sp - int(num_args); i < v.sp; i += 1
		{
			append(&args, v.stack[i])
		}
		// Create a temporary evaluator-like interface for the builtin
		temp_evaluator := Evaluator \
		{
			varena = v.varena,
			sb     = v.sb,
			args   = v.compiler_state.cli_arguments,
		}
		// Call builtin function
		result, ok := fn(&temp_evaluator, args)
		if !ok
		{
			strings.builder_reset(&v.sb)
			fmt.sbprintf(&v.sb, "builtin function error: %v", result)
			return strings.to_string(v.sb)
		}
		// Pop function and arguments from stack
		v.sp -= int(num_args) + 1
		// Push result
		return v->push_vm(result)
	case ObjectMacro:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "macro '%v' was not expanded during compilation", callee)
		return strings.to_string(v.sb)
	case ObjectClass:
		// Class instantiation: Class(args) -> create new instance
		class_obj := callee.(ObjectClass)
		persistent_class := new(ObjectClass, v.varena)
		persistent_class^ = class_obj
		// Create new instance with empty fields
		fields := make(ObjectHashTable)
		instance_ptr := new(ObjectInstance, v.varena)
		instance_ptr^ = ObjectInstance \
		{
			class  = persistent_class,
			fields = fields,
		}
		// Pop arguments from stack (they're not used for basic instantiation)
		v.sp -= int(num_args)
		// Pop class object from stack
		v.sp -= 1
		// Push the new instance
		return v->push_vm(instance_ptr)
	case ObjectQuote:
		strings.builder_reset(&v.sb)
		fmt.sbprintf(
			&v.sb,
			"quote object encountered at runtime - should have been handled during compilation",
		)
		return strings.to_string(v.sb)
	}
	strings.builder_reset(&v.sb)
	fmt.sbprintf(&v.sb, "not a function: '%v'", ObjectType(callee))
	return strings.to_string(v.sb)
}

build_array :: proc(v: ^VM, start, end: int) -> ObjectBase
{
	elements := make(ObjectArray, 0, v.varena)

	for i := start; i < end; i += 1
	{
		append(&elements, v.stack[i])
	}
	return elements
}

build_hash_table :: proc(v: ^VM, start, end: int) -> (ObjectBase, string)
{
	ht := make(ObjectHashTable, (end - start) / 2, v.varena)

	for i := start; i < end; i += 2
	{
		key := v.stack[i]
		value := v.stack[i + 1]

		key_str, key_is_string := key.(string)
		if !key_is_string
		{
			strings.builder_reset(&v.sb)
			fmt.sbprintf(&v.sb, "key '%v' is not a string", key)
			return nil, strings.to_string(v.sb)
		}
		ht[strings.clone(key_str, v.varena)] = value
	}
	return ht, ""
}

pop_frame :: proc(v: ^VM) -> ^Frame
{
	v.frames_idx -= 1
	return &v.frames[v.frames_idx]
}

push_frame :: proc(v: ^VM, f: Frame)
{
	v.frames[v.frames_idx] = f
	v.frames_idx += 1
}

exec_set_idx_expr :: proc(v: ^VM, operand, index, value: ObjectBase) -> (err: string)
{
	_, operand_is_array := operand.(ObjectArray)
	_, operand_is_ht := operand.(ObjectHashTable)
	_, index_is_int := index.(int)
	_, index_is_string := index.(string)

	if operand_is_array && index_is_int
	{
		return v->exec_arr_set_idx(operand.(ObjectArray), index.(int), value)
	}
	 else if operand_is_ht && index_is_string
	{
		ht := operand.(ObjectHashTable)
		key_str := index.(string)
		ht[strings.clone(key_str, v.varena)] = value
		return v->push_vm(value)
	}

	strings.builder_reset(&v.sb)
	fmt.sbprintf(
		&v.sb,
		"set index operator not supported: operand type '%v', index type '%v'",
		reflect.union_variant_typeid(operand),
		reflect.union_variant_typeid(index),
	)
	return strings.to_string(v.sb)
}

exec_arr_set_idx :: proc(v: ^VM, arr: ObjectArray, index: int, value: ObjectBase) -> (err: string)
{
	max := len(arr) - 1
	if index < 0 || index > max
	{
		strings.builder_reset(&v.sb)
		fmt.sbprintf(&v.sb, "array index out of bounds: %d", index)
		return strings.to_string(v.sb)
	}
	arr[index] = value
	return v->push_vm(value)
}

