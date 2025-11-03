test:
	./monkey-odin file ./tests/monkey-src/five_plus_ten.monkey 

build:
	odin build ./src -out:monkey-odin


run ARGS:
	./monkey-odin {{ARGS}}



