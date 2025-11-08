#!/usr/bin/env monkey -- 1,2,3

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
	let whoami = fn(self, name) {
		printf("I am %s", name);
	}
}

let d = Dog();
d@whoami("Buddy");
