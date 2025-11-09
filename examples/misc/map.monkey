#!/usr/bin/env monkey -- 1,2,3,4,5

let nums = arr(args()[0])

let map_f = fn(arr, f) {
	let out = []
	foreach x in arr {
		out = push(out, f(int(x)))
	}
	return out
}

let sq = fn(x) {
	x * x
}

let res = map_f(nums, sq);
printf("Squared input arr: %v", res)


