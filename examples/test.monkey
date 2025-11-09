#!/usr/bin/env monkey -- 1,2,3


class Animal() {
	let speak = fn(self, me) {
		# puts("Animal sound");
		# puts(me)
	};
}

let speak = fn(me) {
	puts("mememe");
	puts(me)
};

let a = "me";
let dog = Animal();
dog@speak(a);
speak(a);
