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

--[[
    On hybrid vehicle we have voltage and current from battery 1, mah from battery 2
--]]
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,utils)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+7,20)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+7,20)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+7,20)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+7,20)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  -- PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 16, battery[1+1] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 16, (battery[1+1] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+76
  lcd.drawText(lx, 32, "V", flags)
  lcd.drawText(lx, 18, status.battsource, flags)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  -- battery current
  local lowAmp = battery[7+1]*0.1 < 10
  drawLib.drawNumberWithDim(x+75,68+86,x+76,83+86,battery[7+1]*(lowAmp and 1 or 0.1),"A",DBLSIZE+RIGHT+CUSTOM_COLOR+(lowAmp and PREC1 or 0),0+CUSTOM_COLOR)
  -- battery mah is from battery 2
  -- we display remaining liters vs used liters as usual
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.01fL/%.01fL",(battery[13+2]-battery[10+2])/1000,battery[13+2]/1000)
  lcd.drawText(x+90, 133, strmah, 0+RIGHT+CUSTOM_COLOR)
  -- fuel gauge from battery 2
  -- battery % only from battery 2
  local perc = battery[16+2]

  lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  drawLib.drawGauge(393,54,"fuelgauge_75x75", 430, 94, 25, 8, perc, 125, CUSTOM_COLOR, utils)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
