#!/usr/bin/env monkey
let i = 0;
let a = [1, 2, 3, 4, 5];
for( i < len(a) ) {
	 a[i] = a[i] * 2;
   i = i + 1
}
puts(a);
