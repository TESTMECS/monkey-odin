package test_commons
import monkey "../src"
concat_instructions :: proc(s: []monkey.Instructions) -> monkey.Instructions {
	using monkey
	out := make(Instructions, 0, context.temp_allocator)
	for ins_slice in s do append(&out, ..ins_slice[:])
	return out
}

