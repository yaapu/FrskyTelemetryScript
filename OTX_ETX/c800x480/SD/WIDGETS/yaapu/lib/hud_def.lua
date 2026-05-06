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
  -- Match ETHOS c800x480: HUD at x=200, y=36, 400x240
  local minX = 200
  local minY = 36
  local maxX = 600
  local maxY = 276

  libs.drawLib.drawArtificialHorizon(minX, minY, 380, 240, "hud_bg", nil, utils.colors.hudTerrain, 5, 18.5, 1.85)

  -- hashmarks (ETHOS step=22, startY=minY, endY=maxY)
  local startY = minY
  local endY = maxY
  local step = 22
  -- hSpeed
  local roundHSpeed = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  lcd.setColor(CUSTOM_COLOR,utils.colors.hudDash)
  for j=roundHSpeed+30,roundHSpeed-30,-5
  do
      yy = startY + (ii*step) + offset - step
      if yy >= startY and yy < endY then
        lcd.drawNumber(209,  yy, j, SMLSIZE+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  -- altitude (ETHOS: x=567/569)
  local roundAlt = math.floor((telemetry.homeAlt*unitScale/5)+0.5)*5;
  offset = math.floor((telemetry.homeAlt*unitScale-roundAlt)*0.2*step);
  ii = 0;
  yy = 0
  for j=roundAlt+30,roundAlt-30,-5
  do
      yy = startY + (ii*step) + offset - step
      if yy >= startY and yy < endY then
        lcd.drawNumber(567,  yy, j, SMLSIZE+CUSTOM_COLOR+RIGHT)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,WHITE)

  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud"),200,36)

  -------------------------------------
  -- vario (ETHOS: up=135-h, down=177)
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*99
  if telemetry.vSpeed > 0 then
    varioY = 135 - varioH
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  else
    varioY = 177
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  end
  lcd.drawFilledRectangle(581, varioY, 19, varioH, CUSTOM_COLOR)

  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- altitude (ETHOS: maxX-1=599, y=135)
  local homeAlt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  local alt = homeAlt
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawRectangle(490, 177, 90, 28, CUSTOM_COLOR)
    lcd.drawFilledRectangle(490, 177, 90, 28, CUSTOM_COLOR+SOLID)
  end
  lcd.setColor(CUSTOM_COLOR, utils.colors.green)

  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber(599,135,alt,MIDSIZE+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(580,175,homeAlt,CUSTOM_COLOR+RIGHT+MIDSIZE)
    end
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber(599,135,alt,DBLSIZE+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(580,175,homeAlt,CUSTOM_COLOR+RIGHT+MIDSIZE)
    end
  else
    lcd.drawNumber(599,135,alt*10,DBLSIZE+PREC1+CUSTOM_COLOR+RIGHT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(580,175,homeAlt*10,PREC1+CUSTOM_COLOR+RIGHT+MIDSIZE)
    end
  end

  -- speed (ETHOS: x+2=202, y=135)
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(10,20,30))
    lcd.drawRectangle(200, 177, 90, 28, CUSTOM_COLOR)
    lcd.drawFilledRectangle(200, 177, 90, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(202,177,"GS",CUSTOM_COLOR+SMLSIZE+LEFT)
  end
  if (math.abs(speed) >= 10) then
    lcd.setColor(CUSTOM_COLOR,utils.colors.green)
    lcd.drawNumber(202,135,speed,DBLSIZE+CUSTOM_COLOR)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(202,175,hSpeed,CUSTOM_COLOR+MIDSIZE)
    end
  else
    lcd.setColor(CUSTOM_COLOR,utils.colors.green)
    lcd.drawNumber(202,135,speed*10,DBLSIZE+CUSTOM_COLOR+PREC1)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(202,175,hSpeed*10,CUSTOM_COLOR+PREC1+MIDSIZE)
    end
  end

  -- wind (ETHOS: x=200, y=248)
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawRectangle(200, 248, 90, 28, CUSTOM_COLOR)
    lcd.drawFilledRectangle(200, 248, 90, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(290,248,"WS",CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.drawNumber(202,246,telemetry.trueWindSpeed*conf.horSpeedMultiplier*0.1,PREC1+CUSTOM_COLOR+MIDSIZE)
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- min/max arrows
  if status.showMinMaxValues == true then
    libs.drawLib.drawVArrow(220, 148,true,false)
    libs.drawLib.drawVArrow(560, 148,true,false)
  end

  -- vspeed box (ETHOS: x=390, y=235, CENTERED)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 -- m/s

  if math.abs(vSpeed*conf.vertSpeedMultiplier*10) > 99 then
    lcd.drawNumber(390, 235, vSpeed*conf.vertSpeedMultiplier, MIDSIZE+CUSTOM_COLOR+CENTER)
  else
    lcd.drawNumber(390, 235, vSpeed*conf.vertSpeedMultiplier*10, MIDSIZE+CUSTOM_COLOR+CENTER+PREC1)
  end

  -- compass ribbon (ETHOS: y=36, x=200..580)
  libs.drawLib.drawCompassRibbon(36,myWidget,400,200,580,25,true,0,utils.colors.compassRibbon)
  -- pitch and roll (ETHOS: 390,164 / 358,144)
  lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
  local xoffset =  math.abs(telemetry.pitch) > 99 and 6 or 0
  lcd.drawNumber(390+xoffset,164,telemetry.pitch,CUSTOM_COLOR+0+RIGHT)
  lcd.drawNumber(358,144,telemetry.roll,CUSTOM_COLOR+0+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
    libs.drawLib.drawWindArrow(390,156,41,73,63,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
    libs.drawLib.drawWindArrow(390,156,50,73,63,telemetry.trueWindAngle-telemetry.yaw, 1.5, CUSTOM_COLOR);
  end
end

function panel.background(myWidget)
end

return panel
