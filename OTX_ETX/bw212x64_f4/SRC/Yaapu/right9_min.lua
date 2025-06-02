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
  local perc = battery[16+battId]
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
  -- cell voltage
  -- +0.5 because PREC2 does a math.floor()  and not a math.round()
  lcd.drawNumber(x+17, 7, (battery[1+battId] + 0.5)*(battery[1+battId] < 1000 and 1 or 0.1), DBLSIZE+flags+(battery[1+battId] < 1000 and PREC2 or PREC1))
  -- save pos to print source and V
  local lx = lcd.getLastRightPos()
  -- battery current
  lcd.drawText(x+59, 24, "A", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 23+4, getMaxValue(battery[7+battId],7+battId)%10,RIGHT)
  lcd.drawText(lcd.getLastLeftPos(), 23, ".",MIDSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 23, getMaxValue(battery[7+battId],7+battId)/10,MIDSIZE+RIGHT)
  -- battery percentage
  lcd.drawText(x+52, 38, "%", RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 36, perc, MIDSIZE+RIGHT)
  -- battery mah
  lcd.drawNumber(x+10, 49, battery[10+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 49, "/", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), 49, battery[13+battId]/100, SMLSIZE+PREC1)
  lcd.drawText(lcd.getLastRightPos(), 49, "Ah", SMLSIZE)
  --minmax
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+59-3,23 + 8,4,true,false)
    drawLib.drawVArrow(x+17+33, 7 + 2 ,6,false,true)
  else
    lcd.drawText(lx, 8, "V", dimFlags)
    lcd.drawText(lx, 17, status.battsource, SMLSIZE)
  end
end



return {
  drawPane=drawPane,
}
