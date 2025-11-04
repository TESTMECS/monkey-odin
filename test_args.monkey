#!/usr/bin/env monkey-odin -- arg1 arg2 arg3

puts("Arguments received:");
let args_list = args();
for i in 0 ..< len(args_list) {
    puts("arg[" + str(i) + "] = " + args_list[i]);
}