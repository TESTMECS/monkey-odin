#!/usr/bin/env monkey --

let arr = [1, 2, 3];
let arr2 = ["a", "b", "c"];

let map = map(arr2, arr); # {"a": 1, "b": 2, "c": 3}
puts(map);
