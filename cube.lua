local Cube = {}
function Cube.new(size)
  local faces = {}
  size = size or 3
  local sizeSquared = size ^ 2
  for face = 0, 5 do
    faces[face] = {}
    for n = 0, sizeSquared - 1 do
      faces[face][n] = face
    end
  end
  
  faces.U = faces[0]
  faces.D = faces[5]
  faces.L = faces[1]
  faces.R = faces[3]
  faces.F = faces[2]
  faces.B = faces[4]

  return setmetatable({
    faces = faces,
    size = size,
    sizeSquared = sizeSquared
  }, {
    __index = Cube,
    __tostring = Cube.tostring
  })
end

function Cube:index(x, y)
  return y * self.size + x
end

local function rotateFace(cube, face)
  local size = cube.size
  for y = 0, math.floor(size / 2) - 1 do
    for x = 0, math.ceil(size / 2) - 1 do
      local t = face[cube:index(x, y)]
      face[cube:index(x, y)] = face[cube:index(y, size - 1 - x)]
      face[cube:index(y, size - 1 - x)] = face[cube:index(size - 1 - x, size - 1 - y)]
      face[cube:index(size - 1 - x, size - 1 - y)] = face[cube:index(size - 1 - y, x)]
      face[cube:index(size - 1 - y, x)] = t
    end
  end
end

function Cube:R(n)
  n = n % 4

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.U[self:index(size - 1, i)]
      faces.U[self:index(size - 1, i)] = faces.F[self:index(size - 1, i)]
      faces.F[self:index(size - 1, i)] = faces.D[self:index(size - 1, i)]
      faces.D[self:index(size - 1, i)] = faces.B[self:index(0, size - i - 1)]
      faces.B[self:index(0, size - i - 1)] = t
    end

    -- Rotate face
    rotateFace(self, faces.R)
  end
end

function Cube:L(n)
  n = n % 4

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.U[self:index(0, i)]
      faces.U[self:index(0, i)] = faces.B[self:index(self.size - 1, self.size - i - 1)]
      faces.B[self:index(self.size - 1, self.size - i - 1)] = faces.D[self:index(0, i)]
      faces.D[self:index(0, i)] = faces.F[self:index(0, i)]
      faces.F[self:index(0, i)] = t
    end

    -- Rotate face
    rotateFace(self, faces.L)
  end
end

function Cube:U(n)
  n = n % 4

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.L[self:index(i, 0)]
      faces.L[self:index(i, 0)] = faces.F[self:index(i, 0)]
      faces.F[self:index(i, 0)] = faces.R[self:index(i, 0)]
      faces.R[self:index(i, 0)] = faces.B[self:index(i, 0)]
      faces.B[self:index(i, 0)] = t
    end

    -- Rotate face
    rotateFace(self, faces.U)
  end
end

function Cube:D(n)
  n = n % 4

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.B[self:index(i, size - 1)]
      faces.B[self:index(i, size - 1)] = faces.R[self:index(i, size - 1)]
      faces.R[self:index(i, size - 1)] = faces.F[self:index(i, size - 1)]
      faces.F[self:index(i, size - 1)] = faces.L[self:index(i, size - 1)]
      faces.L[self:index(i, size - 1)] = t
    end

    -- Rotate face
    rotateFace(self, faces.D)
  end
end

function Cube:F(n)
  n = n % 4

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    -- Rotate sides
    for i = 0, size - 1 do
      local t = faces.U[self:index(i, size - 1)]
      faces.U[self:index(i, size - 1)] = faces.L[self:index(size - 1, size - i - 1)]
      faces.L[self:index(size - 1, size - i - 1)] = faces.D[self:index(size - i - 1, 0)]
      faces.D[self:index(size - i - 1, 0)] = faces.R[self:index(0, i)]
      faces.R[self:index(0, i)] = t
    end

    -- Rotate face
    rotateFace(self, faces.F)
  end
end

function Cube:B(n)
  n = n % 4

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.U[self:index(i, 0)]
      faces.U[self:index(i, 0)] = faces.R[self:index(size - 1, i)]
      faces.R[self:index(size - 1, i)] = faces.D[self:index(size - i - 1, size - 1)]
      faces.D[self:index(size - i - 1, size - 1)] = faces.L[self:index(0, size - i - 1)]
      faces.L[self:index(0, size - i - 1)] = t
    end

    -- Rotate face
    rotateFace(self, faces.B)
  end
end

function Cube:value(n)
  if n < 0 or n > 5 or n % 1 ~= 0 then
    return 0
  end
  
  local sum = 0
  for i = 0, self.sizeSquared - 1 do
    sum = sum + self.faces[n][i]
  end
  return sum
end

function Cube:tostring()
  local s = ""
  local size = self.size
  for y = 0, size - 1 do
    s = s .. (" "):rep(size)
    for x = 0, size - 1 do
      s = s .. self.faces.U[self:index(x, y)]
    end
    s = s .. "\n"
  end
  
  for y = 0, size - 1 do
    for i = 1, 4 do
      for x = 0, size - 1 do
        s = s .. self.faces[i][self:index(x, y)]
      end
    end
    s = s .. "\n"
  end
  
  for y = 0, size - 1 do
    s = s .. (" "):rep(size)
    for x = 0, size - 1 do
      s = s .. self.faces.D[self:index(x, y)]
    end
    s = s .. "\n"
  end

  return s:sub(1, #s - 1)
end

_G.Cube = Cube