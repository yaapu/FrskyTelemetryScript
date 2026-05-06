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

-- zoom factor
local zoom = 0.5
-- last n point circulart buffer
local xPoints = {}
local yPoints = {}

local sample = 0
local sampleCount = 0
local lastSample = getTime()

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
  libs.drawLib.drawLineWithClippingXY(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClippingXY(x1,y1,x3,y3,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClippingXY(x2,y2,x4,y4,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClippingXY(x3,y3,x4,y4,style,xmin,xmax,ymin,ymax,color)
end

local function updateMyPosition(widget)
  -- calculate new absolute position
  if telemetry.homeAngle >= 0 then
    myX = telemetry.homeDist*math.cos(math.rad(telemetry.homeAngle-270))
    myY = telemetry.homeDist*math.sin(math.rad(telemetry.homeAngle-270))

    myScreenX = zoom*myX + originX;
    myScreenY = zoom*myY + originY;
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

local function dist(x1,y1,x2,y2)
  return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

function panel.draw(widget)
  local minX = (LCD_W-280)/2
  local minY = 18

  local maxX = (LCD_W-280)/2 + 280
  local maxY = 18 + 134

  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x63, 0x30, 0x00)) --623000 old brown
  lcd.drawFilledRectangle(minX,minY,280,maxY - minY,CUSTOM_COLOR)

  updateMyPosition(widget)

  lcd.setColor(CUSTOM_COLOR,utils.colors.grey)

  -- lets check if vehicle is about to exit viewport
  local myCode = libs.drawLib.computeOutCode(myScreenX, myScreenY, minX+20, minY+20,maxX-20, maxY-20);

  if bit32.band(myCode,1) == 1 then
    -- vehicle at left border
    -- can we shift and center or should we lower zoom factor?
    local newOriginX = (LCD_W-280)/2+280/2 - (zoom*myX*0.5);
    -- let's check if home would be visible
    local homeCode = libs.drawLib.computeOutCode(newOriginX, originY, minX+20, minY+20,maxX-20, maxY-20);
    -- vehicle is far left, would home leave viewport on the right?
    if bit32.band(homeCode,2) == 2 then
      -- yes -> zoom out!
      zoom = zoom * 0.95
    end
    -- center vehicle
    originX = (LCD_W-280)/2+280/2 - (zoom*myX*0.5);
  end

  if bit32.band(myCode,2) == 2 then
    -- vehicle at right border
    -- can we shift and center or should we lower zoom factor?
    local newOriginX = (LCD_W-280)/2+280/2 - (zoom*myX*0.5);
    -- let's check if home would be visible
    local homeCode = libs.drawLib.computeOutCode(newOriginX, originY, minX+20, minY+20,maxX-20, maxY-20);
    -- vehicle is far right, would home leave viewport on the left?
    if bit32.band(homeCode,1)  == 1 then
      -- yes -> zoom out!
      zoom = zoom * 0.95
    end
    -- center vehicle
    originX = (LCD_W-280)/2+280/2 - (zoom*myX*0.5);
  end

  if bit32.band(myCode,8) == 8 then
    -- vehicle at top border
    -- can we shift and center or should we lower zoom factor?
    local newOriginY = 18+134/2 - (zoom*myY*0.5);
    -- let's check if home would be visible
    local homeCode = libs.drawLib.computeOutCode(originX, newOriginY, minX+20, minY+20,maxX-20, maxY-20);
    -- vehicle is at the top, would home leave viewport on the bottom?
    if bit32.band(homeCode,4) == 4 then
      -- yes -> zoom out!
      zoom = zoom * 0.95
    end
    -- center vehicle
    originY = 18+134/2 - (zoom*myY*0.5);
  end

  if bit32.band(myCode,4) == 4 then
    -- vehicle at bottom border
    -- can we shift and center or should we lower zoom factor?
    local newOriginY = 18+134/2 - (zoom*myY*0.5);
    -- let's check if home would be visible
    local homeCode = libs.drawLib.computeOutCode(originX, newOriginY, minX+20, minY+20,maxX-20, maxY-20);
    -- vehicle is at the bottom, would home leave viewport at the top?
    if bit32.band(homeCode,8) == 8 then
      -- yes -> zoom out!
      zoom = zoom * 0.95
    end
    -- center vehicle
    originY = 18+134/2 - (zoom*myY*0.5);
  end

  libs.drawLib.drawHomeIcon(originX-20/2,originY-20/2)

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

  lcd.drawText((LCD_W-280)/2,18,string.format("zoom:%.02f",zoom),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText((LCD_W-280)/2,18+15,string.format("dist:%d",telemetry.homeDist),SMLSIZE+CUSTOM_COLOR)
  --[[

  lcd.drawText(HUD_X,HUD_Y+30,string.format("myX:%d",myX),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+60,string.format("myY:%d",myY),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+80,string.format("myScreenX:%d",myScreenX),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+100,string.format("myScreenY:%d",myScreenY),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+80,string.format("myScreenX:%d",myScreenX),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(HUD_X,HUD_Y+100,string.format("myScreenY:%d",myScreenY),SMLSIZE+CUSTOM_COLOR)

  lcd.drawText(HUD_X,HUD_Y+120,string.format("avgDistSum:%d",avgDistSum),SMLSIZE+CUSTOM_COLOR)

  for a=0, math.min(avgDistSampleCount-1,DIST_SAMPLES-1)
  do
    lcd.drawNumber(350,20+a*15,avgDistSamples[a] == nil and -1 or avgDistSamples[a],SMLSIZE+CUSTOM_COLOR)
  end
  --]]
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  if dist(myScreenX, myScreenY, originX, originY) < 134/2 then
    if zoom < 0.5 then
      zoom = math.min(zoom * 1.1, 0.5)
    end
  end
end

function panel.background(widget)
end

return panel
