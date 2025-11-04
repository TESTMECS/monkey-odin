# default configuration
test_dir := "./tests/monkey-src/"
exe := "./monkey-odin.out"
test_file := "builtins/args.monkey"

default: build test

# for file tests
alias t := test
test:
	echo "Running test {{test_file}}"
	time {{exe}} file {{test_dir}}{{test_file}} 

# just build
alias b := build
build:
	time odin build ./src -out:monkey-odin.out

# just run repl
alias re := repl
repl:
	just build && just run repl

# just run repl | file | mexpand
alias r := run
run ARGS:
	{{exe}} {{ARGS}}

# for odin tests. 
alias ta := test-all
test-all:
	odin test ./tests -all-packages
	
alias c := clean
clean:
	rm ./*.out
	rm ./*.bin

# git helper
alias cp := commit-push
commit-push MSG:
	git add . && git commit -m "{{MSG}}" && git push


