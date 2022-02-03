--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Ethos OS
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

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local status = nil
local libs = nil

local hudLib = {}

local R2 = 18.5

local HUD_W = 292 --340
local HUD_H = 198 --160
local HUD_MIN_X = (784 - HUD_W)/2
local HUD_MIN_Y = 36
local HUD_MAX_X = HUD_MIN_X + HUD_W
local HUD_MAX_Y = HUD_MIN_Y + HUD_H
local HUD_MID_X = HUD_MIN_X + HUD_W/2 - 6
local HUD_MID_Y = HUD_MIN_Y + HUD_H/2

local function unclip()
  lcd.setClipping()
end

local function clipHud(reset)
  lcd.setClipping(HUD_MIN_X, HUD_MIN_Y, HUD_W, HUD_H)
end

local function clipCompassRibbon()
  lcd.setClipping(HUD_MIN_X, HUD_MIN_Y, 280, 42)
end

function hudLib.drawHud(widget)
  local minX = HUD_MIN_X
  local minY = HUD_MIN_Y

  local maxX = HUD_MAX_X
  local maxY = HUD_MAX_Y

  libs.drawLib.drawArtificialHorizon(minX, minY, HUD_W-12, HUD_H, status.colors.hudSky, status.colors.hudTerrain, 5, R2)

  -- hashmarks
  clipHud() -- tru
  local startY = minY
  local endY = maxY
  local step = 26
  -- hSpeed
  local roundHSpeed = math.floor((status.telemetry.hSpeed*status.conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((status.telemetry.hSpeed*status.conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  lcd.color(status.colors.hudDashes)
  lcd.pen(SOLID)
  lcd.font(FONT_S)
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine(HUD_MIN_X, yy+9, HUD_MIN_X+6, yy+9)
        lcd.drawNumber(HUD_MIN_X+9,  yy, j)
      end
      ii=ii+1;
  end
  -- altitude
  local roundAlt = math.floor((status.telemetry.homeAlt*status.conf.distUnitScale/5)+0.5)*5;
  offset = math.floor((status.telemetry.homeAlt*status.conf.distUnitScale-roundAlt)*0.2*step);
  ii = 0;
  yy = 0
  for j=roundAlt+20,roundAlt-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine(518, yy+8, 524 , yy+8)
        libs.drawLib.drawNumber(516,  yy, j, 0, FONT_S, status.colors.hudDashes, RIGHT)
      end
      ii=ii+1;
  end
  unclip() --reset hud clipping
  -- compass ribbon
  clipCompassRibbon() -- set clipping
  libs.drawLib.drawCompassRibbon(minY,widget,300,minX,maxX-10)
  unclip() -- reset clipping
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  libs.drawLib.drawBitmap(minX, minY, "hud_298x198")

  if status.conf.enableWIND == true then
    libs.drawLib.drawWindArrow(HUD_MID_X,134,33,49,50,status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.white);
    libs.drawLib.drawWindArrow(HUD_MID_X,134,38,49,50,status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.white);
    libs.drawLib.drawWindArrow(HUD_MID_X,134,31,51,53,status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.black);
    libs.drawLib.drawWindArrow(HUD_MID_X,134,40,51,53,status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.black);
  end

  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*status.telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*78
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if status.telemetry.vSpeed > 0 then
    varioY = 114 - varioH
  else
    varioY = 156
  end
  lcd.color(status.colors.yellow)
  lcd.drawFilledRectangle(528, varioY, 14, varioH)

  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  -- altitude
  local homeAlt = libs.utils.getMaxValue(status.telemetry.homeAlt,11) * status.conf.distUnitScale
  local alt = homeAlt
  if status.terrainEnabled == 1 then
    alt = status.telemetry.heightAboveTerrain * status.conf.distUnitScale
    lcd.color(status.colors.black)
    lcd.drawFilledRectangle(446, 156, 80, 18)
  end

  if math.abs(alt) > 999 or alt < -99 then
    libs.drawLib.drawNumber(HUD_MAX_X-1, 114, alt, 0, FONT_XXL, status.colors.hudSideText, RIGHT)
    if status.terrainEnabled == 1 then
      libs.drawLib.drawNumber(HUD_MAX_X-12, 152, alt, 0, FONT_STD, status.colors.hudSideText, RIGHT)
    end
  elseif math.abs(alt) >= 10 then
    libs.drawLib.drawNumber(HUD_MAX_X-1, 114, alt, 0, FONT_XXL, status.colors.hudSideText, RIGHT)
    if status.terrainEnabled == 1 then
      libs.drawLib.drawNumber(HUD_MAX_X-12, 152, alt, 0, FONT_STD, status.colors.hudSideText, RIGHT)
    end
  else
    libs.drawLib.drawNumber(HUD_MAX_X-1, 114, alt, 1, FONT_XXL, status.colors.hudSideText, RIGHT)
    if status.terrainEnabled == 1 then
      libs.drawLib.drawNumber(HUD_MAX_X-12, 152, alt, 1, FONT_STD, status.colors.hudSideText, RIGHT)
    end
  end

  -- telemetry.hSpeed and telemetry.airspeed are in dm/s
  local hSpeed = libs.utils.getMaxValue(status.telemetry.hSpeed,14) * 0.1 * status.conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = status.telemetry.airspeed * 0.1 * status.conf.horSpeedMultiplier
    lcd.color(status.colors.black)
    lcd.pen(SOLID)
    lcd.drawFilledRectangle(HUD_MIN_X, 156, 80, 18)
    libs.drawLib.drawText(HUD_MIN_X+78, 159, "G", FONT_S, status.colors.hudSideText,RIGHT)
  end

  if (math.abs(speed) >= 10) then
    libs.drawLib.drawNumber(HUD_MIN_X+2, 114, speed, 0, FONT_XXL, status.colors.hudSideText)
    if status.airspeedEnabled == 1 then
      libs.drawLib.drawNumber(HUD_MIN_X+2, 152, hSpeed, 0, FONT_STD, status.colors.hudSideText)
    end
  else
    libs.drawLib.drawNumber(HUD_MIN_X+2, 114, speed, 1, FONT_XXL, status.colors.hudSideText)
    if status.airspeedEnabled == 1 then
      libs.drawLib.drawNumber(HUD_MIN_X+2, 152, hSpeed, 1, FONT_STD, status.colors.hudSideText)
    end
  end
  --]]

  -- wind
  if status.conf.enableWIND == true then
    lcd.color(status.colors.black)
    lcd.pen(SOLID)
    lcd.drawFilledRectangle(HUD_MIN_X, 180, 80, 19)
    libs.drawLib.drawText(HUD_MIN_X + 80,184,"W",FONT_S,status.colors.white,RIGHT)
    libs.drawLib.drawNumber(HUD_MIN_X+2,178,status.telemetry.trueWindSpeed*status.conf.horSpeedMultiplier*0.1,1,FONT_STD,status.colors.white)
  end
  --[[
  lcd.color(CUSTOM_COLOR,COLOR_TEXT)
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(168, 73,true,false,utils)
    drawLib.drawVArrow(301, 73,true,false,utils)
  end
  --]]
  -- vspeed box
  local vSpeed = libs.utils.getMaxValue(status.telemetry.vSpeed,13) * 0.1 -- m/s

  if math.abs(vSpeed*status.conf.vertSpeedMultiplier*10) > 99 then --
    libs.drawLib.drawNumber(386, 203, vSpeed*status.conf.vertSpeedMultiplier, 0, FONT_XL, status.colors.white, CENTERED)
  else
    libs.drawLib.drawNumber(386, 203, vSpeed*status.conf.vertSpeedMultiplier, 1, FONT_XL, status.colors.white, CENTERED)
  end
  --]]
  -- pitch and roll
  libs.drawLib.drawNumber(386,142,status.telemetry.pitch,0,FONT_STD,status.colors.white, CENTERED)
  libs.drawLib.drawNumber(360,124,status.telemetry.roll,0,FONT_STD,status.colors.white, RIGHT)
end

function hudLib.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return hudLib
end

return hudLib
