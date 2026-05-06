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
--# include "includes/layout_def_inc.lua"
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

function panel.draw(widget, x, y, battId)
  local colorLabel = lcd.RGB(140, 140, 140)
  local flags = 0
  if conf.rangeFinderMax > 0 then
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    lcd.drawText(x+10, y+-4, "RNG "..unitLabel, SMLSIZE+CUSTOM_COLOR)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.setColor(CUSTOM_COLOR,utils.colors.red)
      lcd.drawFilledRectangle(x+10-65, y+5+4,65,21,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(x+10, y+5, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+flags+CUSTOM_COLOR)
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
    lcd.drawText(x+10, y+-4, "GALT "..unitLabel, SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawNumber(x+10, y+5, alt*unitScale, MIDSIZE+flags+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(x+10, y+31, "HOME-TRAVEL", SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(x+10, y+81, "WP "..unitLabel, SMLSIZE+CUSTOM_COLOR)
  -- VALUES
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
  local strdist = string.format("%d%s",dist*unitScale,unitLabel)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  if dist < 999 then
    lcd.drawText(x+10, y+40, strdist, MIDSIZE+flags+CUSTOM_COLOR)
  else
    lcd.drawText(x+10, y+40, string.format("%0.2f%s", dist*unitLongScale, unitLongLabel), MIDSIZE+flags+CUSTOM_COLOR)
  end
  -- total distance
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(x+10, y+62, string.format("%0.2f%s", telemetry.totalDist*unitLongScale, unitLongLabel), SMLSIZE+CUSTOM_COLOR+PREC2)
  -- draw WP info only for supported flight modes
  -- AUTO, GUIDED, LOITER, RTL, QRTL, QLOITER, QLAND, FOLLOW, ZIGZAG
  if status.wpEnabledMode == 1 then
    -- wp number
    lcd.drawText(x+10, y+112, string.format("#%d",telemetry.wpNumber),SMLSIZE+CUSTOM_COLOR)
    -- wp distance
    lcd.drawNumber(x+10, y+91, telemetry.wpDistance * unitScale,MIDSIZE+CUSTOM_COLOR)
    -- LINES
    lcd.setColor(CUSTOM_COLOR,utils.colors.white) --yellow
    -- wp bearing
    libs.drawLib.drawRVehicle(x+100,y+112,13,telemetry.wpOffsetFromCog,CUSTOM_COLOR)
  else
    -- wp number
    lcd.drawText(x+10, y+112, "# ---",SMLSIZE+CUSTOM_COLOR)
    -- wp distance
    lcd.drawText(x+10, y+91, "---",MIDSIZE+CUSTOM_COLOR)
    -- LINES
    lcd.setColor(CUSTOM_COLOR,utils.colors.white) --yellow
    -- wp bearing
    libs.drawLib.drawRVehicle(x+100, y+112, 13, 0, CUSTOM_COLOR)
  end

  if status.showMinMaxValues == true then
    libs.drawLib.drawVArrow(x+3, y+5+4,true,false)
    libs.drawLib.drawVArrow(x+3, y+40+4 ,true,false)
  end
end

function panel.background(myWidget)
  -- RC CHANNELS
  --[[
  if conf.enableRCChannels == true then
    for i=1,#telemetry.rcchannels do
      setTelemetryValue(Thr_ID, Thr_SUBID, Thr_INSTANCE + i, telemetry.rcchannels[i], 13 , Thr_PRECISION , "RC"..i)
    end
  end
  --]]

  -- WP
  setTelemetryValue(0x050F, 0, 10, telemetry.wpNumber, 0 , 0 , "WPN")
  setTelemetryValue(0x082F, 0, 10, telemetry.wpDistance, 9 , 0 , "WPD")
end

return panel
