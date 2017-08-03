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
  self.loops = {}
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
      local ptr = self.ptr
      if self.command and not self.didCommand and self.options.experimental then
        self:command()
        self.didCommand = true
      end
      
      if self.ptr == ptr then
        self.command = self.commands[c] or (self.options.experimental and self.experimental[c] or nil)
        self.didCommand = false
      end
    end
    
    self.ptr = self.ptr + 1
    
    if self.ptr > #self.program and self.command and not self.didCommand and self.options.experimental then
      self:command()
      self.didCommand = true
    end
  end
end

function C:nextcmd()
  repeat
    self.ptr = self.ptr + 1
  until not tonumber(self.program:sub(self.ptr, self.ptr))
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
    self.cube:R(n)
  end,
  ['Ln'] = function(self, n)
    self.cube:L(n)
  end,
  ['Un'] = function(self, n)
    self.cube:U(n)
  end,
  ['Dn'] = function(self, n)
    self.cube:D(n)
  end,
  ['Fn'] = function(self, n)
    self.cube:F(n)
  end,
  ['Bn'] = function(self, n)
    self.cube:B(n)
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
  [':n'] = function(self, n)
    self.notepad = self:value(n)
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
      self.program = ""
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
      
      while self.program:sub(label.ptr, label.ptr) ~= "(" do
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
    if not n or self:value(n) ~= 0 then
      if #self.loops then
        local label = table.remove(self.loops)
        local valid = not label.args or table.iterator(label.args).any(function(arg) return self:value(arg) ~= 0 end)
        
        if valid then
          -- Convert `loopsIter` back into `self.loops`, removing any elements that have been checked
          self.ptr = label.ptr - 1
          return
        end
      end
    end
  end,
  ['{x'] = function(self, n) end,
  ['}x'] = function(self, n) end,
  ['?xn'] = function(self, n)
    if self:value(n) == 0 then
      -- Seek past conditional, and check elseifs and elses
    else
      self:nextcmd()
      self.ptr = self.ptr - 1
      
      -- Ignore elseifs and elses
    end
  end,
  ['!xn'] = function(self, n)
    if self:value(n) == 0 then
      -- Seek past conditional, and check elseifs and elses
    else
      self:nextcmd()
      self.ptr = self.ptr - 1
      
      -- Ignore elseifs and elses
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
  .select(function(cmd, func)
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
  .totable()

-- Create the experimental commands list
C.experimental = table.iterator(C.commands, true)
  .unpack()
  .where(function(cmd, args, func) return args:match("x") end)
  .totable(function(cmd, args, func) return cmd end, function(cmd, args, func) return func end)

-- Remove experimental commands from main commands list
C.commands = table.iterator(C.commands, true)
  .unpack()
  .where(function(cmd, args, func) return not args:match("x") end)
  .totable(function(cmd, args, func) return cmd end, function(cmd, args, func) return func end)

-- Obsolete commands
C.commands['E'] = C.commands['&']

_G.Cubically = C