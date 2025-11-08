class Animal() {
	let speak = fn(self) {
		puts("Animal sound");
	};
}

class Dog(Animal) {
	let speak = fn(self) {
		puts("Dog barks");
	};
}

let dog = Dog();
dog@speak();