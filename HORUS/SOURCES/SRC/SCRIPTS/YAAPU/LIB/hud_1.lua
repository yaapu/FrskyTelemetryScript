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

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)

  local r = -telemetry.roll
  local cx,cy,dx,dy--,ccx,ccy,cccx,cccy
  local yPos = 28 -- 0 + 20 + 8
  local scale = 1.85 -- 1.85
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 18.5
  if ( telemetry.roll == 0 or math.abs(telemetry.roll) == 180) then
    dx=0
    dy=telemetry.pitch * scale
    cx=0
    cy=18.5
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch * scale
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 18.5
    cy = math.sin(math.rad(90 - r)) * 18.5
  end
  local rollX = math.floor(240) -- math.floor(HUD_X + HUD_WIDTH/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 140x90
  local minY = 18  --HUD_Y
  local maxY = 152 --HUD_Y + HUD_HEIGHT

  local minX = 100 --HUD_X
  local maxX = 380 --HUD_X + HUD_WIDTH

  local ox = 240 + dx --HUD_X + HUD_WIDTH/2 + dx
  local oy = 85 + dy  --HUD_Y_MID + dy
  local yy = 0

  lcd.drawBitmap(utils.getBitmap("hud_bg_280x134"),100,18) --160x90
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


  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, 0xFE60)
    drawLib.drawWindArrow(LCD_W/2,86,30,46,46,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
    drawLib.drawWindArrow(LCD_W/2,86,35,46,46,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
  end
  -- parallel lines above and below horizon
  local linesMaxY = 150 --maxY-2
  local linesMinY = 28  --minY+10
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- +/- 90 deg
  for dist=1,5
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + 85 + dist*cy,r,(dist%2==0 and 80 or 40),DOTTED,102,378,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + 85 - dist*cy,r,(dist%2==0 and 80 or 40),DOTTED,102,378,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end

  --[[
  -- horizon line
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(160,160,160))
  drawLib.drawLineWithClipping(rollX + dx,dy + HUD_Y_MID,r,200, SOLID, HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  --]]

  -- hashmarks
  local startY = minY + 1
  local endY = maxY - 10
  local step = 18
  -- hSpeed
  local roundHSpeed = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(120,120,120))
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine(100, yy+9, 104, yy+9, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(107,  yy, j, SMLSIZE+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  -- altitude
  local roundAlt = math.floor((telemetry.homeAlt*unitScale/5)+0.5)*5;
  offset = math.floor((telemetry.homeAlt*unitScale-roundAlt)*0.2*step);
  ii = 0;
  yy = 0
  for j=roundAlt+20,roundAlt-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine(366, yy+8, 370 , yy+8, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(364,  yy, j, SMLSIZE+RIGHT+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,0xFFFF)

  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_280x134"),100,18)

  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*52
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if telemetry.vSpeed > 0 then
    varioY = 19 + (52 - varioH)
  else
    varioY = 85 + 15
  end
  --00ae10
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0))      --yellow
  -- lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
  -- lcd.setColor(CUSTOM_COLOR,lcd.RGB(50, 50, 50))     --dark grey
  -- lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255))  --white
  lcd.drawFilledRectangle(372, varioY, 8, varioH, CUSTOM_COLOR, 0)

  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  -- altitude
  local homeAlt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  local alt = homeAlt
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 0, 0))
    lcd.drawRectangle(314, 100, 56, 12, SOLID+CUSTOM_COLOR)
    lcd.drawFilledRectangle(314, 100, 56, 12, SOLID, CUSTOM_COLOR)
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green

  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber(381,69,alt,MIDSIZE+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.drawNumber(372,94,homeAlt,CUSTOM_COLOR+RIGHT)
    end
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber(381,65,alt,DBLSIZE+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.drawNumber(372,94,homeAlt,CUSTOM_COLOR+RIGHT)
    end
  else
    lcd.drawNumber(381,65,alt*10,DBLSIZE+PREC1+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.drawNumber(372,94,homeAlt*10,PREC1+CUSTOM_COLOR+RIGHT)
    end
  end
  --

  -- telemetry.hSpeed and telemetry.airspeed are in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 0, 0))
    lcd.drawRectangle(100, 100, 66, 12, SOLID+CUSTOM_COLOR)
    lcd.drawFilledRectangle(100, 100, 66, 12, SOLID, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255))
    lcd.drawText(166,98,"G",CUSTOM_COLOR+SMLSIZE+RIGHT)
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
  if (math.abs(speed) >= 10) then
    lcd.drawNumber(102,65,speed,DBLSIZE+CUSTOM_COLOR)
    if status.airspeedEnabled == 1 then
      lcd.drawNumber(102,94,hSpeed,CUSTOM_COLOR)
    end
  else
    lcd.drawNumber(102,65,speed*10,DBLSIZE+CUSTOM_COLOR+PREC1)
    if status.airspeedEnabled == 1 then
      lcd.drawNumber(102,94,hSpeed*10,CUSTOM_COLOR+PREC1)
    end
  end

  -- wind
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 0, 0))
    lcd.drawRectangle(100, 114, 66, 14, SOLID+CUSTOM_COLOR)
    lcd.drawFilledRectangle(100, 114, 66, 14, SOLID, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFE60)
    lcd.drawText(167,113,"W",CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.drawNumber(103,113,telemetry.trueWindSpeed*conf.horSpeedMultiplier,PREC1+CUSTOM_COLOR+SMLSIZE)
  end


  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(168, 73,true,false,utils)
    drawLib.drawVArrow(301, 73,true,false,utils)
  end

  -- vspeed box
  lcd.setColor(CUSTOM_COLOR,0xFFFF)

  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 -- m/s

  local xx = math.abs(vSpeed*conf.vertSpeedMultiplier) > 999 and 4 or 3
  xx = xx + (vSpeed*conf.vertSpeedMultiplier < 0 and 1 or 0)

  if math.abs(vSpeed*conf.vertSpeedMultiplier*10) > 99 then --
    lcd.drawNumber(240 + (xx/2)*12, 127, vSpeed*conf.vertSpeedMultiplier, MIDSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(240 + (xx/2)*12, 127, vSpeed*conf.vertSpeedMultiplier*10, MIDSIZE+CUSTOM_COLOR+RIGHT+PREC1)
  end

  -- compass ribbon
  drawLib.drawCompassRibbon(18,myWidget,conf,telemetry,status,battery,utils,240,120,360,25,true)
  -- pitch and roll
  lcd.setColor(CUSTOM_COLOR,0xFE60)
  local xoffset =  math.abs(telemetry.pitch) > 99 and 6 or 0
  lcd.drawNumber(248+xoffset,90,telemetry.pitch,CUSTOM_COLOR+SMLSIZE+RIGHT)
  lcd.drawNumber(214,76,telemetry.roll,CUSTOM_COLOR+SMLSIZE+RIGHT)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}
