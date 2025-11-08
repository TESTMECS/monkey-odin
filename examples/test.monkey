#!/usr/bin/env monkey -- 1,2,3

class Point() {
	let new = fn(self, x, y) {
		self.x = x;
		self.y = y;
		return self;
	};
	let inspect = fn(self) {
		puts("Point:");
		puts(self.x);
		puts(self.y);
	};
	let hi = fn(self) {
		puts("hi");
	};
}

class Point3D(Point) {
	let new = fn(self, x, y, z) {
		self.x = x;
		self.y = y;
		self.z = z;
		return self;
	};
	let inspect = fn(self) {
		puts("Point3D:");
		puts(self.x);
		puts(self.y);
		puts(self.z);
	};
	let hi = fn(self, x) {
		puts("hi from Point3D");
		puts(x);
	};
}

let p = Point3D();
p@new(1, 2, 3);
p@hi(1);
