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

function panel.draw(widget)

  local minY = 18  --HUD_Y
  local maxY = 148 --HUD_Y + HUD_HEIGHT
  local minX = 120 --HUD_X
  local maxX = 360 --HUD_X + HUD_WIDTH

  libs.drawLib.drawArtificialHorizon(minX, minY, 240, 130, "hud_bg", nil, utils.colors.hudTerrain, 5, 18.5, 1.85)

  -- hashmarks
  local startY = minY + 1
  local endY = maxY - 10
  local step = 18
  -- hSpeed
  local roundHSpeed = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  lcd.setColor(CUSTOM_COLOR,utils.colors.hudDash)
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        --lcd.drawLine(120, yy+9, 124, yy+9, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(182,  yy, j, SMLSIZE+CUSTOM_COLOR+RIGHT)
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
        --lcd.drawLine(344, yy+8, 350 , yy+8, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(298,  yy, j, SMLSIZE+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,WHITE)

  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud"),120,18)

  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*50
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if telemetry.vSpeed > 0 then
    varioY = 18 + (50 - varioH)
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  else
    varioY = 97
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  end
  lcd.drawFilledRectangle(349, varioY, 11, varioH, CUSTOM_COLOR)

  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  -- altitude
  local homeAlt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  local alt = homeAlt
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawRectangle(294, 98, 55, 19, CUSTOM_COLOR)
    lcd.drawFilledRectangle(294, 98, 55, 19, CUSTOM_COLOR+SOLID)
  end
  lcd.setColor(CUSTOM_COLOR, utils.colors.green) --green

  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber(294,63,alt,MIDSIZE+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(294,92,homeAlt,CUSTOM_COLOR+LEFT+MIDSIZE)
    end
  elseif math.abs(alt) >= 10 then
    lcd.setColor(CUSTOM_COLOR, utils.colors.green) --green
    lcd.drawNumber(294,63,alt,DBLSIZE+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(294,92,homeAlt,CUSTOM_COLOR+LEFT+MIDSIZE)
    end
  else
    lcd.setColor(CUSTOM_COLOR, utils.colors.green) --green
    lcd.drawNumber(294,63,alt*10,DBLSIZE+PREC1+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(294,92,homeAlt*10,PREC1+CUSTOM_COLOR+LEFT+MIDSIZE)
    end
  end

  -- telemetry.hSpeed and telemetry.airspeed are in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(10,20,30))
    lcd.drawRectangle(120, 98, 66, 19, CUSTOM_COLOR)
    lcd.drawFilledRectangle(120, 98, 66, 19, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(122,96,"G",CUSTOM_COLOR+SMLSIZE+LEFT)
  end
  if (math.abs(speed) >= 10) then
    lcd.setColor(CUSTOM_COLOR,utils.colors.green) --green
    lcd.drawNumber(186,63,speed,DBLSIZE+CUSTOM_COLOR+RIGHT)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(186,92,hSpeed,CUSTOM_COLOR+MIDSIZE+RIGHT)
    end
  else
    lcd.setColor(CUSTOM_COLOR,utils.colors.green) --green
    lcd.drawNumber(186,63,speed*10,DBLSIZE+CUSTOM_COLOR+PREC1+RIGHT)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(186,92,hSpeed*10,CUSTOM_COLOR+PREC1+MIDSIZE+RIGHT)
    end
  end

  -- wind
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawRectangle(120, 128, 66, 21, CUSTOM_COLOR)
    lcd.drawFilledRectangle(120, 128, 66, 21, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(122,129,"W",CUSTOM_COLOR+SMLSIZE+LEFT)
    lcd.drawNumber(186,124,telemetry.trueWindSpeed*conf.horSpeedMultiplier,PREC1+CUSTOM_COLOR+MIDSIZE+RIGHT)
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- min/max arrows
  if status.showMinMaxValues == true then
    libs.drawLib.drawVArrow(168, 73,true,false)
    libs.drawLib.drawVArrow(301, 73,true,false)
  end

  -- vspeed box
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 -- m/s

  local xx = math.abs(vSpeed*conf.vertSpeedMultiplier) > 999 and 4 or 3
  xx = xx + (vSpeed*conf.vertSpeedMultiplier < 0 and 1 or 0)

  if math.abs(vSpeed*conf.vertSpeedMultiplier*10) > 99 then --
    lcd.drawNumber(240 + (xx/2)*12, 123, vSpeed*conf.vertSpeedMultiplier, MIDSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(240 + (xx/2)*12, 123, vSpeed*conf.vertSpeedMultiplier*10, MIDSIZE+CUSTOM_COLOR+RIGHT+PREC1)
  end

  -- compass ribbon
  libs.drawLib.drawCompassRibbon(18,myWidget,220,130,350,25,true,0,utils.colors.compassRibbon)
  -- pitch and roll
  lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
  local xoffset =  math.abs(telemetry.pitch) > 99 and 6 or 0
  lcd.drawNumber(248+xoffset,90,telemetry.pitch,CUSTOM_COLOR+0+RIGHT)
  lcd.drawNumber(216,74,telemetry.roll,CUSTOM_COLOR+0+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
    libs.drawLib.drawWindArrow(LCD_W/2,86,30,46,46,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
    libs.drawLib.drawWindArrow(LCD_W/2,86,35,46,46,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
  end
end

function panel.background(myWidget)
end

return panel
