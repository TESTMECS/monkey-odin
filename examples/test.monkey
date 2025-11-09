#!/usr/bin/env monkey -- 1,2,3

class Point() {
	let new = fn(self, x, y) {
		self.x = x;
		self.y = y;
	};
}

let p = Point();
p@new(1, 2);

let i = 0;
let a = [1, 2, 3, 4, 5];
for( i < len(a) ) {
	 a[i] = a[i] * 2;
   i = i + 1
}


