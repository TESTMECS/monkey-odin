#!/usr/bin/env monkey-odin -- from_shebang1 from_shebang2

puts("=== Args Demo ===");
puts("Arguments from args():");
let all_args = args();
puts(all_args);

puts("");
puts("Argument count: " + str(len(all_args)));

puts("");
puts("Individual arguments:");
for i in 0 ..< len(all_args) {
  puts("  arg[" + str(i) + "] = " + all_args[i]);
}

puts("");
puts("=== Demo Complete ===");