#!/usr/bin/env monkey -- 1,2,3

class Point3d {
	let new = fn(self, x, y, z) {
		self.x = x;
		self.y = y;
		self.z = z;
		return self;
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
		return self;
	};
	let add = fn(self, other) {
		puts("adding");
		puts(other.x)
		self.x = self.x + other.x;
		self.y = self.y + other.y;
	};
};

# Instantiation
let p = Point2d();
p@new(1, 2);
puts("p created");
# p@inspect(); # should get superclass methods
# let p2 = Point2d();
# p2@new(1, 2);
# p@add(p2);
# p@inspect();

