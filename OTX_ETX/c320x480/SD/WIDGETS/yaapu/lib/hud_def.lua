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

  local minY = 36  --HUD_Y
  local maxY = 176 --HUD_Y + HUD_HEIGHT
  local minX = 0 --HUD_X
  local maxX = 320 --HUD_X + HUD_WIDTH

  libs.drawLib.drawArtificialHorizon(minX, minY, 320, 140, "hud_bg", nil, utils.colors.hudTerrain, 9, 18.5, 1.85)

  -- hashmarks
  local startY = minY
  local endY = maxY - 10
  local step = 19
  -- hSpeed
  local roundHSpeed = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(200,200,200))
  lcd.setColor(CUSTOM_COLOR, utils.colors.hudDash)
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawNumber(92,  yy, j, SMLSIZE+CUSTOM_COLOR)
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
        lcd.drawNumber(229,  yy, j, SMLSIZE+RIGHT+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,WHITE)

  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud"),0,36)

  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*70
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if telemetry.vSpeed > 0 then
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    varioY = 106 - varioH
  else
    varioY = 106 --37 + 84
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  end
  lcd.drawFilledRectangle(305, varioY, 14, varioH, CUSTOM_COLOR)

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
    lcd.drawRectangle(232, 120, 72, 19, CUSTOM_COLOR)
    lcd.drawFilledRectangle(232, 120, 72, 19, CUSTOM_COLOR+SOLID)
  end
  lcd.setColor(CUSTOM_COLOR, utils.colors.green) --green

  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber(234,85,alt,MIDSIZE+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(234,114,homeAlt,CUSTOM_COLOR+LEFT+MIDSIZE)
    end
  elseif math.abs(alt) >= 10 then
    lcd.setColor(CUSTOM_COLOR, utils.colors.green) --green
    lcd.drawNumber(234,85,alt,DBLSIZE+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(234,114,homeAlt,CUSTOM_COLOR+LEFT+MIDSIZE)
    end
  else
    lcd.setColor(CUSTOM_COLOR, utils.colors.green) --green
    lcd.drawNumber(234,85,alt*10,DBLSIZE+PREC1+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(234,114,homeAlt*10,PREC1+CUSTOM_COLOR+LEFT+MIDSIZE)
    end
  end

  -- telemetry.hSpeed and telemetry.airspeed are in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(10,20,30))
    lcd.drawRectangle(0, 120, 87, 19, CUSTOM_COLOR)
    lcd.drawFilledRectangle(0, 120, 87, 19, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(4,116,"G",CUSTOM_COLOR+SMLSIZE+LEFT)
  end
  if (math.abs(speed) >= 10) then
    lcd.setColor(CUSTOM_COLOR,utils.colors.green) --green
    lcd.drawNumber(84,85,speed,DBLSIZE+CUSTOM_COLOR+RIGHT)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(84,114,hSpeed,CUSTOM_COLOR+MIDSIZE+RIGHT)
    end
  else
    lcd.setColor(CUSTOM_COLOR,utils.colors.green) --green
    lcd.drawNumber(84,85,speed*10,DBLSIZE+CUSTOM_COLOR+PREC1+RIGHT)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(84,114,hSpeed*10,CUSTOM_COLOR+PREC1+MIDSIZE+RIGHT)
    end
  end

  -- wind
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawRectangle(0, 155, 87, 21, CUSTOM_COLOR)
    lcd.drawFilledRectangle(0, 155, 87, 21, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(4,154,"W",CUSTOM_COLOR+SMLSIZE+LEFT)
    lcd.drawNumber(84,152,telemetry.trueWindSpeed*conf.horSpeedMultiplier,PREC1+CUSTOM_COLOR+MIDSIZE+RIGHT)
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

  if math.abs(vSpeed*conf.vertSpeedMultiplier*10) > 99 then --
    lcd.drawNumber(160, 150, vSpeed*conf.vertSpeedMultiplier, MIDSIZE+CUSTOM_COLOR+CENTER)
  else
    lcd.drawNumber(160, 150, vSpeed*conf.vertSpeedMultiplier*10, MIDSIZE+CUSTOM_COLOR+CENTER+PREC1)
  end
  -- compass ribbon
  --function drawLib.drawCompassRibbon(y,myWidget,width,xMin,xMax,stepWidth,bigFont)
  libs.drawLib.drawCompassRibbon(36,myWidget,298,6,304,30,true,MIDSIZE,utils.colors.compassRibbon)
  -- pitch and roll
  lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
  local xoffset =  math.abs(telemetry.pitch) > 99 and 6 or 0
  lcd.drawNumber(160+xoffset,112,telemetry.pitch,CUSTOM_COLOR+CENTER)
  lcd.drawNumber(133,96,telemetry.roll,CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
    libs.drawLib.drawWindArrow(160,106,30,46,46,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
    libs.drawLib.drawWindArrow(160,106,35,46,46,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
  end
end

function panel.background(myWidget)
end

return panel
