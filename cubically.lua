require("cube")
require("iterators")

-- Interpreter
local C = {}

C.codepage = require("codepage")

function C.new(options)
  options = (type(options) == "table") and options or {}
  
  return setmetatable({
    cube = Cube.new(options.size),
    notepad = 0,
    input = 0,
    options = options
  }, {__index = C})
end

function C:exec(program)
  assert(self.cube, "Must be an instance, call new() first")
  assert(type(program) == "string", "program must be a string")
  
  self.program = self.codepage.tochars(self.codepage.utf8bytes(program))
  self.ptr = 1
  self.loops = {}
  self.conditionFailed = false
  self.doElse = false
  self.didCommand = false
  self.command = nil
  self.subscript = 0
  while self.ptr <= #self.program do
    local c = self.program[self.ptr]
    local b = self.codepage.bytes[c]
    local ptr = self.ptr
    
    if self.codepage.digit(b) then
      -- Command argument
      
      if self.command then
        self:command(self.codepage.digit(b))
        self.didCommand = true
        self.doElse = false
      end
    elseif self.codepage.subscript(b) then
      -- Layer selection
      
      self.subscript = self.subscript * 10 + self.codepage.subscript(b)
    elseif self.conditionFailed then
      -- Command being skipped by a conditional
      
      self:skipcmd()
      self.conditionFailed = false
      self.doElse = true
    else
      -- Command
      
      if self.command and not self.didCommand then
        self:command()
        self.didCommand = true
        self.doElse = false
      end
      
      if self.ptr == ptr then
        self.command = self.commands[c] or (self.options.experimental and self.experimental[c] or nil)
        self.subscript = 0
        self.didCommand = false
      end
    end
    
    if self.ptr == ptr then
      self.ptr = self.ptr + 1
    end
    
    if self.ptr > #self.program and self.command and not self.didCommand then
      self:command()
      self.didCommand = true
    end
  end
end

function C:skipcmd()
  local level = 0
  local c = self.program[self.ptr]
  local extraSkip
  repeat
    extraSkip = self.options.experimental and c == "?"
    
    repeat
      if c == "{" then
        level = level + 1
      elseif c == "}" then
        level = level - 1
      end
      
      self.ptr = self.ptr + 1
      c = self.program[self.ptr]
    until self.ptr > #self.program or (level == 0 and not tonumber(c))
  until not extraSkip
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
  ['Rn'] = function(self, n)
    self.cube:R(n, self.subscript)
  end,
  ['Ln'] = function(self, n)
    self.cube:L(n, self.subscript)
  end,
  ['Un'] = function(self, n)
    self.cube:U(n, self.subscript)
  end,
  ['Dn'] = function(self, n)
    self.cube:D(n, self.subscript)
  end,
  ['Fn'] = function(self, n)
    self.cube:F(n, self.subscript)
  end,
  ['Bn'] = function(self, n)
    self.cube:B(n, self.subscript)
  end,
  
  [':n'] = function(self, n)
    self.notepad = self:value(n)
  end,
  ['+n'] = function(self, n)
    self.notepad = self.notepad + self:value(n)
  end,
  ['-n'] = function(self, n)
    self.notepad = self.notepad - self:value(n)
  end,
  ['*n'] = function(self, n)
    self.notepad = self.notepad * self:value(n)
  end,
  ['/n'] = function(self, n)
    self.notepad = math.floor(self.notepad / self:value(n))
  end,
  ['^n'] = function(self, n)
    self.notepad = self.notepad ^ self:value(n)
  end,
  ['_xn'] = function(self, n)
    self.notepad = self.notepad % self:value(n)
  end,
  ['sxn'] = function(self, n)
    self.notepad = bit32.arshift(self.notepad, self:value(n))
  end,
  ['"xn'] = function(self, n)
    self.notepad = bit32.band(self.notepad, self:value(n))
  end,
  ['|xn'] = function(self, n)
    self.notepad = bit32.bor(self.notepad, self:value(n))
  end,
  ['`xn'] = function(self, n)
    self.notepad = bit32.bxor(self.notepad, self:value(n))
  end,
  ["nx"] = function(self, n)
    self.notepad = n and -self:value(n) or -self.notepad
  end,
  
  ['>n'] = function(self, n)
    self.notepad = (self.notepad > self:value(n)) and 1 or 0
  end,
  ['<n'] = function(self, n)
    self.notepad = (self.notepad < self:value(n)) and 1 or 0
  end,
  ['=n'] = function(self, n)
    self.notepad = (self.notepad == self:value(n)) and 1 or 0
  end,
  
  ['&'] = function(self, n)
    if not n or self:value(n) ~= 0 then
      self.program = {}
    end
  end, 
  ['('] = function(self, n)
    local label
    if self.didCommand then
      label = self.loops[#self.loops]
    else
      label = {
        ptr = self.ptr,
        args = {}
      }
      
      while self.program[label.ptr] ~= "(" do
        label.ptr = label.ptr - 1
      end
      
      table.insert(self.loops, label)
    end
  
    if n then
      label.args[n] = true
    else
      label.args = nil
    end
  end,
  [')'] = function(self, n)
    local label = table.remove(self.loops)
    if label then
      if (not n or self:value(n) ~= 0) and (not label.args or table.iterator(label.args).any(function(arg) return self:value(arg) ~= 0 end)) then
        -- Jump to the `(`
        self.ptr = label.ptr
        return
      else
        -- TODO: this should jump if *any* of the arguments are true, not only if the first one is
        self:skipcmd()
      end
    end
  end,
  ['?n'] = function(self, n)
    if self:value(n) == 0 then
      self.conditionFailed = true
      if not self.options.experimental then
        self:skipcmd()
      end
    else
      self.conditionFailed = false
      if self.options.experimental then
        self:skipcmd()
      end
    end
  end,
  ['{'] = function(self, n) end,
  ['}'] = function(self, n) end,
  ['!'] = function(self, n)
    if self.options.experimental then
      if not self.doElse then
        if n then
          if self.program[self.ptr - 1] == "!" then
            self:skipcmd()
            self.conditionFailed = true
            return
          end
        else
          self:skipcmd()
          self.conditionFailed = true
          return
        end
      end
      
      if not n then
        self.conditionFailed = false
      elseif self:value(n) == 0 then
        self.conditionFailed = true
        if not self.options.experimental then
          self:skipcmd()
        end
      elseif self.options.experimental then
        self.conditionFailed = false
        self.doElse = false
        if self.options.experimental then
          self:skipcmd()
        end
      end
    else
      if n then
        if self:value(n) == 0 then
          self.conditionFailed = false
        else
          self.conditionFailed = true
          self:skipcmd()
        end
      elseif not self.doElse then
        self:skipcmd()
        self.conditionFailed = true
      end
    end
  end,
  
  ['@n'] = function(self, n)
    io.write(string.char(self:value(n) % 256))
  end,
  ['%n'] = function(self, n)
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

-- Parse commands
C.commands = table.iterator(C.commands)
  :select(function(cmd, func)
    local args = cmd:sub(2)
    cmd = cmd:sub(1, 1)
        
    if args:match("n") then
      local f = func
      func = function(self, n)
        return n and f(self, n) or nil
      end
    end
    
    return cmd, args, func
  end)
  :totable()

-- Create the experimental commands list
C.experimental = table.iterator(C.commands, true)
  :unpack()
  :where(function(cmd, args, func) return args:match("x") end)
  :totable(function(cmd, args, func) return cmd end, function(cmd, args, func) return func end)

-- Remove experimental commands from main commands list
C.commands = table.iterator(C.commands, true)
  :unpack()
  :where(function(cmd, args, func) return not args:match("x") end)
  :totable(function(cmd, args, func) return cmd end, function(cmd, args, func) return func end)

-- Obsolete commands
C.commands['E'] = C.commands['&']

_G.Cubically = C