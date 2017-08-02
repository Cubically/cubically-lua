local Cube = {}
function Cube.new()
  local faces = {}
  for i = 0, 5 do
    faces[i] = {}
    for n = 0, 8 do
      faces[i][n] = i
    end
  end

  return setmetatable({
    faces = faces
  }, {
    __index = Cube,
    __tostring = Cube.tostring
  })
end

function Cube:R(n)
  n = n % 4

  local t = 0
  local f = self.faces
  for _ = 1, n do
    for i = 2, 8, 3 do
      t = f[0][i]
      f[0][i] = f[2][i]
      f[2][i] = f[5][10 - i]
      f[5][10 - i] = f[4][10 - i - 2]
      f[4][10 - i - 2] = t
    end

    -- Rotate face 3 CW
    local f = f[3]
    t = f[0]
    f[0] = f[6]
    f[6] = f[8]
    f[8] = f[2]
    f[2] = t
    t = f[1]
    f[1] = f[3]
    f[3] = f[7]
    f[7] = f[5]
    f[5] = t
  end
end

function Cube:L(n)
  n = n % 4

  local t = 0
  local f = self.faces
  for _ = 1, n do
    for i = 0, 6, 3 do
      t = f[0][i]
      f[0][i] = f[4][6 - i + 2]
      f[4][6 - i + 2] = f[5][6 - i]
      f[5][6 - i] = f[2][i]
      f[2][i] = t
    end

    -- Rotate face 1 CW
    local f = f[1]
    t = f[0]
    f[0] = f[6]
    f[6] = f[8]
    f[8] = f[2]
    f[2] = t
    t = f[1]
    f[1] = f[3]
    f[3] = f[7]
    f[7] = f[5]
    f[5] = t
  end
end

function Cube:U(n)
  n = n % 4

  local t = 0
  local f = self.faces
  for _ = 1, n do
    for i = 0, 2 do
      t = f[1][i]
      f[1][i] = f[2][i]
      f[2][i] = f[3][i]
      f[3][i] = f[4][i]
      f[4][i] = t
    end

    -- Rotate face 0 CW
    local f = f[0]
    t = f[0]
    f[0] = f[6]
    f[6] = f[8]
    f[8] = f[2]
    f[2] = t
    t = f[1]
    f[1] = f[3]
    f[3] = f[7]
    f[7] = f[5]
    f[5] = t
  end
end

function Cube:D(n)
  n = n % 4

  local t = 0
  local f = self.faces
  for _ = 1, n do
    for i = 6, 8 do
      t = f[4][i]
      f[4][i] = f[3][i]
      f[3][i] = f[2][i]
      f[2][i] = f[1][i]
      f[1][i] = t
    end

    -- Rotate face 5 CW
    local f = f[5]
    t = f[0]
    f[0] = f[2]
    f[2] = f[8]
    f[8] = f[6]
    f[6] = t
    t = f[1]
    f[1] = f[5]
    f[5] = f[7]
    f[7] = f[3]
    f[3] = t
  end
end

function Cube:F(n)
  n = n % 4

  local t = 0
  local f = self.faces
  for _ = 1, n do
    for i = 0, 2 do
      t = f[0][6 + i]
      f[0][6 + i] = f[1][6 - 3 * i + 2]
      f[1][6 - 3 * i + 2] = f[5][8 - i]
      f[5][8 - i] = f[3][3 * i]
      f[3][3 * i] = t
    end

    -- Rotate face 2 CW
    local f = f[2]
    t = f[0]
    f[0] = f[6]
    f[6] = f[8]
    f[8] = f[2]
    f[2] = t
    t = f[1]
    f[1] = f[3]
    f[3] = f[7]
    f[7] = f[5]
    f[5] = t
  end
end

function Cube:B(n)
  n = n % 4

  local t = 0
  local f = self.faces
  for _ = 1, n do
    for i = 0, 2 do
      t = f[0][i]
      f[0][i] = f[3][3 * i + 2]
      f[3][3 * i + 2] = f[5][2 - i]
      f[5][2 - i] = f[1][6 - 3 * i]
      f[1][6 - 3 * i] = t
    end

    -- Rotate face 4 CW
    local f = f[4]
    t = f[0]
    f[0] = f[6]
    f[6] = f[8]
    f[8] = f[2]
    f[2] = t
    t = f[1]
    f[1] = f[3]
    f[3] = f[7]
    f[7] = f[5]
    f[5] = t
  end
end

function Cube:value(n)
  if n < 0 or n > 5 or n % 1 ~= 0 then
    return 0
  end
  
  local sum = 0
  for i = 0, 8 do
    sum = sum + self.faces[n][i]
  end
  return sum
end

function Cube:tostring()
  local s = ""
  for y = 0, 2 do
    s = s .. "   "
    for x = 0, 2 do
      s = s .. self.faces[0][y * 3 + x]
    end
    s = s .. "\n"
  end

  for y = 0, 2 do
    for i = 1, 4 do
      for x = 0, 2 do
        s = s .. self.faces[i][y * 3 + x]
      end
    end
    s = s .. "\n"
  end

  for y = 2, 0, -1 do
    s = s .. "   "
    for x = 0, 2 do
      s = s .. self.faces[5][y * 3 + x]
    end
    s = s .. "\n"
  end

  return s:sub(1, #s - 1)
end

_G.Cube = Cube