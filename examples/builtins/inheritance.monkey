#!/usr/bin/env monkey

# Sub-Class ovverides super
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

# Sub-class inherits super methods.
class Cat(Animal) {
	let meow = fn(self) {
		puts("Cat meows");
	};
	let whoami = fn(self, name) {
		printf("I am %s", name);
	}
}
let cat = Cat();
cat@speak(); 
cat@meow();
# Super method DOES NOT override on parameters only name
cat@whoami("Whiskers"); # =>> I am Whiskers
cat@whoami("Whiskers", "Feline"); # =>> I am Feline
# cat@whoami("Whiskers", "Feline", "Cat"); # =>> error - too many parameters
# cat@whoami(); # error - no parameters
