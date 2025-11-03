test:
	./monkey-odin file ./tests/monkey-src/puts.monkey 

build:
	odin build ./src -out:monkey-odin


run ARGS:
	./monkey-odin {{ARGS}}



