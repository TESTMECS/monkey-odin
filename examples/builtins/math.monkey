#!/usr/bin/env monkey -- -420 69 100 101 329 

let my_num = abs(int(args()[0]));
puts(my_num);

let my_rand = rand();
printf("My rand='%d'", my_rand);

let my_arr = args();
printf("random choice='%d'", int(choose(my_arr)));
