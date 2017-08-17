

-- Codepage
-- First 128 characters are auto-populated below if not explicitly set here
local Codepage = {}
local INH = false -- Inherit from ASCII table, equivalent to `nil`
Codepage.chars = {
  [0] = 
  -- _0   _1   _2   _3   _4   _5   _6   _7   _8   _9   _A   _B   _C   _D   _E   _F
     nil, nil, nil, nil, nil, nil, nil, nil, nil, INH, nil, nil, nil, nil, nil, nil, -- 0_ -- 0A is `\n`
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 1_
     " ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", -- 2_
     "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", -- 3_ -- normal digits for face-valued arguments
     "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", -- 4_
     "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", INH, "]", "^", "_", -- 5_ -- 5C is `\`
     "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", -- 6_
     "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", nil, -- 7_
     "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉", "ⁿ", "√", "ṡ", "ċ", "Ṡ", "Ċ", -- 8_ -- subscript for constant layer selection
     "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹", "¬", "«", "»", nil, nil, nil, -- 9_ -- superscript for face-valued layer selection
     "⓪", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", nil, nil, nil, nil, nil, nil, -- A_ -- circled digits for constant arguments
     "½", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- B_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- C_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- D_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- E_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- F_
}

-- First 128 characters
for i = 0, 127 do
  Codepage.chars[i] = Codepage.chars[i] or string.char(i)
end

-- Reverse lookup
Codepage.bytes = {}

for i = 0, 255 do
  if Codepage.chars[i] then
    Codepage.bytes[Codepage.chars[i]] = i
  end
end

-- Metatables for undefined characters
setmetatable(Codepage.chars, {
  __index = function(self, k)
    return rawget(self, k) or "�"
  end
})

setmetatable(Codepage.bytes, {
  __index = function(self, k)
    return rawget(self, k) or -1
  end
})

-- String to utf8 character array conversion
local ascii = {}
for i = 0, 255 do
  ascii[i] = string.char(i)
end

function Codepage.new(cubically)
  return setmetatable({
    cubically = cubically
  }, {
    __index = Codepage
  })
end

function Codepage:utf8raw(str)
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
        table.insert(bytes, cur)
        cur = nil
      end
    else
      -- 1 byte character
      if cur then
        table.insert(bytes, cur)
        cur = nil
      end
      
      table.insert(bytes, ascii[b])
      bytesleft = 0
    end
    ptr = ptr + 1
  end
  
  return bytes
end

function Codepage:utf8bytes(str)
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
        table.insert(bytes, Codepage.bytes[cur])
        cur = nil
      end
    else
      -- 1 byte character
      if cur then
        table.insert(bytes, Codepage.bytes[cur])
        cur = nil
      end
      
      table.insert(bytes, Codepage.bytes[ascii[b]])
      bytesleft = 0
    end
    ptr = ptr + 1
  end
  
  return bytes
end

function Codepage:tochars(str)
  local chars = {}
  for i, v in ipairs(str) do
    chars[i] = Codepage.chars[v]
  end
  return chars
end

function Codepage:tobytes(str)
  local bytes = {}
  for i, v in ipairs(str) do
    bytes[i] = Codepage.bytes[v]
  end
  return bytes
end

function Codepage:constarg(char, index)
  if type(char) == "string" then
    char = Codepage.bytes[char]
  end
  
  if char >= 0xA0 and char < 0xAA then
    return char - 0xA0
  elseif char == 0x27 then
    -- Treat each apostrophe as a 3
    return 3
  elseif char == 0xB0 then
    return 1 / (index or 2)
  end
end

function Codepage:facearg(char, index)
  if type(char) == "string" then
    char = Codepage.bytes[char]
  end
  
  if char >= 0x30 and char < 0x3A then
    return self.cubically:value(char - 0x30, index)
  end
end

function Codepage:constindex(char)
  if type(char) == "string" then
    char = Codepage.bytes[char]
  end
  
  if char >= 0x80 and char < 0x8A then
    return char - 0x80
  end
end

function Codepage:faceindex(char)
  if type(char) == "string" then
    char = Codepage.bytes[char]
  end
  
  if char >= 0x90 and char < 0x9A then
    return self.cubically:value(char - 0x90)
  end
end

_G.Codepage = Codepage