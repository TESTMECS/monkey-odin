package monkey

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"

main :: proc() {
	evaluator := Evaluator__New__()
	defer evaluator->free()

	buf: [2048]byte
	reader: bufio.Reader
	bufio.reader_init_with_buf(&reader, os.stream_from_handle(os.stdin), buf[:])

	fmt.println("Monkey REPL. Type 'exit' to quit.")

	for {
		fmt.print(">> ")
		line, err := bufio.reader_read_string(&reader, '\n')
		if err != nil do break
		line = strings.trim_space(line)
		if line == "exit" do break

		p := Parser__New__(line)
		program := p->parse()
		if parser_has_error(p) {
			p->free()
			continue
		}

		result, ok := evaluator.eval(&evaluator, program, evaluator.vmem.allocator)
		p->free()
		if !ok {
			fmt.println("Error:", result)
		} else {
			sb := strings.builder_make(context.temp_allocator)
			defer strings.builder_destroy(&sb)
			obj := Object(result)
			ObjectInspect(obj, &sb)
			fmt.println(strings.to_string(sb))
		}
	}
}

