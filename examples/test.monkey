#!/usr/bin/env monkey -- 1,2,3

class Point3d {
	let new = fn(self, x, y, z) {
		self.x = x;
		self.y = y;
		self.z = z;
	};
	let add = fn(self, other) {
		self.x = self.x + other.x;
		self.y = self.y + other.y;
		self.z = self.z + other.z;
		return self;
	};
	let inspect = fn(self) {
		puts(self.x);
		puts(self.y);
		puts("printing z");
		puts(self.z);
	};
}

class Point2d(Point3d) {
	let new = fn(self, x, y) {
		self.x = x;
		self.y = y;
	};
	let add = fn(self, other) {
		self.x = self.x + other.x;
		self.y = self.y + other.y;
		return self;
	};
};

let p = Point2d().new(1,2);

p.inspect();

let res = p.add(Point2d().new(1,2)); # make sure we call the correct add method

puts(res);
