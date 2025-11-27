test_dir := "./examples/"
exe := "./monkey-odin.out"
test_file := "arrow_call.monkey"
tree_sitter_parse_test_file := "./examples/demo.monkey"

default:
	@just --list
alias t := test
test:
	echo "Running test {{test_file}}"
	time {{exe}} file {{test_dir}}{{test_file}} 

alias b := build
build:
	time odin build ./src -out:monkey-odin.out

alias re := repl
repl:
	just build && {{exe}} repl

ast:
	echo "AST for {{test_file}}"
	just build && {{exe}} ast {{test_dir}}{{test_file}}

bytes:
	echo "Bytecode for {{test_file}}"
	just build && {{exe}} bytes {{test_dir}}{{test_file}}

alias ta := test-all
test-all:
	odin test ./tests -all-packages
	odin test ./tests/examples 

alias c := clean
clean:
	rm ./*.out
	rm ./*.bin

alias cp := commit-push
commit-push MSG:
	git add . && git commit -m "{{MSG}}" && git push

alias tsgen := tree-sitter-gen
tree-sitter-gen:
	tree-sitter generate

alias tstest := tree-sitter-test
tree-sitter-test:
	tree-sitter parse {{tree_sitter_parse_test_file}} 

