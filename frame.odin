package monkey

Frame :: struct {
	instructions: []byte,
	ip:           int,
	base_pointer: int,
}
frame :: proc(instructions: []byte, base_pointer: int) -> Frame {
	return Frame{instructions, -1, base_pointer}
}

