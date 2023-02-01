--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Horus class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

---------------------------------
-- Note: Home is absolute origin
---------------------------------

-- home relative vehicle coordinates
local myX = 0
local myY = 0

-- viewport relative vehicle coordinates
local myScreenX = 0
local myScreenY = 0

-- absolute viewport home offset
local originX = (LCD_W-280)/2+280/2
local originY = 18+134/2

-- size of grid in pixel
local tileSize = 50
-- zoom factor
local zoom = 0.5
-- last n point circulart buffer
local xPoints = {}
local yPoints = {}

local sample = 0
local sampleCount = 0
local lastSample = getTime()

local avgDistSamples = {}

avgDistSamples[0] = 0

local avgDist = 0;
local avgDistSum = 0;
local avgDistSample = 0;
local avgDistSampleCount = 0;
local avgDistLastSampleTime = getTime();

local panel = {}

local conf
local telemetry
local status
local utils
local libs

function panel.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

local function drawVehicle(x,y,r,angle,style,xmin,xmax,ymin,ymax,color)
  local x1 = x + r * math.cos(math.rad(angle - 90))
  local y1 = y + r * math.sin(math.rad(angle - 90))
  local x2 = x + r * math.cos(math.rad(angle - 90 + 150))
  local y2 = y + r * math.sin(math.rad(angle - 90 + 150))
  local x3 = x + r * math.cos(math.rad(angle - 90 - 150))
  local y3 = y + r * math.sin(math.rad(angle - 90 - 150))
  local x4 = x + r * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = y + r * 0.5 *math.sin(math.rad(angle - 270))
  --
  libs.drawLib.drawLineWithClipping(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClipping(x1,y1,x3,y3,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClipping(x2,y2,x4,y4,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClipping(x3,y3,x4,y4,style,xmin,xmax,ymin,ymax,color)
end

local function updateMyPosition(widget)
  -- calculate new absolute position
  if telemetry.homeAngle >= 0 then
    myX = telemetry.homeDist*math.cos(math.rad(telemetry.homeAngle-270))
    myY = telemetry.homeDist*math.sin(math.rad(telemetry.homeAngle-270))

    myScreenX = zoom*myX + originX;
    myScreenY = zoom*myY + originY;
  end

  if getTime() - avgDistLastSampleTime > 20 then
    avgDistSamples[avgDistSample] = telemetry.homeDist
    avgDistSampleCount = avgDistSampleCount+1
    avgDistSample = avgDistSampleCount%10
    avgDistLastSampleTime = getTime()

    avgDistSum = 0
    local samples=math.min(avgDistSampleCount,10)-1
    for s=0,samples
    do
      avgDistSum = avgDistSum+avgDistSamples[s]
    end
    avgDist=avgDistSum/(samples+1)
  end
  -- update last n positioins buffer
  if getTime() - lastSample > 50 then
    xPoints[sample] = myX
    yPoints[sample] = myY
    sampleCount = sampleCount+1
    sample = sampleCount%20
    lastSample = getTime()
  end
end

function panel.draw(widget)

  local minY = 18
  local maxY = 18 + 134

  local minX = (LCD_W-280)/2
  local maxX = (LCD_W-280)/2 + 280

  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x63, 0x30, 0x00)) --623000 old brown
  lcd.drawFilledRectangle(minX,minY,280,maxY - minY,CUSTOM_COLOR)
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  --
  updateMyPosition(widget)

  -- draw the tile grids
  local myTileSize = tileSize*zoom

  lcd.setColor(CUSTOM_COLOR,utils.colors.grey)

  local myCode = libs.drawLib.computeOutCode(myScreenX, myScreenY, minX+20, minY+20,maxX-20, maxY-20);

  -- center vehicle on screen
  if myCode == 1 or myCode == 2 or myCode == 8 or myCode == 4 then
      originX = (LCD_W-280)/2+280/2 - zoom*myX;
      originY = 18+134/2 - zoom*myY
  end


  -- round minX to closest tileSize multiple
  local xStart = (LCD_W-280)/2 + 280/2 + 10 - (1+math.floor(280/2/tileSize))*tileSize
  local xOffset = xStart + originX%myTileSize

  for v=0,1+280/myTileSize
  do
    libs.drawLib.drawLineWithClipping(xOffset+v*myTileSize,minY,xOffset+v*myTileSize,maxY,SOLID,minX+1,maxX-1,minY+1,maxY-1,CUSTOM_COLOR)
  end

  local yStart = 18 + 134/2 + 1.5*10 - (1+math.floor(134/2/tileSize))*tileSize
  local yOffset = yStart + originY%myTileSize
  for h=0,1+134/myTileSize
  do
    libs.drawLib.drawLineWithClipping(minX,yOffset+h*myTileSize,maxX,yOffset+h*myTileSize,SOLID,minX+1,maxX-1,minY+1,maxY-1,CUSTOM_COLOR)
  end

  local homeCode = libs.drawLib.computeOutCode(originX, originY, minX+10, minY+10,maxX-10, maxY-10);

  local originXclip = originX;
  local originYclip = originY;

  if bit32.band(homeCode,1) == 1 then
    originXclip = minX+10;
  end
  if bit32.band(homeCode,2) == 2 then
    originXclip = maxX-10;
  end
  if bit32.band(homeCode,8) == 8 then
      originYclip = minY+10;
  end
  if bit32.band(homeCode,4) == 4 then
    originYclip = maxY-10;
  end

  if originXclip ~= originX or originYclip ~= originY then
    utils.drawBlinkBitmap("minihomeorange",originXclip-10/2,originYclip-10/2)
  else
    libs.drawLib.drawHomeIcon(originXclip-10/2,originYclip-10/2,utils)
  end

  -- last n points
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  for p=0, math.min(sampleCount-1,20-1)
  do
    local xx = zoom*xPoints[p] + originX;
    local yy = zoom*yPoints[p] + originY;
    if (xx ~= myScreenX or yy ~= myScreenY) and libs.drawLib.computeOutCode(xx, yy, minX+3, minY+3, maxX-3, maxY-3) == 0 then
        lcd.drawFilledRectangle(xx,yy,2,2,CUSTOM_COLOR)
    end
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  drawVehicle(myScreenX, myScreenY, 20, telemetry.yaw, SOLID, minX, maxX, minY, maxY, CUSTOM_COLOR)

  --[[
  lcd.drawText(HUD_X,HUD_Y,string.format("yaw:%d",telemetry.yaw),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+15,string.format("angle:%d",telemetry.homeAngle),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+30,string.format("myX:%d",myX),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+60,string.format("myY:%d",myY),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+80,string.format("myScreenX:%d",myScreenX),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+100,string.format("myScreenY:%d",myScreenY),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+80,string.format("myScreenX:%d",myScreenX),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+100,string.format("myScreenY:%d",myScreenY),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+120,string.format("avgDistSum:%d",avgDistSum),SMLSIZE+CUSTOM_COLOR)
  --]]
  lcd.drawNumber((LCD_W-280)/2,18+140,avgDist,SMLSIZE+CUSTOM_COLOR)

  --[[
  for a=0, math.min(avgDistSampleCount-1,DIST_SAMPLES-1)
  do
    lcd.drawNumber(350,20+a*15,avgDistSamples[a] == nil and -1 or avgDistSamples[a],SMLSIZE+CUSTOM_COLOR)
  end
  --]]
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
end

function panel.background(widget)
end

return panel
