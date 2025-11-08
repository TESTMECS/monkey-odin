#!/usr/bin/env monkey -- 1,2,3

let new_str = replace("hello monkey", "hello (.*)", "BANANAS")
puts(new_str);

let test = contains("hello monkey", "monkey")
puts(test);
