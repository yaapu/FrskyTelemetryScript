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
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{
  1 = notified,
  2 = alarm start,
  3 = armed,
  4 = type(0=min,1=max,2=timer,3=batt),
  5 = grace duration
  6 = ready
  7 = last alarm
}
--]]
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"
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
  lcd.drawNumber(x+21, 7, (battery[1+battId] + 0.5)*(battery[1+battId] < 1000 and 1 or 0.1), DBLSIZE+flags+(battery[1+battId] < 1000 and PREC2 or PREC1))
  -- save pos to print source and V
  local lx = lcd.getLastRightPos()
  -- battery voltage
  lcd.drawNumber(x+0, 36, battery[4+battId]/10,MIDSIZE)
  lcd.drawText(lcd.getLastRightPos() - 1, 36, ".",MIDSIZE)
  lcd.drawNumber(lcd.getLastRightPos() - 1, 36+4, battery[4+battId]%10,0)
  lcd.drawText(lcd.getLastRightPos()-1, 36, "V", SMLSIZE)
  -- battery current
  lcd.drawText(x+61, 36, "A", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 36+4, getMaxValue(battery[7+battId],7+battId)%10,RIGHT)
  lcd.drawText(lcd.getLastLeftPos(), 36, ".",MIDSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 36, getMaxValue(battery[7+battId],7+battId)/10,MIDSIZE+RIGHT)
  -- battery percentage
  lcd.drawNumber(x+0, 11, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos(), 16, "%", SMLSIZE)
  -- display capacity bar %
  lcd.drawFilledRectangle(x+5, 24, perc/100*50, 3, SOLID+FORCE)
  local step = 50/10
  for s=1,10 - 1 do
    lcd.drawLine(x+5 + s*step - 1,24, x+5 + s*step - 1, 24 + 3 - 1,SOLID,0)
  end
  -- battery mah
  lcd.drawNumber(x+5, 29, battery[10+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 29, "/", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), 29, battery[13+battId]/100, SMLSIZE+PREC1)
  lcd.drawText(lcd.getLastRightPos(), 29, "Ah", SMLSIZE)
  -- efficiency
  local eff = telemetry.hSpeed*0.1 > 2 and 1000*battery[7+battId]*0.1/(telemetry.hSpeed*0.1*conf.horSpeedMultiplier) or 0
  lcd.drawText(x+0, 49, "Eff", SMLSIZE)
  lcd.drawText(x+61,49,string.format("%d mAh",eff),SMLSIZE+RIGHT)
  --minmax
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+0+23,36 + 8, 4,false,true)
    drawLib.drawVArrow(x+61-3,36 + 8,4,true,false)
    drawLib.drawVArrow(x+21+33, 7 + 2 ,6,false,true)
  else
    lcd.drawText(lx, 8, "V", dimFlags)
    lcd.drawText(lx, 17, status.battsource, SMLSIZE)
  end
end



return {
  drawPane=drawPane,
}
