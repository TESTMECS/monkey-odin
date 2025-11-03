default: 
	@just --list --list-prefix ····

alias t := test
test:
	./monkey-odin file ./tests/monkey-src/five_plus_ten.monkey 

alias b := build
build :
	time odin build ./src -out:monkey-odin

alias r := run
run ARGS:
	./monkey-odin {{ARGS}}

