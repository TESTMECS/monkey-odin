#!/usr/bin/env monkey -- 1,2,3 true monkey-lang

puts(args()[0]);
printf("args[1]='%v'", args()[1]);

let arr_of_lines = split(str_of_file, "\n");

# Read and write
# let str_of_file = readf("tests.txt");

# let res = writef("tests.txt", "hello BANANAS")

# puts(res); # true


