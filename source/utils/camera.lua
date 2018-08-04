-- Love2D camera
-- http://ebens.me/post/cameras-in-love2d-part-1-the-basics
local camera = 
{
  x = 0,
  y = 0,
  scaleX = 1,
  scaleY = 1,
  rotation = 0,
  shake = 0,
}
function camera:set()
  local xOffset = (love.math.random(-1, 1) * self.shake)
  local yOffset = (love.math.random(-1, 1) * self.shake)
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
  love.graphics.translate(-self.x + xOffset, -self.y + yOffset)
end

function camera:update(dt)
  if self.shake > 0 then
    self.shake = self.shake - dt * 4;
  else
    self.shake = 0;
  end
end

function camera:unset()
  love.graphics.pop()
end

function camera:move(dx, dy)
  self.x = self.x + (dx or 0)
  self.y = self.y + (dy or 0)
end

function camera:rotate(dr)
  self.rotation = self.rotation + dr
end

function camera:scale(sx, sy)
  sx = sx or 1
  self.scaleX = self.scaleX * sx
  self.scaleY = self.scaleY * (sy or sx)
end

function camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function camera:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end

function camera:mousePosition()
  return love.mouse.getX() * self.scaleX + self.x, love.mouse.getY() * self.scaleY + self.y
end

function camera:addShake(pixels)
  self.shake = self.shake + pixels
  if self.shake > Config.shakeMax then
    self.shake = Config.shakeMax
  end
end

return camera;

