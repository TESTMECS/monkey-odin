#!/usr/bin/env monkey -- 10

let countTo = fn(n) {
	let count = 0
	foreach i in range(0, n, 1) {
		count = count + 1
		puts(count)
	}
}

countTo(10)
