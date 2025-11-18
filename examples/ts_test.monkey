#!/usr/bin/env monkey -- 

let x = 1;
let my_fn = fn(x) {
	return x + 1;
}
my_fn->1;
puts("Hello World");
let a = [1,2,3];
let hm = {"a":1, "b":2};
foreach i in a {
	puts->i;
}
let i = 0;
let a = [1, 2, 3, 4, 5];
for( i < len(a) ) {
	 a[i] = a[i] * 2;
   i = i + 1
}

