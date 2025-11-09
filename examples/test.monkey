#!/usr/bin/env monkey -- 1,2,3

let i = 0;
let a = [1, 2, 3, 4, 5];
for( i < len(a) ) {
	 a[i] = a[i] * 2;
   i = i + 1
}

class Animal() {
	let speak = fn(self) {
		puts("Animal sound");
	};
	let whoami = fn(self) {
		printf("I am who I am");
	}
}

class Dog(Animal) {
	let speak = fn(self) {
		puts("Dog barks");
	};
}

let dog = Dog();
dog@speak();
dog@whoami(); # =>> I am who I am


