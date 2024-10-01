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
    lcd.drawText(x+0,6 + 2, strStatus, SMLSIZE)
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(x+0 + 35, 6+1, strNumSats, MIDSIZE+RIGHT)
    lcd.drawText(x+0 + 37, 6 + 2 , "H", SMLSIZE)
    lcd.drawNumber(x+0 + 60, 6+1, telemetry.gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(x+0 + 35,6+1,x+0+35,6 + 12,SOLID,FORCE)
  else
    lcd.drawText(x+0 + 10, 6+1, strStatus, MIDSIZE+INVERS+BLINK)
  end
  lcd.drawLine(x+0 ,6 + 13,x+0+60,6 + 13,SOLID,FORCE)
  if status.showMinMaxValues == true then
    flags = 0
  end
  if conf.rangeFinderMax > 0 then
    -- rng finder
    flags = 0
    local rng = telemetry.range
    -- rng is centimeters, RANGE_MAX is feet
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,16)
    lcd.drawText(x+2 + 4, 30, "Rng", SMLSIZE)
    lcd.drawText(x+60, 31 , unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), 31-1 , rng*0.01*unitScale*100, PREC2+RIGHT+SMLSIZE+flags)
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10 -- meters
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,12)
    end
    lcd.drawText(x+2 + 4, 30, "Asl", SMLSIZE)
    lcd.drawText(x+60, 31, unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), 31-1 ,alt*unitScale, RIGHT+SMLSIZE+flags)
  end
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- home distance
  lcd.drawText(x+60, 37+5, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 37, dist*unitScale, RIGHT+MIDSIZE+flags)
  -- waypoints
  lcd.drawNumber(x+0, 21, telemetry.wpNumber, SMLSIZE)
  drawLib.drawRArrow(lcd.getLastRightPos()+4,25,5,telemetry.wpBearing*45,FORCE)
  lcd.drawText(x+60, 21+1, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 21, telemetry.wpDistance*unitScale, RIGHT)
  -- total distance
  lcd.drawText(x+60, 49, unitLongLabel, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), 49, telemetry.totalDist*unitLongScale*10, RIGHT+SMLSIZE+PREC1)
  -- throttle
  lcd.drawNumber(x+0, 49, telemetry.throttle,SMLSIZE)
  lcd.drawText(lcd.getLastRightPos(), 49, "%", SMLSIZE)
  -- minmax
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+0 + 2, 41-2,6,true,false)
    drawLib.drawVArrow(x+2,30 - 1,6,true,false)
  else
    drawLib.drawVArrow(x+2,30 - 1,7,true,true)
    drawLib.drawHomeIcon(x+0 + 1,41,7)
  end
end




return {
  drawPane=drawPane,
}
