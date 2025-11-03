#!/usr/bin/env monkey

let a = args();

puts("Got");
puts(len(a));
puts("arguments");

let i = 0;
for( i < len(a) ) {
   puts( "\t", i, " " , a[i], "\n");
   i++
}

