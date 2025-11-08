#!/usr/bin/env monkey -- hash upper lower split join

let str1 = "hello";
puts(hash(str1));

puts(lower("HELLO")) # hello

puts(upper("hello")) # HELLO

let arr = split("a, b, c", ",");

puts(arr);

puts(join(args(), " ")) # "hash upper lower split join"

let cap = match("hello monkey", "hello (.*)")
puts(cap); # =>> "monkey"

let new_str = replace("hello monkey", "hello (.*)", "BANANAS")
puts(new_str);

let test = contains("hello monkey", "monkey")
puts(test);
