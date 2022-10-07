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

local function unclip()
  lcd.setClipping()
end

local function clipHud(x,y,w,h)
  lcd.setClipping(x, y, w, h)
end

local function clipCompassRibbon(x,y,w,h)
  lcd.setClipping(x, y, w, h)
end

function hudLib.drawHud(widget,x,y,w,h)

  local minX = x
  local minY = y

  local maxX = x + w
  local maxY = y + h

  local midX = minX + (w-20)/2
  local midY = minY + h/2

  libs.drawLib.drawArtificialHorizon(minX, minY, w-20, h, status.colors.hudSky, status.colors.hudTerrain, 5, R2)

  -- hashmarks
  clipHud(x,y,w,h)
  local startY = minY
  local endY = maxY
  local step = 22
  -- hSpeed
  local roundHSpeed = math.floor((status.telemetry.hSpeed*status.conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((status.telemetry.hSpeed*status.conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  lcd.color(status.colors.hudDashes)
  lcd.pen(SOLID)

  lcd.font(FONT_S)
  for j=roundHSpeed+30,roundHSpeed-30,-5
  do
      yy = startY + (ii*step) + offset - step
      if yy >= startY and yy < endY then
        lcd.drawLine(x, yy+9, x+6, yy+9)
        lcd.drawNumber(x+9,  yy, j)
      end
      ii=ii+1;
  end
  -- altitude
  local roundAlt = math.floor((status.telemetry.homeAlt*status.conf.distUnitScale/5)+0.5)*5;
  offset = math.floor((status.telemetry.homeAlt*status.conf.distUnitScale-roundAlt)*0.2*step);
  ii = 0;
  yy = 0
  for j=roundAlt+30,roundAlt-30,-5
  do
      yy = startY + (ii*step) + offset - step
      if yy >= startY and yy < endY then
        lcd.drawLine(569, yy+9, 569 + 6 , yy+9)
        libs.drawLib.drawNumber(567,  yy, j, 0, FONT_S, status.colors.hudDashes, RIGHT)
      end
      ii=ii+1;
  end
  unclip() --reset hud clipping
  -- compass ribbon
  clipCompassRibbon(x,y,w-20,80) -- set clipping
  libs.drawLib.drawCompassRibbon(y, widget, w, x, x+w-20, FONT_L, FONT_XXL, 80, 40)
  unclip() -- reset clipping
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  libs.drawLib.drawBitmap(x, y, "hud")

  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*status.telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*99
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if status.telemetry.vSpeed > 0 then
    varioY = 135 - varioH
  else
    varioY = 177
  end
  lcd.color(status.colors.yellow)
  lcd.drawFilledRectangle(maxX-20+1, varioY, 20-1, varioH)

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
    lcd.drawFilledRectangle(490, 177, 90, 28)
  end

  if math.abs(alt) > 999 or alt < -99 then
    libs.drawLib.drawNumber(maxX-1, 135, alt, 0, FONT_XXL, status.colors.hudSideText, RIGHT)
    if status.terrainEnabled == 1 then
      libs.drawLib.drawNumber(maxX-20, 175, homeAlt, 0, FONT_XL, status.colors.white, RIGHT)
    end
  elseif math.abs(alt) >= 10 then
    libs.drawLib.drawNumber(maxX-1, 135, alt, 0, FONT_XXL, status.colors.hudSideText, RIGHT)
    if status.terrainEnabled == 1 then
      libs.drawLib.drawNumber(maxX-20, 175, homeAlt, 0, FONT_XL, status.colors.white, RIGHT)
    end
  else
    libs.drawLib.drawNumber(maxX-1, 135, alt, 1, FONT_XXL, status.colors.hudSideText, RIGHT)
    if status.terrainEnabled == 1 then
      libs.drawLib.drawNumber(maxX-20, 175, homeAlt, 1, FONT_XL, status.colors.white, RIGHT)
    end
  end

  -- telemetry.hSpeed and telemetry.airspeed are in dm/s
  local hSpeed = libs.utils.getMaxValue(status.telemetry.hSpeed,14) * 0.1 * status.conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = status.telemetry.airspeed * 0.1 * status.conf.horSpeedMultiplier
    lcd.color(status.colors.black)
    lcd.pen(SOLID)
    lcd.drawFilledRectangle(x, 177, 90, 28)
    libs.drawLib.drawText(x+90, 177, "GS", FONT_S, status.colors.white,RIGHT)
  end

  if (math.abs(speed) >= 10) then
    libs.drawLib.drawNumber(x+2, 135, speed, 0, FONT_XXL, status.colors.hudSideText)
    if status.airspeedEnabled == 1 then
      libs.drawLib.drawNumber(x+2, 175, hSpeed, 0, FONT_XL, status.colors.white)
    end
  else
    libs.drawLib.drawNumber(x+2, 135, speed, 1, FONT_XXL, status.colors.hudSideText)
    if status.airspeedEnabled == 1 then
      libs.drawLib.drawNumber(x+2, 175, hSpeed, 1, FONT_XL, status.colors.white)
    end
  end
  --]]

  -- wind
  if status.conf.enableWIND == true then
    lcd.color(status.colors.black)
    lcd.pen(SOLID)
    lcd.drawFilledRectangle(x, 248, 90, 28)
    libs.drawLib.drawText(x + 90, 248,"WS",FONT_S,status.colors.white,RIGHT)
    local wind = status.telemetry.trueWindSpeed*status.conf.horSpeedMultiplier*0.1
    if math.abs(wind) >= 10 then
      libs.drawLib.drawNumber(x+2,246,wind,0,FONT_XL,status.colors.white)
    else
      libs.drawLib.drawNumber(x+2,246,wind,1,FONT_XL,status.colors.white)
    end
  end

  -- vspeed box
  local vSpeed = libs.utils.getMaxValue(status.telemetry.vSpeed,13) * 0.1 -- m/s

  if math.abs(vSpeed*status.conf.vertSpeedMultiplier*10) > 99 then --
    libs.drawLib.drawNumber(390, 235, vSpeed*status.conf.vertSpeedMultiplier, 0, FONT_XXL, status.colors.white, CENTERED)
  else
    libs.drawLib.drawNumber(390, 235, vSpeed*status.conf.vertSpeedMultiplier, 1, FONT_XXL, status.colors.white, CENTERED)
  end
  --]]
  -- pitch and roll

  libs.drawLib.drawNumber(390,164,status.telemetry.pitch,0,FONT_STD,status.colors.black, CENTERED)
  libs.drawLib.drawNumber(358,144,status.telemetry.roll,0,FONT_STD,status.colors.black, RIGHT)





  -- wind arrow
  if status.conf.enableWIND == true then
    libs.drawLib.drawWindArrow(midX,  midY, 41,  73,  63,  status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.black);
    libs.drawLib.drawWindArrow(midX,  midY, 43,  69,  58,  status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.white);
    libs.drawLib.drawWindArrow(midX,  midY, 48,  69,  58,  status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.white);
    libs.drawLib.drawWindArrow(midX,  midY, 50, 73, 63, status.telemetry.trueWindAngle-status.telemetry.yaw, 1.3, status.colors.black);
  end
end

function hudLib.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return hudLib
end

return hudLib
