# cubically-lua [variant]
A Cubically interpreter written in Lua. This is a variant of Cubically.

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

### Options
- `size` - The size of the cube (default is `3` for 3x3)
- `experimental` - Enables functionality that is not in the official spec.
  - `#` - Print debugging information.
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

## Notepad
The notepad's value was changed from an integer type to a floating point type.

## Commands
### Cube manipulation
|Command|Description|
|---|---------------------------------|
|`R`|Rotates the right face `n` times |
|`L`|Rotates the left face `n` times  |
|`U`|Rotates the top face `n` times   |
|`D`|Rotates the bottom face `n` times|
|`F`|Rotates the front face `n` times |
|`B`|Rotates the back face `n` times  |

`n` is defaulted to 0 for each of these commands. You may use `'` as an alias for `3` to rotate counter-clockwise.

### Arithmetic
|Command|Description|
|---|---------------------------------|
|`+`|Adds `n` to the notepad|
|`-`|Subtracts `n` from the notepad|
|`×`|Muliplies the notepad by `n`|
|`÷`|Divides the notepad by `n`|
|`%`|Calculates the modulus between the notepad and `n` |
|`ⁿ`|Raises `n` (or notepad by default) to the power of the given index, or 2 by default|
|`√`|Calculates the `n`th root of the notepad, or 2 by default|
|'~'|Multiplies `n` by -1, default argument is notepad|
|`ṡ`|Caculates the sine of `n` degrees, or the notepad by default|
|`ċ`|Caculates the cosine of `n` degrees, or the notepad by default|
|`Ṡ`|Calculates the sine⁻¹ of `n`, or the notepad by default|
|`Ċ`|Calculates the cosine⁻¹ of `n`, or the notepad by default|

### Binary arithmetic
|Command|Description|
|---|---------------------------------|
|`&`|Adds `n` to the notepad|
|`|`|Subtracts `n` from the notepad|
|`^`|Muliplies the notepad by `n`|
|`¬`|Divides the notepad by `n`|
|`«`|Rotate the notepad left `n` times|
|`»`|Rotate the notepad right `n` times|

### I/O
|Command|Description|
|---|---------------------------------|
|`_`|Input the next character's ASCII value to face 7, or -1 if at end of input stream|
|`$`|Input the next number to face 7, or leave the input unchanged if there is no number value to take as input|
|`@`|Output the character with ASCII value `⌊n⌋`|
|`"`|Output the number `n`|

### Conditionals
Unchanged from normal Cubically

### Loops
Unchanged from normal Cubically

### Constant arguments vs. face-valued arguments
- Use double-struck digits to pass constant arguments from faces to commands.
  - These arguments will be equal to the digit used as the argument.
  - This is limited to the values 0-9 (inclusive).
  - `'` is an alias of `𝟛`
  - `½` represents `1 / i`, where `i` is the given index, or 2 if no index is given
- Use normal digits to pass face-valued arguments to commands.
  - These arguments, by default, pass the sum of every square on the given face to the command
  - If an index is specified, it passes the square on the given face at the given index to the command

### Indexed commands and indexed arguments
- You can specify an index when loading a command or argument
- An index assigned to a command modifies the command
  - For example, assigning the index 1 to the command R will rotate the layer 1 in from the right side counterclockwise from the right
- An index assigned to an argument modifies the argument
  - With face-valued arguments, it specifies which index on the face to take the value from instead of summing the face
  - With constant arguments, it does nothing (feel free to suggest ideas!)

### Selecting an index
- Use subscript numbers to select the index from the given constant value.
- Use superscript numbers to select the index from the value of the given face.

## Code page
|    | _0 | _1 | _2 | _3 | _4 | _5 | _6 | _7 | _8 | _9 | _A | _B | _C | _D | _E | _F |
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| 0_ |    |    |    |    |    |    |    |    |    |    |`\n`|    |    |    |    |    |
| 1_ |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
| 2_ |<code> </code>| `!`| `"`| `#`| `$`| `%`| `&`| `'`| `(`| `)`| `*`| `+`| `,`| `-`| `.`| `/`|
| 3_ | `0`| `1`| `2`| `3`| `4`| `5`| `6`| `7`| `8`| `9`| `:`| `;`| `<`| `=`| `>`| `?`|
| 4_ | `@`| `A`| `B`| `C`| `D`| `E`| `F`| `G`| `H`| `I`| `J`| `K`| `L`| `M`| `N`| `O`|
| 5_ | `P`| `Q`| `R`| `S`| `T`| `U`| `V`| `W`| `X`| `Y`| `Z`| `[`| `\`| `]`| `^`| `_`|
| 6_ | `` ` `` | `a`| `b`| `c`| `d`| `e`| `f`| `g`| `h`| `i`| `j`| `k`| `l`| `m`| `n`| `o`|
| 7_ | `p`| `q`| `r`| `s`| `t`| `u`| `v`| `w`| `x`| `y`| `z`| `{`|`\|`| `}`| `~`|    |
| 8_ | `₀`| `₁`| `₂`| `₃`| `₄`| `₅`| `₆`| `₇`| `₈`| `₉`| `×`| `÷`| `ⁿ`| `√`| `↕`| `↔`|
| 9_ | `⁰`| `¹`| `²`| `³`| `⁴`| `⁵`| `⁶`| `⁷`| `⁸`| `⁹`| `¬`| `«`| `»`|    |    |    |
| A_ | `𝟘`| `𝟙`| `𝟚`| `𝟛`| `𝟜`| `𝟝`| `𝟞`| `𝟟`| `𝟠`| `𝟡`|    |    |    |    |    |    |
| B_ | `½`|    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
| C_ |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
| D_ |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
| E_ |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
| F_ |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |    |

All characters are accessible through `\yx`, where `yx` is the hexidecimal value of the character. For example, `\A3` would be equivalent to `𝟛`.

## Face-valued argument indexes
       012
       345
       678
    012012012012
    345345345345
    678678678678
       012
       345
       678
