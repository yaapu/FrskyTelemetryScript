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

function panel.draw(widget, x, battId)
  local colorLabel = lcd.RGB(140, 140, 140)
  --[[
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(5,52,85))
  lcd.drawRectangle(x, 18, 120, 43, CUSTOM_COLOR)
  lcd.drawRectangle(x, 61, 120, 43, CUSTOM_COLOR)
  lcd.drawRectangle(x, 104, 120, 44, CUSTOM_COLOR)
  --]]
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  --lcd.drawBitmap(utils.getBitmap("left_def"),x,18)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if conf.rangeFinderMax > 0 then
    flags = 0
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.drawFilledRectangle(8, 27+4,102,27, CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    lcd.drawText(10, 18, string.format("RANGE %s",unitLabel), SMLSIZE+CUSTOM_COLOR)
    --lcd.drawText(100, 27+10, unitLabel, SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(10, 27, string.format("%.1f",rng*0.01*unitScale), DBLSIZE+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,12)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    lcd.drawText(10, 18, string.format("GALT %s",unitLabel), SMLSIZE+CUSTOM_COLOR)
    --lcd.drawText(100, 27+10, unitLabel, SMLSIZE+CUSTOM_COLOR)
    local stralt = string.format("%d",alt*unitScale)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(10, 27, stralt, DBLSIZE+flags+CUSTOM_COLOR)
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- home distance
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local label = unitLabel
  if dist*unitScale > 999 then
    flags = flags + PREC2
    dist = dist*unitLongScale*100
    label = unitLongLabel
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(10, 60, string.format("HOME %s",label), SMLSIZE+CUSTOM_COLOR)
  --lcd.drawText(100, 69+16, label, SMLSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawNumber(10, 69, dist, DBLSIZE+flags+CUSTOM_COLOR)

  -- total distance
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  --lcd.drawText(100, 113+10, unitLongLabel, SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(10, 104, string.format("TRAVEL %s",unitLongLabel), SMLSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local mult = telemetry.totalDist*unitLongScale > 99 and 10 or 100
  local prec = telemetry.totalDist*unitLongScale > 99 and PREC1 or PREC2
  lcd.drawNumber(10, 113, telemetry.totalDist*unitLongScale*mult, prec+DBLSIZE+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    libs.drawLib.drawVArrow(4, 27 + 4,true,false)
    libs.drawLib.drawVArrow(4, 69 + 4 ,true,false)
  end
end

function panel.background(myWidget)
end

return panel
