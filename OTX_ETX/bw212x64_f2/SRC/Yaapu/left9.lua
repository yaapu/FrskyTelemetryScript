--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry script for the Taranis class radios
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

-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

local function doGarbageCollect()
    collectgarbage()
    collectgarbage()
end


local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- gps status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  local strNumSats = ""
  local flags = BLINK
  local mult = 1
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(0,6 + 2, strStatus, SMLSIZE)
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(0 + 35, 6+1, strNumSats, MIDSIZE+RIGHT)
    lcd.drawText(0 + 37, 6 + 2 , "H", SMLSIZE)
    lcd.drawNumber(0 + 60, 6+1, telemetry.gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(0 + 35,6+1,0+35,6 + 12,SOLID,FORCE)
  else
    lcd.drawText(0 + 10, 6+1, strStatus, MIDSIZE+INVERS+BLINK)
  end
  lcd.drawLine(0 ,6 + 13,0+60,6 + 13,SOLID,FORCE)
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
  if conf.rangeFinderMax > 0 then
    -- rng finder
    flags = 0
    local rng = telemetry.range
    -- rng is centimeters, RANGE_MAX is feet
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,16)
    lcd.drawText(4 + 4, 23, "Rng", SMLSIZE)
    lcd.drawText(61, 24 , unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos()-1, 24-1 , rng*0.01*unitScale*100, PREC2+RIGHT+flags)
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10 -- meters
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,12)
    end
    lcd.drawText(4 + 4, 23, "Asl", SMLSIZE)
    lcd.drawText(61, 24, unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos()-1, 24-1 , alt*unitScale, RIGHT+flags)
  end
  -- home distance
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(60, 34+4, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 34-1, dist*unitScale, RIGHT+MIDSIZE+flags)
  -- total distance
  drawLib.drawHArrow(2,49 + 2,8,true,true)
  lcd.drawText(61, 49, unitLongLabel, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 49, telemetry.totalDist*unitLongScale*100, RIGHT+SMLSIZE+PREC2)

  if status.showMinMaxValues == true then
    drawLib.drawVArrow(2 + 1, 34+1,6,true,false)
    drawLib.drawVArrow(4 - 1, 24-2,6,true,false)
  else
    drawLib.drawVArrow(4,23 - 1,7,true,true)
    drawLib.drawHomeIcon(2 + 1,37,7)
  end
end



return {
  drawPane=drawPane,
}
