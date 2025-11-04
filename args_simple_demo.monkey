#!/usr/bin/env monkey-odin -- from_shebang1 from_shebang2

puts("=== Args Demo ===");
puts("Arguments from args():");
let all_args = args();
puts(all_args);
puts("Count: " + str(len(all_args)));
puts("First arg: " + all_args[0]);
puts("Second arg: " + all_args[1]);
puts("=== Demo Complete ===");