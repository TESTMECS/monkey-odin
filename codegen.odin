package monkey

import "core:encoding/endian"
import "core:fmt"
import "core:strings"

Instructions :: [dynamic]byte

Opcode :: enum byte {
	Cnst,
	Arr,
	Ht,
	Pop,
	Add,
	Sub,
	Mul,
	Div,
	Idx,
	Call,
	Ret_V,
	Ret,
	True,
	False,
	Eq,
	Neq,
	Gt,
	Neg,
	Not,
	Jmp_If_Not,
	Jmp,
	Nil,
	Get_G,
	Set_G,
	Get_L,
	Set_L,
}

Definition :: struct {
	name:           string,
	operand_widths: []int,
}

Definition__Map__ := [Opcode]Definition {
	.Cnst       = {"OpConstant", {2}},
	.Arr        = {"OpArray", {2}},
	.Ht         = {"OpHashTable", {2}},
	.Pop        = {"OpPop", {}},
	.Add        = {"OpAdd", {}},
	.Sub        = {"OpSub", {}},
	.Mul        = {"OpMul", {}},
	.Div        = {"OpDiv", {}},
	.Idx        = {"OpIndex", {}},
	.Call       = {"OpCall", {1}},
	.Ret_V      = {"OpReturnValue", {}},
	.Ret        = {"OpReturn", {}},
	.True       = {"OpTrue", {}},
	.False      = {"OpFalse", {}},
	.Eq         = {"OpEqual", {}},
	.Neq        = {"OpNotEqual", {}},
	.Gt         = {"OpGreaterThan", {}},
	.Neg        = {"OpNegate", {}},
	.Not        = {"OpNot", {}},
	.Jmp_If_Not = {"OpJumpIfNotTrue", {2}},
	.Jmp        = {"OpJump", {2}},
	.Nil        = {"OpNil", {}},
	.Get_G      = {"OpGetGlobal", {2}},
	.Set_G      = {"OpSetGlobal", {2}},
	.Get_L      = {"OpGetLocal", {1}},
	.Set_L      = {"OpSetLocal", {1}},
}

lookup :: proc(op: Opcode) -> (Definition, bool) {
	def := Definition__Map__[Opcode(op)]
	if def.name == "" do return Definition{}, false
	return def, true
}

make_instructions :: proc(
	op: Opcode,
	operands: ..int,
	allocator := context.allocator,
) -> Instructions {
	def, ok := lookup(op)
	if !ok do return {}

	inst_len := 1
	for w in def.operand_widths {
		inst_len += w
	}

	instruction := make(Instructions, inst_len, inst_len, allocator)
	instruction[0] = byte(op)

	offset := 1
	for o, i in operands {
		width := def.operand_widths[i]
		switch width {
		case 2:
			endian.put_u16(instruction[offset:], .Big, u16(o))
		case 1:
			instruction[offset] = byte(o)
		}
		offset += width
	}
	return instruction
}

@(private = "file")
format_instruction :: proc(sb: ^strings.Builder, def: Definition, operands: []int) {
	operand_count := len(def.operand_widths)

	if len(operands) != operand_count {
		fmt.sbprintf(
			sb,
			"invalid number of operands, expected='%d', got='%d'",
			operand_count,
			len(operands),
		)
		return
	}

	switch operand_count {
	case 0:
		fmt.sbprint(sb, def.name)
		return
	case 1:
		fmt.sbprintf(sb, "%s %d", def.name, operands[0])
		return
	}

	fmt.sbprintfln(sb, "ERROR: unhandled operand_count for %s", def.name)
}

instructions_to_string :: proc(
	instructions: Instructions,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	i := 0
	for i < len(instructions) {
		def, ok := lookup(Opcode(instructions[i]))
		if !ok {
			fmt.sbprintf(&sb, "unknown opcode '%d'", instructions[i])
			continue
		}
		operands, read := read_operands(def, instructions[i + 1:], allocator)
		fmt.sbprint(&sb, "%04d", i)
		format_instruction(&sb, def, operands)
		fmt.sbprintln(&sb)
		i += 1 + read
	}
	return strings.to_string(sb)
}

read_operands :: proc(
	def: Definition,
	instructions: []byte,
	allocator := context.allocator,
) -> (
	[]int,
	int,
) {
	operands := make([]int, len(def.operand_widths), allocator)
	offset := 0

	for width, i in def.operand_widths {
		switch width {
		case 2:
			operands[i] = int(read_u16(instructions[offset:]))
		case 1:
			operands[i] = int(read_u8(instructions[offset:]))
		}
		offset += width
	}
	return operands, offset
}

read_u16 :: proc(ins: []byte) -> u16 {
	res, _ := endian.get_u16(ins, .Big)

	return res
}

read_u8 :: proc(ins: []byte) -> u8 {
	return u8(ins[0])
}

