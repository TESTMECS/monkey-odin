#!/usr/bin/env monkey -- str True 42 3.14159265 1,2,3 a,b,c 

# Strings
let my_str = args()[0];
printf("typeof(my_str): %s", typeof(my_str));
# Booleans
let cond = bool(args()[1]);
if (cond) {
  # Integers
	let my_int = int(args()[2]);
	puts(my_int*10);
	# Floats
	let my_float = float(args()[3]);
	printf("The only digits of pi i know are %0.8f", my_float);
}
# Arrays
let my_arr = arr(args()[4]);
puts(typeof(my_arr));
let i = 0;
for ( i < len(my_arr) ) {
	let j = my_arr[i];
	let k = int(j)
	my_arr[i] = k + 1;
	i = i + 1;
}
puts(my_arr);
# Maps
let my_arr2 = arr(args()[5]);
let my_map = map(my_arr2, my_arr);
puts(my_map);







