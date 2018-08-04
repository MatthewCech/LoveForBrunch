require("utils/animation");


-- Configure the game here
function love.load()
  -- Globals
  Config = require("config");
  Camera = require("utils/camera");
  G = 9.81;

  -- Default settings
  love.graphics.setDefaultFilter("nearest");
  love.window.setMode(Config.width * Config.scale, Config.height * Config.scale);

  -- Initialize
  Scene:Init();
end

function love.draw()
  love.graphics.push();
  love.graphics.setDefaultFilter("nearest");
  love.graphics.scale(Config.scale, Config.scale);

  
  Camera:set();
  Scene:DrawBackground(love.graphics);
  Scene:Draw(love.graphics);
  Camera:unset();

  love.graphics.pop();
end

function love.update(dt)
  Camera:update(dt);
  Scene:Update(dt);
end

function love.keypressed(key, scancode, isrepeat)
  Scene:KeyPressed(key, scancode, isrepeat);
end


function love.mousepressed( x, y, button, istouch )
  Scene:MousePressed(x, y, button);

end

Scene =
{
  player = 
  {
    position = { x = nil, y = nil },
    animation = {},
    scale = { x = nil, y = nil },
    width = 32,
    height = 32,
    speed = 0,
    forceUp = nil,
    forceUpReset = nil,
    rotation = 0,
    currentAnimation = "",
    onGround = true,
  },

  glitch = 
  {
    image = nil,
  },

  -- Effect fields: {image, position {x, y}, color, lifespan, life}
  effects = {},

  -- Attack fields: {start {x, y}, stop {x, y}, color, lifespan, life}
  attacks = {},
  
  -- Enemy fields: { object }
  enemies = {},

  -- Just images. All drawn at 0,0.
  backgroundImages = {},

  -- Physics
  world = nil,
  objects = nil,
}

function Scene:Init()
  self.player.scale.x = 1;
  self.player.scale.y = 1;
  self.player.speed = 200;
  self.player.forceUpReset = G * 12000;
  self.player.forceUp = self.player.forceUpReset;
  self.rotation = 0;
  self.player.position.x = 0;
  self.player.position.y = 0;
  self.player.animation = {};
  self.player.animation["left"]       = ConstructAnimation(love.graphics.newImage("assets/playerLeft.png"), 32, 32, 0.7);
  self.player.animation["idle"]       = ConstructAnimation(love.graphics.newImage("assets/playerIdle.png"), 32, 32, 2.0);
  self.player.animation["right"]      = ConstructAnimation(love.graphics.newImage("assets/playerRight.png"), 32, 32, 0.5);
  self.player.animation["punchright"] = ConstructAnimation(love.graphics.newImage("assets/playerPunchRight.png"), 32, 32, 1.0);
  self.player.animation["punchleft"]  = ConstructAnimation(love.graphics.newImage("assets/playerPunchLeft.png"), 32, 32, 1.0);
  self.player.animation["jumpright"]  = ConstructAnimation(love.graphics.newImage("assets/playerJumpRight.png"), 32, 32, 1.0);
  self.player.animation["jumpleft"]   = ConstructAnimation(love.graphics.newImage("assets/playerJumpLeft.png"), 32, 32, 1.0);
  self.player.animation["slideleft"]  = ConstructAnimation(love.graphics.newImage("assets/playerSlideLeft.png"), 32, 32, 1.0);
  self.player.animation["slideright"] = ConstructAnimation(love.graphics.newImage("assets/playerSlideRight.png"), 32, 32, 1.0);
  self.player.currentAnimation = "idle";


  self.glitch.image = love.graphics.newImage("assets/playerGlitch.png");

  -- Background
  love.graphics.setBackgroundColor(27/255, 104/255, 129/255);
  self.backgroundImages = {};
  self.player.onGround = true;
  table.insert(self.backgroundImages, love.graphics.newImage("assets/trees.png"));

  ---------------------------------------------------------------------------------------------------------

  love.physics.setMeter(16); --the height of a meter our worlds will be 16px
  self.world = love.physics.newWorld(0, G*128, true);
  self.world:setCallbacks(BeginContact, EndContact, PreSolve, PostSolve);
  self.objects = {};

  -- Create ground
  self.objects.ground = {};
  self.objects.ground.body = love.physics.newBody(self.world, Config.width / 2, Config.height);
  self.objects.ground.shape = love.physics.newRectangleShape(Config.width, Config.border * 2);
  self.objects.ground.fixture = love.physics.newFixture(self.objects.ground.body, self.objects.ground.shape);
  self.objects.ground.fixture:setFriction(.8);
  self.objects.ground.fixture:setUserData("ground");

  self.objects.leftWall = {};
  self.objects.leftWall.body = love.physics.newBody(self.world, 0, Config.height / 2);
  self.objects.leftWall.shape = love.physics.newRectangleShape(Config.border * 2, Config.height * 2);
  self.objects.leftWall.fixture = love.physics.newFixture(self.objects.leftWall.body, self.objects.leftWall.shape);
  self.objects.leftWall.fixture:setUserData("wall");

  self.objects.rightWall = {};
  self.objects.rightWall.body = love.physics.newBody(self.world, Config.width, Config.height / 2);
  self.objects.rightWall.shape = love.physics.newRectangleShape(Config.border * 2, Config.height * 2);
  self.objects.rightWall.fixture = love.physics.newFixture(self.objects.rightWall.body, self.objects.rightWall.shape);
  self.objects.rightWall.fixture:setUserData("wall");

  --let's create a player
  self.objects.player = {}
  self.objects.player.body = love.physics.newBody(self.world, self.player.position.x + self.player.width / 2, self.player.position.y + self.player.height / 2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  self.objects.player.shape = love.physics.newRectangleShape(self.player.width, self.player.height); --the player's shape has a radius of 20
  self.objects.player.fixture = love.physics.newFixture(self.objects.player.body, self.objects.player.shape, 1) -- Attach fixture to body and give it a density of 1.
  self.objects.player.fixture:setRestitution(0) --let the player bounce
  self.objects.player.fixture:setFriction(.8);
  self.objects.player.fixture:setUserData("player");
  self:MakeEnemy();
end

function Scene:MakeEnemy()
  local enemy = {}
    --let's create a couple blocks to play around with
  enemy.body = love.physics.newBody(self.world, 100, 100, "dynamic")
  enemy.shape = love.physics.newRectangleShape(0, 0, 50, 50)
  enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 5)
  enemy.fixture:setUserData("enemy");
  enemy.fixture:setFriction(.8);
  table.insert(self.objects, enemy);
  table.insert(self.enemies, { object = enemy });
end

function Scene:DrawBackground(Graphics)
  Graphics.setColor(53/255, 121/255, 144/255);

  for _, i in pairs(self.backgroundImages) do
    Graphics.draw(i, 0, 0);
  end

  Graphics.setColor(1, 1, 1);
end

function Scene:Draw(Graphics)
  --love.graphics.setColor(27/255, 104/255, 129/255); -- set the drawing color to green for the ground
  --love.graphics.setColor(53/255, 121/255, 144/255); -- set the drawing color to green for the ground
  Graphics.setColor(82/255, 147/255, 168/255); -- set the drawing color to green for the ground
  Graphics.polygon("fill", self.objects.ground.body:getWorldPoints(self.objects.ground.shape:getPoints())); 

  local leftAlpha = (Config.border + Config.borderWarningDistance) - self.player.position.x;
  if leftAlpha < 0 then
    leftAlpha = 0;
  end
  if leftAlpha > Config.borderWarningDistance then
    leftAlpha = borderWarningDistance;
  end
  Graphics.setColor(82/255, 147/255, 168/255, leftAlpha / Config.borderWarningDistance);
  Graphics.polygon("fill", self.objects.leftWall.body:getWorldPoints(self.objects.leftWall.shape:getPoints())); 

  local rightAlpha = math.abs((Config.width - Config.border - Config.borderWarningDistance) - self.player.position.x );
  if rightAlpha < 0 then
    rightAlpha = 0;
  end
  if rightAlpha > Config.borderWarningDistance then
    rightAlpha = borderWarningDistance;
  end

  Graphics.setColor(82/255, 147/255, 168/255, rightAlpha);
  Graphics.polygon("fill", self.objects.rightWall.body:getWorldPoints(self.objects.rightWall.shape:getPoints())); 
  Graphics.setColor(1, 1, 1);
  Graphics.draw(
    self.player.animation[self.player.currentAnimation].spriteSheet,
    self.player.animation[self.player.currentAnimation].GetCurrentFrame(), 
    self.player.position.x - self.player.width / 2, self.player.position.y - self.player.height / 2, 
    math.rad(self.player.rotation), 
    self.player.scale.x, self.player.scale.y);

  -- Update effects
  for _, e in pairs(self.effects) do
    local r,g,b,a = unpack(e.color);
    a = e.life / e.lifespan;
    Graphics.setColor(r,g,b,a);
    Graphics.draw(e.image, e.position.x, e.position.y);
  end
  Graphics.setColor(1,1,1,1);

  -- Update attacks
  for _, a in pairs(self.attacks) do
    local rv,gv,bv,av = unpack(a.color);
    av = a.life / a.lifespan;
    Graphics.setColor(rv,gv,bv,av);
    love.graphics.line(a.start.x, a.start.y, a.stop.x,  a.stop.y);
  end
  Graphics.setColor(1,1,1,1);

  -- Draw boxes
  for _, a in pairs(self.enemies) do
    love.graphics.setColor(0.20, 0.20, 0.20) -- set the drawing color to grey for the blocks
    love.graphics.polygon("fill", a.object.body:getWorldPoints(a.object.shape:getPoints()))
  end
end


function Scene:Update(dt)
  if self.player.onGround == true then
    self.player.forceUp = self.player.forceUpReset;
  end

  -- Physics Tick
  self:UpdatePlayerInput(dt);
  self.world:update(dt);
  
  --self.objects.player.body.setAngle(0);
  self.player.position.x = self.objects.player.body:getX();
  self.player.position.y = self.objects.player.body:getY();
  self.player.animation[self.player.currentAnimation].Update(dt);

  -- Update effects
  for _, e in pairs(self.effects) do
    e.life = e.life - dt;
  end

  -- Update attacks
  for _, a in pairs(self.attacks) do
    a.life = a.life - dt;
  end
end

function Scene:KeyPressed(key, scancode, isrepeat)
  local x, y = self.objects.player.body:getLinearVelocity();
  local _punchForce = G * 18000;  

  if key == "w" or key == "up" or key == "space" then
    if self.player.onGround == false then
      self.objects.player.body:applyForce(0 , -self.player.forceUp);
      self.player.forceUp = self.player.forceUp / 2;
      self.player.onGround = false;
    end

    if self.player.onGround == true then
      self.objects.player.body:applyForce(x, G * -25000);
      self.player.onGround = false;
    end
  elseif key == "s" or key == "down" then
    self.objects.player.body:setLinearVelocity(x, 500);
  end
end

function Scene:UpdatePlayerInput(dt)
  local x, y = self.objects.player.body:getLinearVelocity();
  local correctionScalar = Config.inAirCorrection;

  --if not love.keyboard.isDown("right") and not love.keyboard.isDown("left") then
  if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
    self.player.currentAnimation = "right";
    if self.player.onGround == true then
      self.objects.player.body:setLinearVelocity(self.player.speed, y);
    else
      self.objects.player.body:setLinearVelocity(x + self.player.speed * correctionScalar, y);
    end
  elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
    self.player.currentAnimation = "left";
    if self.player.onGround == true then
      self.objects.player.body:setLinearVelocity(-self.player.speed, y);
    else
      self.objects.player.body:setLinearVelocity(x - self.player.speed * correctionScalar, y);
    end
  else 
    self.player.currentAnimation = "idle";
  end
 -- end

  -- Set jumping/falling visuals
  if self.player.onGround == false then
    if x > 0 then
      if y < 0 then
        self.player.currentAnimation = "jumpright";
      else
        self.player.currentAnimation = "slideright";
      end
    else
      if y < 0 then
        self.player.currentAnimation = "jumpleft";
      else
        self.player.currentAnimation = "slideleft";
      end
    end
  end
end
-- Normalize two numbers.
function Normalize(x,y) local l=(x*x+y*y)^.5 if l==0 then return 0,0,0 else return x/l,y/l,l end end

-- Source of the image file to use
-- X and Y position of the effect
-- lifespan of fading effect in seconds
function MakeEffect(imageSrc, xPos, yPos, lifespanTotal)  
  if lifespanTotal == nil then
    lifespanTotal = 1;
  end

  return { 
    image = imageSrc, 
    position = { x = xPos, y = yPos }, 
    color = {1, 1, 1, 1 },
    lifespan = lifespanTotal,
    life = lifespanTotal,
  }
end

function MakeAttack(xStart, yStart, xEnd, yEnd, lifespanTotal)
  if lifespanTotal == nil then
    lifespanTotal = 1;
  end

  return { 
    start = { x = xStart, y = yStart}, 
    stop = { x = xEnd, y = yEnd }, 
    color = {.8, .8, 1, 1 },
    lifespan = lifespanTotal,
    life = lifespanTotal,
  }
end

function Scene:MousePressed(xRaw, yRaw, button)
  local x = xRaw / Config.scale;
  local y = yRaw / Config.scale;
  local pxO = self.objects.player.body:getX();
  local pyO = self.objects.player.body:getY();
  local px = pxO + self.player.width / 2;
  local py = pyO + self.player.height / 2;

  -- Camera shake
  Camera:addShake(2);
  local xn, yn, l = Normalize(x - px, y - py);
  table.insert(self.effects, MakeEffect(self.glitch.image, pxO, pyO, love.math.random(1.5, 2)));
  table.insert(self.attacks, MakeAttack(px, py, x, y, 2));

  -- Push player back a tad, s for scalar
  local s = G * 15000;  
  self.objects.player.body:applyForce(-xn * s, -yn * s);
end





function BeginContact(a, b, coll)
  local _x, _y = coll:getNormal();
  local _aName = a:getUserData();
  local _bName = b:getUserData();
  if _aName == "player" and _bName == "ground" or _aName == "ground" and _bName == "player" then
    Scene.player.onGround = true;
  end
  if _aName == "player" and _bName == "enemy" or _aName == "enemy" and _bName == "player" then
    Scene.player.onGround = true;
  end
  --print("\n"..a:getUserData().." colliding with "..b:getUserData().." with a vector normal of: "..x..", "..y);
end
 
function EndContact(a, b, coll)
  persisting = 0;
  --print(text.."\n"..a:getUserData().." uncolliding with "..b:getUserData());
end
 
function PreSolve(a, b, coll)
  --[[
    if persisting == 0 then    -- only say when they first start touching
        text = text.."\n"..a:getUserData().." touching "..b:getUserData()
    elseif persisting < 20 then    -- then just start counting
        text = text.." "..persisting
    end
    persisting = persisting + 1    -- keep track of how many updates they've been touching for
    ]]--
end
 
function PostSolve(a, b, coll, normalimpulse, tangentimpulse)

end
