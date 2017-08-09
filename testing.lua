require("cubically")

local interpreter = Cubically.new({experimental = true})
io.input("input.txt")
interpreter:exec(io.open("program.cb", "r"):read("*a"))

print()
print("===========")
print("Final state")
print("-----------")
interpreter:exec("#")