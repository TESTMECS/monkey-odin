default: 
	@just --list --list-prefix ····

alias t := test
test:
	./monkey-odin.out file ./tests/monkey-src/five_plus_ten.monkey 

alias b := build
build :
	time odin build ./src -out:monkey-odin.out

alias r := run
run ARGS:
	./monkey-odin.out {{ARGS}}

alias ta := test-all
test-all:
	odin test ./tests/compiler/
	odin test ./tests/vm/
	odin test ./tests/parser/
	odin test ./tests/lexer/
	odin test ./tests/codegen/
	odin test ./tests/evaluator/

alias c := clean
clean:
	rm ./*.out
	rm ./*.bin

