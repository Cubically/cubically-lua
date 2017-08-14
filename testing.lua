require("cubically")

local interpreter = Cubically.new({experimental = false, size = 3})
io.input("input.txt")
local program = io.open("program.cb", "r"):read("*a")
interpreter:exec(program)

print()
print("===========")
print("Program size: " .. #Cubically.codepage.utf8bytes(program) .. " bytes (" .. #program .. " in ASCII).")
--print("-----------")
--print("Final state:")
--interpreter:exec("#")