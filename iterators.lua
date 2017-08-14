--[[ This file focuses on iterators, like pairs and ipairs. It defines functions similar to LINQ that return iterators. ]]--

-- Keep track of all iterator objects, but allow them to be GC'd
local iterators = setmetatable({}, {__mode = "k"})
local Iterator = {}

local function isIterator(o)
  return type(o) == "function" or iterators[o]
end

local function asIterator(o)
  return isIterator(o) and o or table.iterator(o)
end

--- Converts a table or iterator function into an iterator object.
-- An iterator object is just a wrapper for an iterator function with additional functionality attached to it.
-- @param target The object to iterate. If `target` is an iterator object or function, this function simply wraps it. If `target` is a table, this function creates an iterator object from it.
-- @param valuesOnly Whether to iterate through only the values of `target`. This parameter is only used if `target` is a table.
-- @param index Whether to use `ipairs` instead of `pairs` to create the iterator
function table.iterator(target, valuesOnly, index)
  -- If onCall is a table to iterate, then convert it to a stateless iterator function
  if not isIterator(target) then
    local typ = type(target)
    if typ == "table" then
      local nxt, t, k, v
      if (index) then
        nxt, t, k, v = ipairs(target)
      else
        nxt, t, k, v = pairs(target)
      end
      
      target = function()
        k, v = nxt(t, k, v)
        
        if valuesOnly then
          return v
        end
        
        return k, v
      end
    elseif typ == "string" then
      local i = -1
      local str = target
      target = target:gmatch(".")
    else
      error("target must be iterable")
    end
  end
  
  -- Create the iterator
  local iter = {
    target = target
  }
  
  iterators[iter] = true
  return setmetatable(iter, {
    __index = Iterator,
    __call = target
  })
end

--- Limits the output of the iterator
-- The output will be in the same order, but only values determined by `predicate` will be returned
-- @param predicate The function which determines whether a result should be returned by the iterator
function Iterator:where(predicate)
  local this = self
  return table.iterator(function()
    local ret
    repeat
      ret = {this.target()}
    until #ret == 0 or predicate(unpack(ret))
    return unpack(ret)
  end)
end

--- Modifies the results of the iterator
-- The values returned by `predicate` will be returned by the iterator instead
-- @param predicate The function which determines what will be output by the iterator
function Iterator:select(predicate)
  local this = self
  return table.iterator(function()
    local ret = {this.target()}
    if #ret > 0 then
      return predicate(unpack(ret))
    end
  end)
end

--- Combines multiple iterators
-- This will not check that each iterator has the same number of results
function Iterator:concat(...)
  local joined = {...}
  local this = self
  return table.iterator(function()
    local ret = {this.target()}
    
    while #ret == 0 and #joined > 0 do
      this.target = asIterator(table.remove(joined, 1))
      ret = {this.target()}
    end
    
    if #ret > 0 then
      return unpack(ret)
    end
  end)
end

--- Creates a new iterator based on the results of two different iterators
-- The number of elements in the resulting iterator will be equal to the current number of elements or the number of elements in `second`, whichever is smaller
-- @param second The iterator to zip with
-- @param selector Optional. The function which determines what will be output by the iterator. Default is `function(...) return ... end`.
function Iterator:zip(second, selector)
  second = asIterator(second)
  selector = selector or function(...) return ... end
  local this = self
  return table.iterator(function()
    local ret1 = {this.target()}
    local ret2 = {second()}
    
    if #ret1 > 0 and #ret2 > 0 then
      for i, v in ipairs(ret2) do
        table.insert(ret1, v)
      end
      
      return selector(unpack(ret1))
    end
  end)
end

--- Returns an iterator containing the elements in both this iterator and the second iterator
-- The elements in this iterator are returned
-- @param second The iterator to compare this to
-- @param comparer Optional. The function which determines which results are equivalent. Defualt compares each result from each iterator with each other
function Iterator:intersect(second, comparer)
  second = asIterator(second)
  
  -- Iterate `second` to be compared to later
  local secondTable = {}
  local r = {second()}
  while #r > 0 do
    table.insert(secondTable, r)
    r = {second()}
  end
  
  local this = self
  return table.iterator(function()
    local r = {this.target()}
    
    while #r > 0 do
      local collision = false
      
      -- Compare to each element in `second`
      for _, elem in ipairs(secondTable) do
        if comparer then
          local t = {unpack(r)}
          for i, v in ipairs(elem) do
            table.insert(t, v)
          end
          
          if comparer(unpack(t)) then
            collision = true
            break
          end
        else
          collision = true
          
          for i, v in ipairs(r) do
            if elem[i] ~= v then
              collision = false
              break
            end
          end
          
          if collision then
            break
          end
        end
      end
      
      if collision then
        return unpack(r)
      end
      
      r = {this.target()}
    end
    return nil      
  end)
end

--- Returns an iterator containing the elements in this iterator and not the second iterator
-- The elements in this iterator are returned
-- @param second The iterator to compare this to
-- @param comparer Optional. The function which determines which results are equivalent. Defualt compares each result from each iterator with each other
function Iterator:except(second, comparer)
  second = asIterator(second)
  
  -- Iterate `second` to be compared to later
  local secondTable = {}
  local r = {second()}
  while #r > 0 do
    table.insert(secondTable, r)
    r = {second()}
  end
  
  local this = self
  return table.iterator(function()
    local r = {this.target()}
    
    while #r > 0 do
      local collision = false
      
      -- Compare to each element in `second`
      for _, elem in ipairs(secondTable) do
        if comparer then
          local t = {unpack(r)}
          for i, v in ipairs(elem) do
            table.insert(t, v)
          end
          
          if comparer(unpack(t)) then
            collision = true
            break
          end
        else
          collision = true
          
          for i, v in ipairs(r) do
            if elem[i] ~= v then
              collision = false
              break
            end
          end
          
          if collision then
            break
          end
        end
      end
      
      if not collision then
        return unpack(r)
      end
      
      r = {this.target()}
    end
    return nil      
  end)
end

--- Returns an iterator containing only the unique results from this iterator
-- The first instances of the distinct results are returned
-- @param comparer Optional. The function which determines which results are equivalent. Defualt compares each element of each result with each other
function Iterator:distinct(comparer)
  local checked = {}
  local this = self
  return table.iterator(function()
    local r = {this.target()}
    
    while #r > 0 do
      local collision = false
      
      -- Compare to each element in `second`
      for _, elem in ipairs(secondTable) do
        if comparer then
          local t = {unpack(r)}
          for i, v in ipairs(elem) do
            table.insert(t, v)
          end
          
          if comparer(unpack(t)) then
            collision = true
            break
          end
        else
          collision = true
          
          for i, v in ipairs(r) do
            if elem[i] ~= v then
              collision = false
              break
            end
          end
          
          if collision then
            break
          end
        end
      end
      
      if not collision then
        table.insert(checked, r)
        return unpack(r)
      end
      
      r = {this.target()}
    end
    
    return nil
  end)
end

--- Skips the first `n` results of this iterator
-- Does not create a new iterator
-- @param n The number of results to skip
function Iterator:skip(n)
  while n > 0 and self.target() do
    n = n - 1
  end
  return self
end

--- Limits this iterator to the first `n` results
-- Creates a new iterator from this one. It is not cloned.
-- @param n The number of results to take
function Iterator:take(n)
  local this = self
  return table.iterator(function()
    if n > 0 then
      n = n - 1
      return this.target()
    end
  end)
end

--- Reverses the results from this iterator
-- Iterates the whole iterator
function Iterator:reverse()
  local buffer = self:totable()
  return table.iterator(function()
    if #buffer == 0 then
      return
    end
    
    return unpack(table.remove(buffer))
  end)
end

--- Sorts the elements in this iterator
-- Iterates the whole iterator
-- @param comparer The comparison function passed into `table.sort`
function Iterator:sort(comparer)
  local buffer = self:totable()
  table.sort(buffer, function(a, b)
    local t = {unpack(a)}
    for i, v in ipairs(b) do
      table.insert(t, v)
    end
    return comparer(unpack(t))
  end)
  return table.iterator(buffer, true, true):unpack()
end

--- Returns whether the iterator will return anything, optionally filtered by a predicate
-- If `predicate` is passed in, this will check if it returns true for any elements being iterated
-- @param predicate Optional. Determines which results it should be checking for
function Iterator:any(predicate)
  local ret = {self.target()}
  local buffer = {}
  while #ret > 0 do
    table.insert(buffer, ret)
    if not predicate or predicate(unpack(ret)) then
      self.target = table.iterator(buffer, true, true).select(function(t) return unpack(t) end).concat(self.target)
      return true
    end
    ret = {self.target()}
  end
  self.target = table.iterator(buffer, true, true)
  return false
end

--- Returns whether all results from this iterator meet the given `predicate`
-- This will create a new iterator that is a clone of this one
-- @param predicate The function to match each result against
function Iterator:all(predicate)
  local ret = {self.target()}
  local buffer = {}
  while #ret > 0 do
    table.insert(buffer, ret)
    if not predicate(unpack(ret)) then
      self.target = table.iterator(buffer, true, true).select(function(t) return unpack(t) end).concat(self.target)
      return false
    end
    ret = {self.target()}
  end
  self.target = table.iterator(buffer, true, true)
  return true
end

--- Returns the first result from the iterator, optionally filtered by a predicate
-- If `predicate` is passed in, will return the first result from the iterator that the predicate matches
-- @param predicate Optional. The function to match each result against
function Iterator:first(predicate)
  local ret = {self.target()}
  local buffer = {}
  while #ret > 0 do
    table.insert(buffer, ret)
    if not predicate or predicate(unpack(ret)) then
      self.target = table.iterator(buffer, true, true).select(function(t) return unpack(t) end).concat(self.target)
      return unpack(ret)
    end
    ret = {self.target()}
  end
  self.target = table.iterator(buffer, true, true)
  return false
end

function Iterator:last(predicate)
  local ret = {self.target()}
  local last = nil
  local buffer = {}
  while #ret > 0 do
    table.insert(buffer, ret)
    if not predicate or predicate(unpack(ret)) then
      self.target = table.iterator(buffer, true, true).select(function(t) return unpack(t) end).concat(self.target)
      last = ret
    end
    ret = {self.target()}
  end
  self.target = table.iterator(buffer, true, true)
  if last then
    return unpack(last)
  end
end

function Iterator:aggregate(seed, func, resultSelector)
  if type(seed) == "function" then
    resultSelector = func
    func = seed
    seed = nil
  end
  
  local ret = {self.target()}
  while #ret > 0 do
    seed = func(seed, unpack(ret))
    ret = {self.target()}
  end
  return resultSelector and resultSelector(seed) or seed
end

function Iterator:unpack()
  local this = self
  return table.iterator(function()
    local ret = {this.target()}
    if #ret > 0 then
      return unpack(ret[1])
    end
  end)
end

function Iterator:totable(keySelector, valueSelector)
  local t = {}
  local ret = {self.target()}
  if keySelector then
    -- Use keySelector to select keys
    while #ret > 0 do
      t[keySelector(unpack(ret))] = valueSelector and valueSelector(unpack(ret)) or ret[1]
      ret = {self.target()}
    end
  else
    -- Keys will be an incrementing integer starting at 1.
    local i = 1
    while #ret > 0 do
      t[i] = valueSelector and valueSelector(unpack(ret)) or ret
      ret = {self.target()}
      i = i + 1
    end
    --end
  end
  return t
end

--- Returns an iterator containing number values.
-- If no `start` is defined, this function will start at `1`.
-- @param start Optional. What number to start at. Default value is `1`. (Inclusive)
-- @param finish What number to end at. (Inclusive)
-- @param step Optional. Difference between each element. Default value is `1`.
function table.range(start, finish, step)
  step = step or 1
  if not finish then
    finish = start
    start = 1
  end
  
  local i = start - step
  return table.iterator(function()
    i = i + step
    return i <= finish and i or nil
  end)
end
