package monkey
import "core:mem"
import "core:strings"

Symbol_Scope :: enum
{
	Global,
	Local,
	Builtin,
}

Symbol :: struct
{
	name:  string,
	scope: Symbol_Scope,
	index: int,
}

Symbol_Table :: struct
{
	store:          map[string]Symbol,
	outer:          ^Symbol_Table,
	free:           proc(table: ^Symbol_Table),
	define:         proc(table: ^Symbol_Table, name: string, allocator: mem.Allocator) -> Symbol,
	define_builtin: proc(table: ^Symbol_Table, name: string, index: int),
	resolve:        proc(table: ^Symbol_Table, name: string) -> (Symbol, bool),
}

Symbol_Table_New :: proc(allocator: mem.Allocator, outer: ^Symbol_Table = nil) -> Symbol_Table
{
	return Symbol_Table {
		store = make(map[string]Symbol, allocator),
		outer = outer,
		free = proc(table: ^Symbol_Table)
		{
			delete(table.store)
		},
		define = proc(table: ^Symbol_Table, name: string, allocator: mem.Allocator) -> Symbol
		{
			name_copied := strings.clone(name, allocator)
			scope: Symbol_Scope = .Global if table.outer == nil else .Local
			symbol := Symbol{name_copied, scope, len(table.store)}
			table.store[name_copied] = symbol
			return symbol
		},
		define_builtin = proc(table: ^Symbol_Table, name: string, index: int)
		{
			name_copied := strings.clone(name, table.store.allocator)
			symbol := Symbol{name_copied, .Builtin, index}
			table.store[name_copied] = symbol
		},
		resolve = proc(table: ^Symbol_Table, name: string) -> (Symbol, bool)
		{
			obj, ok := table.store[name]
			if !ok && table.outer != nil do return table.outer->resolve(name)
			return obj, ok
		},
	}
}

