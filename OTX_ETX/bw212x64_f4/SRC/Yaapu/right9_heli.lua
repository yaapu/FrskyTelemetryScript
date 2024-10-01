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
  -- battery voltage
  lcd.drawText(x, 13, "batt", SMLSIZE)
  lcd.drawNumber(x+0+53, 8, battery[4+battId],MIDSIZE+PREC1+RIGHT)
  lcd.drawText(x+0+53, 13, "V", SMLSIZE)
  -- throttle %
  lcd.drawText(x, 30, "torque", SMLSIZE)
  lcd.drawNumber(x+0+53, 25, telemetry.throttle, MIDSIZE+RIGHT)
  lcd.drawText(x+0+53, 30, "%", SMLSIZE)
  --  %
  lcd.drawText(x, 47, "rpm", SMLSIZE)
  lcd.drawNumber(x+0+57, 42, telemetry.rpm1, MIDSIZE+RIGHT)
end



return {
  drawPane=drawPane,
}
