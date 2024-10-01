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



---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- GPS status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  flags = BLINK+PREC1
  local mult = 1
  lcd.drawLine(x,6 + 20,1+30,6 + 20,SOLID,FORCE)
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(x+1, 6+13, strStatus, SMLSIZE)
    local strNumSats
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(x+1 + 29, 6 + 13, strNumSats, SMLSIZE+RIGHT)
    lcd.drawText(x+1, 6 + 2 , "Hd", SMLSIZE)
    lcd.drawNumber(x+1 + 29, 6+1, telemetry.gpsHdopC*mult ,MIDSIZE+flags+RIGHT)

  else
    lcd.drawText(x+1 + 8, 6+3, "No", SMLSIZE+INVERS+BLINK)
    lcd.drawText(x+1 + 5, 6+12, strStatus, SMLSIZE+INVERS+BLINK)
  end
  -- alt asl/rng
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
    flags = 0
  if conf.rangeFinderMax > 0 then
    -- rng finder
    local rng = telemetry.range
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
      -- update max only with 3d or better lock
    rng = getMaxValue(rng,16)
    lcd.drawText(x+31, 30+1 , unitLabel, SMLSIZE+RIGHT)

    if rng*unitScale*0.01 > 10 then
      lcd.drawNumber(lcd.getLastLeftPos(), 30, rng*unitScale*0.1, flags+RIGHT+SMLSIZE+PREC1)
    else
      lcd.drawNumber(lcd.getLastLeftPos(), 30, rng*unitScale, flags+RIGHT+SMLSIZE+PREC2)
    end

    if status.showMinMaxValues == true then
      drawLib.drawVArrow(x+1+1, 30,5,true,false)
    else
      lcd.drawText(x+1, 30, "R", SMLSIZE)
    end
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,12)
    end
    lcd.drawText(x+31, 30,unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), 30, alt*unitScale, flags+RIGHT+SMLSIZE)

    if status.showMinMaxValues == true then
      drawLib.drawVArrow(x+1+1, 30 + 1,5,true,false)
    else
      drawLib.drawVArrow(x+1+1,30,5,true,true)
    end
  end
  -- home dist
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(x+31, 40, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 40, dist*unitScale,SMLSIZE+RIGHT+flags)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+1+1, 42-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+1, 42)
  end
  -- total distance
  lcd.drawText(32, 50, unitLongLabel, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), 50, telemetry.totalDist*unitLongScale*10, RIGHT+SMLSIZE+PREC1)
end


return {
  drawPane=drawPane,
}
