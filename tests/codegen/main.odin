#+feature dynamic-literals
package codegen_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_code_make :: proc(t: ^testing.T) {
	using monkey
	tests := [?]struct {
		op:       Opcode,
		operands: [dynamic]int,
		expected: []byte,
	} {
		{.Cnst, {65534}, {u8(Opcode.Cnst), 255, 254}},
		{.Add, {}, {u8(Opcode.Add)}},
		{.Get_L, {1}, {u8(Opcode.Get_L), 1}},
	}

	defer free_all(context.allocator)

	for test_case, i in tests {
		instructions := make_instructions(
			context.temp_allocator,
			test_case.op,
			..test_case.operands[:],
		)
		if len(instructions) != len(test_case.expected) {
			log.errorf(
				" test [%d] has failed, instructions has wrong length. wants='%d', got='%d' ",
				i,
				len(test_case.expected),
				len(instructions),
			)
			continue
		}
		for b, idx in test_case.expected {
			if instructions[idx] != test_case.expected[idx] {
				log.errorf(
					" test [%d] has failed, instruction at index '%d' has wrong value. wants='%d', got='%d' ",
					i,
					idx,
					b,
					instructions[idx],
				)
				continue
			}
		}
	}
}

@(test)
test_instructions_string :: proc(t: ^testing.T) {
	using monkey
	instructions := [?]Instructions {
		make_instructions(context.allocator, .Add),
		make_instructions(context.allocator, .Get_L, 1),
		make_instructions(context.allocator, .Cnst, 2),
		make_instructions(context.allocator, .Cnst, 65535),
	}

	defer free_all(context.allocator)

	expected := `0000 OpAdd
0001 OpGetLocal 1
0003 OpConstant 2
0006 OpConstant 65535
`


	concatenated := concat_instructions(instructions[:])

	instructions_str := instructions_to_string(concatenated, context.allocator)

	if instructions_str != expected {
		log.errorf(
			"instruction wrongly formatted.\nwants='%s'\ngot='%s'",
			expected,
			instructions_str,
		)
		testing.fail(t)
	}
}

@(test)
test_read_operands :: proc(t: ^testing.T) {
	using monkey
	tests := []struct {
		op:         Opcode,
		operands:   []int,
		bytes_read: int,
	}{{.Cnst, {65535}, 2}, {.Get_L, {255}, 1}}

	defer free_all(context.allocator)

	for test_case, i in tests {
		instruction := make_instructions(context.allocator, test_case.op, ..test_case.operands)

		def, ok := lookup(test_case.op)
		if !ok {
			log.errorf("definition not found: %q", test_case.op)
			testing.fail(t)
			continue
		}

		operands_read, n := read_operands(def, instruction[1:], context.allocator)
		if n != test_case.bytes_read {
			log.errorf(
				"test[%d] has failed: n wrong. wants='%d', got='%d'",
				i,
				test_case.bytes_read,
				n,
			)
		}

		for want, b_idx in test_case.operands {
			if operands_read[b_idx] != want {
				log.errorf(
					"test[%d] has failed: operand wrong. wants='%d', got='%d'",
					i,
					want,
					operands_read[b_idx],
				)
				testing.fail(t)
			}
		}
	}
}

