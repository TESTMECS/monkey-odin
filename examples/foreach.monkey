#!/usr/bin/env monkey -- 1,2,3

foreach i in arr(args()[0]) {
	puts(i);
}

# Have to use this for keys
let d = {"a": 1, "b": 2, "c": 3};
foreach k in reverse(keys(d)) {
	puts(k);
}
