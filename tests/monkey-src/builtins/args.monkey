#!/usr/bin/env monkey -- true "Donkey Kong" 1

puts(args());
puts(args()[0]);
puts(typeof(args()[0])); # str
puts(typeof(bool(args()[0]))); # bool

# Loop over arguments
let i = 0;
let a = args();
for ( i < len(a) ) {
	printf("arg:%d", a[i]);
}
