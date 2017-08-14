require("iterators")

-- Codepage
-- First 128 characters are auto-populated below if not explicitly set here
local codepage = {}
codepage.chars = {
  [0] = 
  -- _0   _1   _2   _3   _4   _5   _6   _7   _8   _9   _A   _B   _C   _D   _E   _F
     "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉", nil, nil, nil, nil, nil, nil, -- 0_ -- 0A is `\n`
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 1_
     " ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", -- 2_
     "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", -- 3_
     "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", -- 4_
     "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", nil, "]", "^", "_", -- 5_ -- 5C is `\`
     "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", -- 6_
     "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", nil, -- 7_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 8_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 9_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- A_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- B_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- C_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- D_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- E_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- F_
}

-- First 128 characters
for i = 0, 127 do
  codepage.chars[i] = codepage.chars[i] or string.char(i)
end

-- Reverse lookup
codepage.bytes = {}

for i = 0, 255 do
  if codepage.chars[i] then
    codepage.bytes[codepage.chars[i]] = i
  end
end

-- Metatables for undefined characters
setmetatable(codepage.chars, {
  __index = function(self, k)
    return rawget(self, k) or "�"
  end
})

setmetatable(codepage.bytes, {
  __index = function(self, k)
    return rawget(self, k) or -1
  end
})

-- String to utf8 character array conversion
local ascii = {}
for i = 0, 255 do
  ascii[i] = string.char(i)
end

function codepage.utf8bytes(str)
  local bytes = {}
  local ptr = 1
  local len = str:len()
  
  local cur = nil
  local bytesleft = 0
  while ptr <= len do
    local b = str:byte(ptr)
    if b >= 0xF0 then
      -- 4 byte character
      cur = ascii[b]
      bytesleft = 3
    elseif b >= 0xE0 then
      -- 3 byte character
      cur = ascii[b]
      bytesleft = 2
    elseif b >= 0xC0 then
      -- 2 byte character
      cur = ascii[b]
      bytesleft = 1
    elseif b >= 0x80 and bytesleft > 0 then
      -- Part of a character
      cur = cur .. ascii[b]
      bytesleft = bytesleft - 1
      
      if bytesleft == 0 then
        table.insert(bytes, codepage.bytes[cur])
        cur = nil
      end
    else
      -- 1 byte character
      if cur then
        table.insert(bytes, codepage.bytes[cur])
        cur = nil
      end
      
      table.insert(bytes, codepage.bytes[ascii[b]])
      bytesleft = 0
    end
    ptr = ptr + 1
  end
  
  return bytes
end

function codepage.tochars(str)
  local chars = {}
  for i, v in ipairs(str) do
    chars[i] = codepage.chars[v]
  end
  return chars
end

function codepage.tobytes(str)
  local bytes = {}
  for i, v in ipairs(str) do
    bytes[i] = codepage.bytes[v]
  end
  return bytes
end

function codepage.digit(char)
  if type(char) == "string" then
    char = codepage.bytes[char]
  end
  
  if char >= 0x30 and char < 0x3A then
    return char - 0x30
  end
end

function codepage.subscript(char)
  if type(char) == "string" then
    char = codepage.bytes[char]
  end
  
  if char >= 0x00 and char < 0x0A then
    return char
  end
end

return codepage