# Monkey Compiler in Odin.
Compiler and interpreter for the Monkey programming language.
# Examples.
```monkey
# Closures
let add = fn(x,y) {
    x + y
}
add(1,2) # 3

# Macros
macro add(x,y) {
    x + y
}
let equation = quote(5+3)
add(unquote(equation),2) # 10 

# Floats
1.023 
# Arrays
[1,2,3]
# Hashmaps
{"a":1,"b":2}
# Bultins
prinf("%v", add(35,24))
prinf("First arg='%v'", str(args()[0]))
sort([100,520,23,1])
puts(rand())
```
## Kanban
---
| Backlog | In Progress | Important | Done |
| :--- | :---: | :---: | ---: |
| | | | 
| | Refactoring for readability | | |
| hash return string is bad | | | |
| add split function | | | |



# Features
## Bultins.



