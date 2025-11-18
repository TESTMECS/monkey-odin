#!/usr/bin/env monkey -- 1,2,3 T 24

# io
let arr = args(); 
printf("args[1]='%d'", int->args()[2]); # ARROW Functions take 1 argument
let str_of_file = readf->"tests.txt";
let res = writef("tests.txt", "hello BANANAS")

