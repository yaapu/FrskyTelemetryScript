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
  local perc = 0
  if (battery[13+battId] > 0) then
    perc = math.min(math.max((1 - (battery[10+battId]/battery[13+battId]))*100,0),99)
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if status.showMinMaxValues == false then
    if status.battAlertLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif status.battAlertLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  -- +0.5 because PREC2 does a math.floor()  and not a math.round()
  lcd.drawNumber(x+1, 7, (battery[1+battId] + 0.5)*(battery[1+battId] < 1000 and 1 or 0.1), MIDSIZE+flags+(battery[1+battId] < 1000 and PREC2 or PREC1))
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+1+26, 7+2,6,false,true)
  else
    local lx = lcd.getLastRightPos()
    lcd.drawText(lx-1, 7, "V", dimFlags+SMLSIZE)
    --local xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
    local s = status.battsource == "a2" and "a" or (status.battsource == "vs" and "s" or "f")
    lcd.drawText(lx, 13, s, SMLSIZE)
  end
  -- battery voltage
  lcd.drawText(x+30, 19, "V", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 19, battery[4+battId],SMLSIZE+PREC1+RIGHT)
  -- battery current
  lcd.drawText(x+30, 26, "A", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 26, getMaxValue(battery[7+battId],7+battId),PREC1+SMLSIZE+RIGHT)
  -- battery percentage
  lcd.drawNumber(x+1, 32, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos()+1, 36, "%", SMLSIZE)
  -- battery mah
  lcd.drawNumber(x+1, 44, battery[10+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 44, "Ah", SMLSIZE)
  -- battery cap
  lcd.drawNumber(x+1, 44+7, battery[13+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 44+7, "Ah", SMLSIZE)
end


return {
  drawPane=drawPane,
}
