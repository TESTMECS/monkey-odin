#!/usr/bin/env monkey -- 

let arr = [1, 2, 3];
let arr2 = ["a", "b", "c"];

let map = map(arr2, arr); # {"a": 1, "b": 2, "c": 3}
puts(map);

let my_keys = keys(map);
puts(my_keys);

let my_values = values(map);
puts(my_values);

let my_has = has(map, "a");
puts(my_has);
