#!/usr/bin/env monkey -- 1,2,3 true Hello

let my_args = args();
let my_arr = arr(my_args[0]);
printf("First arg is=%v", my_arr);
