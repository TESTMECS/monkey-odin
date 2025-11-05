package tests_examples

import monkey "../../src"
import test_commons "../../tests_commons"
import "core:log"
import "core:mem/virtual"
import os "core:os/os2"
import "core:strings"
import "core:testing"


EXAMPLES_DIR :: "./examples"

@(test)
test_main :: proc(t: ^testing.T) {
	using monkey
	using test_commons


	vmem := new_vmem()
	varena := virtual.arena_allocator(vmem.a)
	defer vmem->free()

	sb := strings.builder_make(varena)

	if !os.exists(EXAMPLES_DIR) {
		log.error("examples directory not found")
		return
	}

	w := os.walker_create_path(EXAMPLES_DIR)
	defer os.walker_destroy(&w)

	num_run := 0
	for info in os.walker_walk(&w) {
		_ = os.walker_error(&w) or_break
		if !strings.ends_with(info.name, ".monkey") {
			continue
		}
		file_str, _ := Monkey_Read_File(info.fullpath, &sb, varena)
		_ = Monkey_Run_String(file_str, &sb, false, varena, []string{""})
		num_run += 1
	}
	log.infof("ran %d examples", num_run)
}

