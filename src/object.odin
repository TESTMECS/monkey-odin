package monkey
import "core:fmt"
import "core:reflect"
import "core:strings"
/*
* Copyright (C) 2025 TESTMEE
* ./object.odin
*/
NULL :: ObjectNil{}
ObjectNil :: struct {}
// Base Object union, includes nil.
ObjectBase :: union {
	int,
	f64,
	bool,
	string,
	ObjectNil,
	^ObjectFunction,
	ObjectBuilinFunction,
	ObjectArray,
	ObjectHashTable,
	ObjectCompiledFunction,
	ObjectMacro,
	ObjectQuote,
	ObjectIterator,
}
ObjectReturn :: distinct ObjectBase
// Union of base and return objects, includes nil.
Object :: union {
	ObjectBase,
	ObjectReturn,
}
ObjectFunction :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
	env:        ^Environment, // closure of values + map of string to values.
}
ObjectMacro :: struct {
	parameters: [dynamic]Ast_Identifier,
	body:       Ast_Block,
	env:        ^Environment,
}
ObjectQuote :: struct {
	node: Node,
}
// Map of string to ObjectBase
ObjectHashTable :: map[string]ObjectBase
// Array of ObjectBase, distinct for Hashable.
ObjectArray :: distinct [dynamic]ObjectBase
ObjectCompiledFunction :: struct {
	instructions:   Instructions, // List of bytes
	num_locals:     int,
	num_parameters: int,
}
ObjectIterator :: struct {
	collection: ^ObjectBase, // collection to iterate over
	index:      int, // index of current iteration
	keys:       [dynamic]string, // keys of collection
	is_array:   bool,
}
ToObjectBase :: proc {
	to_object_base_val,
	to_object_base_ptr,
}
@(private = "file")
to_object_base_val :: proc(obj: Object) -> ObjectBase {
	obj := obj
	return to_object_base_ptr(&obj)
}
@(private = "file")
to_object_base_ptr :: proc(obj: ^Object) -> ObjectBase {
	switch data in obj {
	case ObjectBase:
		return data
	case ObjectReturn:
		return ObjectBase(data)
	}
	unreachable()
}
object_is_truthy :: proc(obj: ObjectBase) -> bool {
	#partial switch o in obj {
	case bool:
		return o
	case ObjectNil:
		return false
	case:
		return true
	}
	unreachable()
}
ObjectIsReturn :: proc {
	object_is_return_ptr,
	object_is_return_val,
}
@(private = "file")
object_is_return_ptr :: proc(o: ^Object) -> bool {
	return reflect.union_variant_typeid(o^) == ObjectReturn
}
@(private = "file")
object_is_return_val :: proc(o: Object) -> bool {
	return reflect.union_variant_typeid(o) == ObjectReturn
}
ObjectType :: proc {
	object_type_val,
	object_type_ptr,
}
@(private = "file")
object_type_val :: proc(o: Object) -> typeid {
	return reflect.union_variant_typeid(ToObjectBase(o))
}
object_type_ptr :: proc(o: ^Object) -> typeid {
	return reflect.union_variant_typeid(ToObjectBase(o^))
}
// Display of the object.
ObjectInspect :: proc {
	object_inspect_ptr,
	object_inspect_val,
}
@(private = "file")
object_inspect_val :: proc(o: Object, sb: ^strings.Builder) {
	obj := o
	object_inspect_ptr(&obj, sb)
}
@(private = "file")
object_inspect_ptr :: proc(o: ^Object, sb: ^strings.Builder) {
	obj := o
	obj_base := ToObjectBase(obj)
	#partial switch data in obj_base {
	case bool, int, f64, string:
		fmt.sbprint(sb, data)
	case ObjectNil:
		fmt.sbprint(sb, "(null)")
	case ^ObjectFunction:
		fmt.sbprint(sb, "(function)")
	case ObjectBuilinFunction:
		fmt.sbprint(sb, "(builtin)")
	case ObjectArray:
		fmt.sbprint(sb, "[")
		for item, i in data {
			ObjectInspect(item, sb)
			if i < len(data) - 1 do fmt.sbprint(sb, ", ")
		}
		fmt.sbprint(sb, "]")
	case ObjectHashTable:
		fmt.sbprint(sb, "{ ")
		i := 0
		for key, value in data {
			fmt.sbprintf(sb, "%s:", key)
			ObjectInspect(value, sb)
			if i < len(data) - 1 do fmt.sbprint(sb, ", ")
			i += 1
		}
		fmt.sbprint(sb, " }")
	case ObjectCompiledFunction:
		fmt.sbprint(sb, "(compiled function)")
	case ObjectMacro:
		fmt.sbprint(sb, "(macro)")
	case ObjectQuote:
		fmt.sbprint(sb, "(quote)")
	}
}

