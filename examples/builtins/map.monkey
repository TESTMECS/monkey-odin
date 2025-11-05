#!/usr/bin/env monkey -- 1,2,3 a,b,c 

let arr1 = args()[0];
let arr2 = args()[1];

let map = map(arr2, arr1); # {"a": 1, "b": 2, "c": 3}

let my_keys = keys(map); # =>["a", "b", "c"]
let my_values = values(map); # =>[1, 2, 3]

let my_has = has(map, "a"); # =>true
