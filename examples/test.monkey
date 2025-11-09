#!/usr/bin/env monkey -- 


class Animal() {
	let speak = fn(self) {
		self.x = "me"
		puts("Animal sound");
	};
	let whoami = fn(self) {
		printf("I am who I am %s", self.x);
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


