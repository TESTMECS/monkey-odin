#!/usr/bin/env monkey -- 1,2,3,4,5
let nums = arr(args()[0])

let filter_f = fn(arr, f) {
	let out = []
	foreach x in arr {
		if (f(int(x))) {
			out = push(out, x)
		}
	}
	out
}
let is_even = fn(x) {
	let n = x
	for (n >= 2) {
		n = n - 2
	}
	n == 0
}

let res = filter_f(nums, is_even);
printf("Even input arr: %v", res)
