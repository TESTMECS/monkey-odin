package monkey
import "core:strings"
Symbol_Scope :: enum {
	Global,
	Local,
}

Symbol :: struct {
	name:  string,
	scope: Symbol_Scope,
	index: int,
}

Symbol_Table :: struct {
	store:   map[string]Symbol,
	outer:   ^Symbol_Table,
	//%methods
	free:    proc(table: ^Symbol_Table),
	define:  proc(table: ^Symbol_Table, name: string) -> Symbol,
	resolve: proc(table: ^Symbol_Table, name: string) -> (Symbol, bool),
	vmem:    VArena,
}

Symbol_Table__New__ :: proc(
	allocator := context.allocator,
	outer: ^Symbol_Table = nil,
) -> Symbol_Table {
	return Symbol_Table {
		store = make(map[string]Symbol, allocator),
		outer = outer,
		//%methods
		//%desc{{"frees the symbol table and all of its symbols"}}
		free = proc(table: ^Symbol_Table) {
			delete(table.store)
		},
		//%desc{{"defines a symbol in the symbol table and returns it"}}
		define = proc(table: ^Symbol_Table, name: string) -> Symbol {
			name_copied := strings.clone(name, table.vmem.allocator)
			scope: Symbol_Scope = .Global if table.outer == nil else .Local
			symbol := Symbol{name_copied, scope, len(table.store)}
			table.store[name_copied] = symbol
			return symbol
		},
		//%desc{{"resolves a symbol in the symbol table and returns it"}}
		resolve = proc(table: ^Symbol_Table, name: string) -> (Symbol, bool) {
			obj, ok := table.store[name]
			if !ok && table.outer != nil do return table.outer->resolve(name)
			return obj, ok
		},
		//%desc{{"returns the VArena used by the symbol table"}}
		vmem = VArena__New__(),
	}
}

