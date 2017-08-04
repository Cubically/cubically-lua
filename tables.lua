--[[ This file focuses on iterators, like pairs and ipairs. It defines functions similar to LINQ that return iterators. ]]--

-- Keep track of all iterator objects, but allow them to be GC'd
local iterators = setmetatable({}, {__mode = "k"})

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
  local iter = {}
    
  iter.where = function(predicate)
    return table.iterator(function()
      local ret
      repeat
        ret = {target()}
      until #ret == 0 or predicate(unpack(ret))
      return unpack(ret)
    end)
  end
  
  iter.select = function(predicate)
    return table.iterator(function()
      local ret = {target()}
      if #ret > 0 then
        return predicate(unpack(ret))
      end
    end)
  end
  
  iter.concat = function(...)
    local joined = {...}
    
    return table.iterator(function()
      local ret = {target()}
      
      while #ret == 0 and #joined > 0 do
        target = asIterator(table.remove(joined, 1))
        ret = {target()}
      end
      
      if #ret > 0 then
        return unpack(ret)
      end
    end)
  end
  
  iter.zip = function(second, selector)
    second = asIterator(second)
    selector = selector or function(...) return ... end
    
    return table.iterator(function()
      local ret1 = {target()}
      local ret2 = {second()}
      
      if #ret1 > 0 and #ret2 > 0 then
        for i, v in ipairs(ret2) do
          table.insert(ret1, v)
        end
        
        return selector(unpack(ret1))
      end
    end)
  end
  
  iter.intersect = function(second)
    -- TODO: It'd be neat if `r` could be hashed and stored as a key in `t` rather than a value
    local secondTable = {}
    local r = {second()}
    while #r > 0 do
      table.insert(secondTable, r)
      r = {second()}
    end
    
    return table.iterator(function()
      local r = {target()}
      
      while #r > 0 do
        local collision = false
        for _, elem in ipairs(secondTable) do
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
        
        if collision then
          return unpack(r)
        end
        
        r = {target()}
      end
      return nil      
    end)
  end
  
  iter.except = function(second)
    -- TODO: It'd be neat if `r` could be hashed and stored as a key in `t` rather than a value
    local secondTable = {}
    local r = {second()}
    while #r > 0 do
      table.insert(secondTable, r)
      r = {second()}
    end
    
    return table.iterator(function()
      local r = {target()}
      
      while #r > 0 do
        local collision = false
        for _, elem in ipairs(secondTable) do
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
        
        if not collision then
          return unpack(r)
        end
        
        r = {target()}
      end
      return nil      
    end)
  end
  
  iter.distinct = function()
    local checked = {}
    
    return table.iterator(function()
      local r = {target()}
      
      while #r > 0 do
        local collision = false
        for _, elem in ipairs(checked) do
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
        
        if not collision then
          table.insert(checked, r)
          return unpack(r)
        end
        
        r = {target()}
      end
      
      return nil
    end)
  end
  
  iter.skip = function(n)
    while n > 0 and target() do
      n = n - 1
    end
    return self
  end
  
  iter.take = function(n)
    return table.iterator(function()
      if n > 0 then
        n = n - 1
        return target()
      end
    end)
  end
  
  iter.reverse = function()
    local buffer = iter.totable()
    return table.iterator(function()
      if #buffer == 0 then
        return
      end
      
      return unpack(table.remove(buffer))
    end)
  end
  
  iter.sort = function(comparer)
    local buffer = iter.totable()
    table.sort(buffer, function(a, b)
      local t = {unpack(a)}
      for i, v in ipairs(b) do
        table.insert(t, v)
      end
      return comparer(unpack(t))
    end)
    return table.iterator(buffer, true, true).unpack()
  end
  
  iter.any = function(predicate)
    local ret = {target()}
    local buffer = {}
    while #ret > 0 do
      table.insert(buffer, ret)
      if predicate(unpack(ret)) then
        target = table.iterator(buffer, true, true).select(function(t) return unpack(t) end).concat(target)
        return true
      end
      ret = {target()}
    end
    target = table.iterator(buffer, true, true)
    return false
  end
  
  iter.all = function(predicate)
    local ret = {target()}
    local buffer = {}
    while #ret > 0 do
      table.insert(buffer, ret)
      if not predicate(unpack(ret)) then
        target = table.iterator(buffer, true, true).select(function(t) return unpack(t) end).concat(target)
        return false
      end
      ret = {target()}
    end
    target = table.iterator(buffer, true, true)
    return true
  end
  
  iter.aggregate = function(seed, func, resultSelector)
    if type(seed) == "function" then
      resultSelector = func
      func = seed
      seed = nil
    end
    
    local ret = {target()}
    while #ret > 0 do
      seed = func(seed, unpack(ret))
      ret = {target()}
    end
    return resultSelector and resultSelector(seed) or seed
  end
  
  iter.unpack = function()
    return table.iterator(function()
      local ret = {target()}
      if #ret > 0 then
        return unpack(ret[1])
      end
    end)
  end
  
  iter.totable = function(keySelector, valueSelector)
    local t = {}
    local ret = {target()}
    if keySelector then
      -- Use keySelector to select keys
      while #ret > 0 do
        t[keySelector(unpack(ret))] = valueSelector and valueSelector(unpack(ret)) or ret[1]
        ret = {target()}
      end
    else
      -- Keys will be an incrementing integer starting at 1.
      local i = 1
      while #ret > 0 do
        t[i] = valueSelector and valueSelector(unpack(ret)) or ret
        ret = {target()}
        i = i + 1
      end
      --end
    end
    return t
  end
  
  iterators[iter] = true
  return setmetatable(iter, {
    __call = target
  })
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

local arr = table.range(10).select(function() return math.random(10) end).reverse().totable(nil, function(n) return n end)
print(table.iterator(arr, true, true).aggregate("", function(cur, n) return cur .. n .. " " end))

print(table.iterator(arr, true, true).sort(function(a, b) return a < b end).aggregate("", function(cur, n) return cur .. n .. " " end))