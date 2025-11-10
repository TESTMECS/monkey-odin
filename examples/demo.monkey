#!/usr/bin/env monkey -- 1,2,3 T 24

# io
let arr = args(); # =>>["1", "2", "3", "T", "24"]
printf("args[1]='%d'", int(args()[2]));
let str_of_file = readf("tests.txt");
let res = writef("tests.txt", "hello BANANAS")
# fn
let fibonacci = fn(x) {
  if (x == 0) {
    0
  } else {
    if (x == 1) {
      return 1;
    } else {
      fibonacci(x - 1) + fibonacci(x - 2);
    }
  }
};
fibonacci(5);

# for loops
let i = 0;
let a = [1, 2, 3, 4, 5];
for( i < len(a) ) {
	 a[i] = a[i] * 2;
   i = i + 1
}
a; #=>>[2, 4, 6, 8, 10]
# foreach loops
foreach i in [1,2,3,4] {
	puts(i);
}
let d = {"a": 1, "b": 2, "c": 3};
foreach k in reverse(keys(d)) {
	puts(k);
}
# macros
let check_positive = macro(x) {
	quote(if (unquote(x) > 0) { puts("positive") } else { puts("zero or negative") })
}
check_positive(5);                   # prints: positive  
check_positive(0);                   # prints: zero or negative

# types
let my_num = 12;
let my_float = 12.0;
let bool = bool(args()[1]);

# str
let my_str = "monkey BANANAS";
let my_str2 = upper(my_str);
let my_str3 = lower(my_str2);
puts(split(my_str3, " ")); # =>>["monkey", "BANANAS"]
# regex
let cap = match("hello monkey", "hello (.*)")
puts(cap); # =>> "monkey"

let new_str = replace("hello monkey", "hello (.*)", "BANANAS")
puts(new_str);

let test = contains("hello monkey", "monkey")
puts(test);

# arr
let my_arr = args(); # =>>["1", "2", "3"]
let arr2 = ["a", "b", "c"];
let my_num_arr = [1, 2, 3];
let v = slice(my_arr, 0, 2); # =>>["1", "2"]
indexOf(my_arr, "2"); # =>>1
sum(my_num_arr); # =>>6
min(my_num_arr); # =>>1
max(my_num_arr); # =>>3
puts(len(my_arr)); # =>>3
#
# map
let map = map(arr2, my_arr); # {"a": 1, "b": 2, "c": 3}
let my_keys = keys(map); # =>["a", "b", "c"]
let my_values = values(map); # =>[1, 2, 3]
let my_has = has(map, "a"); # =>true
#
# math
let my_rand = rand();
let my_hash = hash(my_str);
let my_sin = sin(float(0));
let my_cos = cos(float(0));
let my_tan = tan(float(0));

# Bitwise ops
let bor = 1 | 2; puts(bor);
let bxor = 1 ^ 2; puts(bxor);
let band = 1 & 2; puts(band);
let bnot = ~1; puts(bnot);

let mod = 1 % 2; puts(mod);
let brshift = 4 >> 2; puts(brshift);
let blshift = 1 << 2; puts(blshift);

let lor = true || false; puts(lor);
let land = true && false; puts(land);


