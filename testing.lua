require("cubically")

local interpreter = Cubically.new({experimental = true})
--io.write("Cube> ")
--interpreter:exec(io.read("*l"))
--TODO: `self.loops` is storing the loop labels past when they're needed. The last `)` jumps to the second `(`.
io.input("input.txt")
interpreter:exec([[
R3D1R1D1

+0
(
  %6
  ?6{
    ?7@7
    ~
    :1+2<7?6{
      +35>7?6{
        :7-120?6{
          (
            @7
            B3@5
            B1-0
            -6
          )6
        }
        :0
      }
    }
  }
  
  ?7@7
  
  ~
  -60=7&6
  -60=7?6&
  +4-3=7
  %6
)
]])

print()
print("===========")
print("Final state")
print("-----------")
interpreter:exec("#")