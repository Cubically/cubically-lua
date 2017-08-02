require("cube")
require("tables")

-- Interpreter
local C = {}

function C.new(options)
  options = (type(options) == "table") and options or {}
  
  return setmetatable({
    instance = true,
    cube = Cube.new(),
    notepad = 0,
    input = 0,
    command = nil,
    didCommand = false,
    options = options
  }, {__index = C})
end

function C:exec(program)
  assert(self.instance, "Must be an instance, call new() first")
  assert(type(program) == "string", "program must be a string")
  
  self.program = program
  self.ptr = 1
  self.dir = 1
  self.loopStack = {}
  while self.ptr <= #self.program do
    local c = self.program:sub(self.ptr, self.ptr)
    local n = tonumber(c)
    
    if n then
      if not self.command then
        print(self.cube:tostring())
        return
      end
      
      if self.command then
        self:command(n)
        self.didCommand = true
      end
    else
      if self.command and not self.didCommand and self.options.experimental then
        self:command()
      end
      
      self.command = self.commands[c] or (self.options.experimental and self.experimental[c] or nil)
      self.didCommand = false
    end
    
    self.ptr = self.ptr + self.dir
  end

  if self.command and not self.didCommand and self.options.experimental then
    self:command()
  end
end

function C:value(n)
  if n % 1 ~= 0 then
    return 0
  end
  
  if n >= 0 and n <= 5 then
    return self.cube:value(n)
  elseif n == 6 then
    return self.notepad
  elseif n == 7 then
    return self.input
  else
    return 0
  end
end

C.commands = {
  ['R'] = function(self, n)
    if not n then
      return
    end
    self.cube:R(n)
  end,
  ['L'] = function(self, n)
    if not n then
      return
    end
    self.cube:L(n)
  end,
  ['U'] = function(self, n)
    if not n then
      return
    end
    self.cube:U(n)
  end,
  ['D'] = function(self, n)
    if not n then
      return
    end
    self.cube:D(n)
  end,
  ['F'] = function(self, n)
    if not n then
      return
    end
    self.cube:F(n)
  end,
  ['B'] = function(self, n)
    if not n then
      return
    end
    self.cube:B(n)
  end,
  
  ['+'] = function(self, n)
    if not n then
      return
    end
    self.notepad = self.notepad + self:value(n)
  end,
  ['-'] = function(self, n)
    if not n then
      return
    end
    self.notepad = self.notepad - self:value(n)
  end,
  ['*'] = function(self, n)
    if not n then
      return
    end
    self.notepad = self.notepad * self:value(n)
  end,
  ['/'] = function(self, n)
    if not n then
      return
    end
    self.notepad = math.floor(self.notepad / self:value(n))
  end,
  ['^'] = function(self, n)
    if not n then
      return
    end
    self.notepad = self.notepad ^ self:value(n)
  end,
  [':'] = function(self, n)
    if not n then
      return
    end
    self.notepad = self:value(n)
  end,
  
  ['>x'] = function(self, n)
    if not n then
      return
    end
    self.notepad = (self.notepad > self:value(n)) and 1 or 0
  end,
  ['<x'] = function(self, n)
    if not n then
      return
    end
    self.notepad = (self.notepad < self:value(n)) and 1 or 0
  end,
  ['='] = function(self, n)
    if not n then
      return
    end
    self.notepad = (self.notepad == self:value(n)) and 1 or 0
  end,
  
  ['&'] = function(self, n)
    if not n then
      return
    end
    if self:value(n) ~= 0 then
      self.program = ""
    end
  end,
  ['(x'] = function(self, n)
    local label
    if self.didCommand then
      label = self.loopStack[#self.loopStack]
    else
      label = {
        ptr = self.ptr,
        args = {}
      }
      table.insert(self.loopStack, label)
    end
  
    if n then
      label.args[n] = true
    else
      label.args = nil
    end
  end,
  [')x'] = function(self, n)
    if not n or self:value(n) ~= 0 then
      local label = table.remove(self.loopStack)
      local valid = false
      while label ~= nil do
        if label.args then
          for k, _ in pairs(label.args) do
            if self:value(k) ~= 0 then
              valid = true
              break
            end
          end
        else
          valid = true
        end
        
        if valid then
          break
        end
        label = table.remove(self.loopStack)
      end
      
      if label then
        table.insert(self.loopStack, label)
        self.ptr = label.ptr
        while tonumber(self.program:sub(self.ptr, self.ptr)) do
          self.ptr = self.ptr + 1
        end
        self.ptr = self.ptr - self.dir
      end
    end
  end,
  
  ['@'] = function(self, n)
    if not n then
      return
    end
    io.write(string.char(self:value(n) % 256))
  end,
  ['%'] = function(self, n)
    if not n then
      return
    end
    io.write(self:value(n))
  end,
  ['$'] = function(self, n)
    self.input = io.read("*n") or self.input
  end,
  ['~'] = function(self, n)
    local inp = io.read(1)
    self.input = inp and string.byte(inp) or -1
  end,
  
  ['#x'] = function(self, n)
    print(self.cube:tostring())
    print("Notepad: " .. self.notepad)
    print("Input: " .. self.input)
    print()
  end
}

-- Create the experimental commands list
C.experimental = table.iterator(C.commands)
  .where(function(cmd, func) return #cmd > 1 and cmd:sub(2, 2) == "x" end)
  .select(function(cmd, func) return cmd:sub(1, 1), func end)
  .totable(function(cmd, func) return cmd end, function(cmd, func) return func end)

for cmd, func in pairs(C.experimental) do
  C.commands[cmd .. "x"] = nil
end

_G.Cubically = C