# default configuration
test_dir := "./examples/"
exe := "./monkey-odin.out"
test_file := "arrow_call.monkey"
ts_parse_test_file := "./examples/demo.monkey"

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
	just build && {{exe}} repl

ast:
	echo "AST for {{test_file}}"
	just build && {{exe}} ast {{test_dir}}{{test_file}}

bytes:
	echo "Bytecode for {{test_file}}"
	just build && {{exe}} bytes {{test_dir}}{{test_file}}

# for odin tests. 
alias ta := test-all
test-all:
	odin test ./tests -all-packages
	odin test ./tests/examples 
	
alias c := clean
clean:
	rm ./*.out
	rm ./*.bin

# git helper
alias cp := commit-push
commit-push MSG:
	git add . && git commit -m "{{MSG}}" && git push

alias tsgen := tree-sitter-gen
tree-sitter-gen:
	tree-sitter generate

alias tstest := tree-sitter-test
tree-sitter-test:
	tree-sitter parse {{ts_parse_test_file}} 

