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

-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
--[[
BATT_CELL 1
BATT_VOLT 4
BATT_CURR 7
BATT_MAH 10
BATT_CAP 13

BATT_IDALL 0
BATT_ID1 1
BATT_ID2 2
--]]
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,utils)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local perc = battery[16+battId]
  --  battery min cell
  local flags = 0
  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white

  -- display capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+10, 22,80,32,CUSTOM_COLOR)
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+10, 22,80,32,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,0x0000) -- black

  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+25, 18, strperc, DBLSIZE+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+7,74)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+7,74)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,0x0000) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+7,74)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+7,74)
      lcd.setColor(CUSTOM_COLOR,0x0000) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 70, battery[1+battId] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 70, (battery[1+battId] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+76
  lcd.drawText(lx, 86, "V", flags)
  lcd.drawText(lx, 72, status.battsource, flags)

  -- labels
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(x+90,54,battId == 0 and "B1+B2" or (battId == 1 and "B1" or "B2"),SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+90, 108, "IMUt", SMLSIZE+RIGHT+CUSTOM_COLOR)

  -- IMU Temperature
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawText(x+90, 120, string.format("%d@",telemetry.imuTemp), DBLSIZE+RIGHT+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+75+11, 70 + 8,false,true,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
