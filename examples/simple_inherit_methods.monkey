class A() {
	let test = fn(self) {
		puts("A.test");
	};
}

class B(A) {
	let test2 = fn(self) {
		puts("B.test2");
	};
}

let b = B();
b@test2();
b@test();