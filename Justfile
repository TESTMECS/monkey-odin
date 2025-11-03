default: build test

test_dir := "./tests/monkey-src/"
exe := "./monkey-odin.out"
test_file := "puts.monkey"

alias t := test
test:
	{{exe}} file {{test_dir}}{{test_file}} 

alias b := build
build:
	time odin build ./src -out:monkey-odin.out

alias r := run
run ARGS:
	{{exe}} {{ARGS}}

alias ta := test-all
test-all:
	odin test ./tests -all-packages
	
alias c := clean
clean:
	rm ./*.out
	rm ./*.bin

