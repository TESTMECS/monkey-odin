#!/usr/bin/env monkey -- brainfuck

let fill = fn(x, i) {
	let xs = [];
	for (i > 0) {
		xs = push(xs, x);
		i = i - 1;
	}
	return xs;
};
# let my_xs = fill(1,10);

buildJumpMap = fn(program) {
	stack = [];
	my_map = {};

	n = 0;
	for (n < len(program)) {
		if (program[n] == "[") {
			stack = push(stack, n);
		}
		if (program[n] == "]") {
			start = pop(stack);
			my_map[start] = n;
			my_map[n] = start;
		}
		n = n + 1;
	}
	return my_map;
}




