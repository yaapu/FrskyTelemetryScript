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


local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)--getMaxValue,getBitmap,drawBlinkBitmap)

  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = 0 + 20 + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 11
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch
    cx=0
    cy=11
    ccx=0
    ccy=2*11
    cccx=0
    cccy=3*11
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 11
    cy = math.sin(math.rad(90 - r)) * 11
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * 11
    ccy = math.sin(math.rad(90 - r)) * 2 * 11
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * 11
    cccy = math.sin(math.rad(90 - r)) * 3 * 11
  end
  local rollX = math.floor((LCD_W-92)/2 + 92/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 90x70
  local minY = 30
  local maxY = 30+70
  --
  local minX = (LCD_W-92)/2
  local maxX = (LCD_W-92)/2 + 92
  --
  local ox = (LCD_W-92)/2 + 92/2 + dx
  --
  local oy = 30+70/2 + dy
  local yy = 0

    --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x0d, 0x68, 0xb1)) -- bighud blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.drawFilledRectangle(minX,minY,maxX-minX,maxY - minY,CUSTOM_COLOR)
  -- HUD
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(77, 153, 0))
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x90, 0x63, 0x20)) --906320 bighud brown
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x63, 0x30, 0x00)) --623000 old brown
  
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- prevent divide by zero
  if telemetry.roll == 0 then
    drawLib.drawFilledRectangle(minX,math.max(minY,dy+minY+(maxY-minY)/2),maxX-minX,math.min(maxY-minY,(maxY-minY)/2-dy+(math.abs(dy) > 0 and 1 or 0)),CUSTOM_COLOR)
  elseif math.abs(telemetry.roll) >= 180 then
    drawLib.drawFilledRectangle(minX,minY,maxX-minX,math.min(maxY-minY,(maxY-minY)/2+dy),CUSTOM_COLOR)
  else
    -- HUD drawn using horizontal bars of height 2
    -- true if flying inverted
    local inverted = math.abs(telemetry.roll) > 90
    -- true if part of the hud can be filled in one pass with a rectangle
    local fillNeeded = false
    local yRect = inverted and 0 or LCD_H
    
    local step = 2
    local steps = (maxY - minY)/step - 1
    local yy = 0
    
    if 0 < telemetry.roll and telemetry.roll < 180 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step,CUSTOM_COLOR)
        elseif xx < minX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    elseif -180 < telemetry.roll and telemetry.roll < 0 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(minX, yy, xx-minX, step,CUSTOM_COLOR)
        elseif xx > maxX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    end
    
    if fillNeeded then
      local yMin = inverted and minY or yRect
      local height = inverted and yRect - minY or maxY-yRect
      --lcd.setColor(CUSTOM_COLOR,0xF800) --623000 old brown
      lcd.drawFilledRectangle(minX, yMin, maxX-minX, height ,CUSTOM_COLOR)
    end
  end


  -- parallel lines above and below horizon
  local linesMaxY = maxY-1
  local linesMinY = minY+1
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- +/- 90 deg
  for dist=1,8
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + 30+70/2 + dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,(LCD_W-92)/2+2,(LCD_W-92)/2+92-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + 30+70/2 - dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,(LCD_W-92)/2+2,(LCD_W-92)/2+92-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_90x70a"),(LCD_W-106)/2,30-10) --106x90
  -------------------------------------
  -- vario bitmap
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = 0
  if telemetry.vSpeed > 0 then
    varioY = 20+46 - varioSpeed/varioMax*40
  else
    varioY = 20+45
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0))
  lcd.drawFilledRectangle(275+26, varioY, 7, varioSpeed/varioMax*39, CUSTOM_COLOR, 0)
  lcd.drawBitmap(utils.getBitmap("variogauge_90"),275,20)

  if telemetry.vSpeed > 0 then
    lcd.drawBitmap(utils.getBitmap("varioline"),275+21,varioY-1)
  else
    lcd.drawBitmap(utils.getBitmap("varioline"),275+21,20+44 + varioSpeed/varioMax*39)
  end
  -- compass ribbon
  drawLib.drawCompassRibbon(115,myWidget,conf,telemetry,status,battery,utils,140,(LCD_W-140)/2,(LCD_W+140)/2,15)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}
