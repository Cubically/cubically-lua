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
The interpreter's state is preserved between calls, so you can run programs in sections:
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
- `size` - The size of the cube (default is `3` for 3x3)
- `experimental` - Enables functionality that is not in the official spec.
  - `#` - Print debugging information.
  - `_` - Modulus
  - `s` - Bitwise right shift, or left if given a negative number
  - `"` - Bitwise AND
  - `|` - Bitwise OR
  - `` ` `` - Bitwise XOR
  - `n` - Set the notepad to `-arg`, or `-notepad` if no argument is specified
  - **Conditionals**
    - **This only applies if the experimental flag is set. For non-experimental conditionals, please refer to the official language specification.**
    - `{...}` - Explicit code block
    - `?` - Executes next command/block only if any argument evaluates to true or if there are no arguments. Also creates a block containing this command and the next command/block.
    - `!` - Executes next command/block only if code was just skipped due to a condition failing. If arguments are supplied and none of them evaluate to truthy, the next command/block will be skipped.
    - **Examples**
      - Print notepad only if notepad is truthy: `?6%6`
      - Execute code only if notepad is truthy or input is truthy, otherwise execute different code: `?67{...}!{...}`
      - Execute code only if notepad is truthy and input is truthy, otherwise execute different code if side 0 is truthy: `?6?7{...}!0{...}`
      - Execute code only if notepad is truthy, otherwise execute different code if input is truthy and side 0 is truthy, otherwise execute different code: `?6{...}!7?0{...}!{...}`
    - **Notes**
      - `?{...}!{...}` will execute the first code block, but not the second.
      - `!{...}` by itself will not execute the code block, regardless of the arguments supplied to `!` (if any).
      - `{...}` by itself will execute the code block.
      - `?6!{...}` is equivalent to `?6{}!{...}`. If notepad is truthy, then `!{...}` is evaluated and the block is skipped, but if notepad is falsy, then `{...}` is evaluated and the block is executed.
      - `!?6{...}` is equivalent to `!6{...}`.
    - **Notes on code blocks**
      - `{%6%7:7}` is a code block
      - `?6&` is a code block
      - `+510` is a code block
      - The code blocks in `+41?6{-3%7}!{-4%6}(%6-1)6` are:
        - `+41`
        - `?6{-3%7}`
          - `?6`
          - `{-3%7}`
            - `-3`
            - `%7`
        - `!`
        - `{-4%6}`
          - `-4`
          - `%6`
        - `(`
        - `%6`
        - `-1`
        - `)6`
