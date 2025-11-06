# Monkey.
WIP Compiler impl for the Monkey programming language.

# demo.monkey 
```monkey
#!/usr/bin/env monkey -- 1,2,3 T 24

# io
let arr = args(); # =>>["1", "2", "3"]
printf("args[1]='%d'", int(args()[2]));

# types
let my_num = 12;
let my_float = 12.0;
let bool = bool(args()[1]);

# str
let my_str = "monkey BANANAS";
let my_str2 = upper(my_str);
let my_str3 = lower(my_str2);
puts(split(my_str3, " ")); # =>>["monkey", "BANANAS"]

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

# map
let map = map(arr2, my_arr); # {"a": 1, "b": 2, "c": 3}
let my_keys = keys(map); # =>["a", "b", "c"]
let my_values = values(map); # =>[1, 2, 3]
let my_has = has(map, "a"); # =>true

# math
let my_rand = rand();
let my_hash = hash(my_str);

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
puts(fibonacci(5));

# macros
let check_positive = macro(x) {
	quote(if (unquote(x) > 0) { puts("positive") } else { puts("zero or negative") })
}
check_positive(5);                   # prints: positive  
check_positive(0);                   # prints: zero or negative

# loops
let i = 0;
let a = [1, 2, 3, 4, 5];
for( i < len(a) ) {
	 a[i] = a[i] * 2;
   i = i + 1
}
puts(a);
```

