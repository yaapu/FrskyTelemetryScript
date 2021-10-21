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
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local perc = 99
  perc = battery[16+1]

  local perc2 = 99
  perc2 = battery[16+2]

  -- battery 1 cell voltage (no alerts on battery 1)
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(200,200,200)) -- white
  lcd.drawFilledRectangle(x+7,16+5,86,52,CUSTOM_COLOR)
  --lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- white
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 16, battery[1+1] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 16, (battery[1+1] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+76
  lcd.drawText(lx, 36, "V", flags)
  lcd.drawText(lx, 18, status.battsource, flags)

  --  BATT2 Cell voltage
  flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+7,76)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+7,76)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+7,76)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+7,76)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+2] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 72, battery[1+2] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 72, (battery[1+2] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  lx = x+78
  lcd.drawText(lx, 88, "V", flags)
  lcd.drawText(lx, 72, status.battsource, flags)

  -- BATTERY BAR % --
  --[[
  -- batt1 capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,CUSTOM_COLOR)
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,perc,100,CUSTOM_COLOR)
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  --]]
  -- batt2 capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+10, 130,80,21,CUSTOM_COLOR)
  if perc2 > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc2 <= 50 and perc2 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+10, 130,80,21,perc2,100,CUSTOM_COLOR)
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
  local strperc2 = string.format("%02d%%",perc2)
  lcd.drawText(x+35, 126, strperc2, MIDSIZE+CUSTOM_COLOR)

  -- POWER --
  -- power 1
  lcd.setColor(CUSTOM_COLOR,utils.colors.black)
  local power1 = battery[4+1]*battery[7+1]*0.01
  lcd.drawNumber(x+75,46,power1,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+77,53,"W",CUSTOM_COLOR)
  -- power 2
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local power2 = battery[4+2]*battery[7+2]*0.01
  lcd.drawNumber(x+75,103,power2,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+77,110,"W",CUSTOM_COLOR)

  --[[
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+11, BATTCELL_Y + 8,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+11,BATTVOLT_Y + 3, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+11,BATTCURR_Y + 10,true,false,utils)
  end
  --]]
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
