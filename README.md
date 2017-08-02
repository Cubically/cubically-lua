# cubically-lua
A Cubically interpreter written in Lua.

### Usage
Import `cubically.lua`, `tables.lua`, and `cube.lua` into your project, then run this line of code:
```lua
require("cubically")
```
`Cubically` will be defined in the global table. Using the interpreter is easy:
```lua
local interpreter = Cubically.new([options]) -- Create a new instance of the interpreter
interpreter:exec(program) -- Execute a program on the interpreter
```
The interpreter's state is preserved between calls, so you could do this, for example:
```lua
-- Initialize the interpreter
local interpreter = Cubically.new({experimental = true})

-- Execute the program
interpreter:exec(program)

-- Show debugging information. Experimental mode must be activated for the debug info command used below.
print("===========")
print("Final state")
print("===========")
interpreter:exec("#") -- You can put any program here. This is an experimental command to show debugging info.
```

**Options:**
- `experimental` - Enables functionality that is not in the official spec.
  - Commands will be implicitly called if no arguments are supplied and they don't require arguments.
  - `>`, `<` - Greater than and less than variants of `=`
  - `(` - Defines a label that can be jumped back to. If any arguments are supplied, at least one of them must be truthy for this label to be jumped to.
  - `)` - Goto the most recent label that can be jumped to. If any arguments are supplied, at least one of them must be truthy for the instruction pointer to jump.
  - `#` - Print debugging information.
