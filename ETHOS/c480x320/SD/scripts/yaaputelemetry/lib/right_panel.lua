--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Ethos OS
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


local HUD_W = 240
local HUD_H = 150
local HUD_X = (480 - HUD_W)/2
local HUD_Y = 18

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local panel = {}
local status = nil
local libs = nil












function panel.draw(widget,x)
  local x_right = 480 - 10
  local x_left = x
  local perc = status.battery[16]
  --  battery min cell
  local flags = 0

  local color = status.colors.white
  lcd.pen(SOLID)
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      lcd.color(status.colors.red)
      libs.drawLib.drawBlinkRectangle(x+30,30,90,34,3)
      libs.drawLib.resetBacklightTimeout()
    elseif status.battLevel2 == true then
      lcd.color(status.colors.red)
      lcd.drawFilledRectangle(x+30,30,90,34,3)
      libs.drawLib.resetBacklightTimeout()
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      lcd.color(status.colors.yellow)
      libs.drawLib.drawBlinkRectangle(x+30,30,90,34,3)
      libs.drawLib.resetBacklightTimeout()
    elseif status.battLevel1 == true then
      color = status.colors.black
      lcd.color(status.colors.yellow)
      lcd.drawFilledRectangle(x+30,30,90,34,3)
      libs.drawLib.resetBacklightTimeout()
    end
  end

  -- cell voltage
  libs.drawLib.drawText(x+117, 17, string.upper(status.battsource).."-CELL", FONT_STD, status.colors.panelLabel, RIGHT)
  if status.battery[1] * 0.01 < 10 then
    libs.drawLib.drawNumber(x + 107, 30, status.battery[1]*0.01,2, FONT_XXL, color, RIGHT)
  else
    libs.drawLib.drawNumber(x + 107, 30, status.battery[1]*0.01, 1, FONT_XXL, color, RIGHT)
  end
  lcd.font(FONT_STD)
  lcd.drawText(x + 107, 46, "V")

  color = status.colors.white
  -- battery voltage
  libs.drawLib.drawText(x+44, 64, "BATT", FONT_STD, status.colors.panelLabel, RIGHT)
  libs.drawLib.drawNumber(x + 42, 88, status.battery[4]*0.1, 1, FONT_L, color, RIGHT)
  lcd.font(FONT_STD)
  lcd.drawText(x + 42, 90, "v")

-- battery current
  libs.drawLib.drawText(x+118, 64, "CURR", FONT_STD, status.colors.panelLabel,RIGHT)
  if status.battery[7]*0.1 < 10 then
    libs.drawLib.drawNumber(x + 108, 76, status.battery[7]*0.1, 1, FONT_XXL, color, RIGHT)
  else
    libs.drawLib.drawNumber(x + 108, 76, status.battery[7]*0.1, 0, FONT_XXL, color, RIGHT)
  end
  lcd.font(FONT_STD)
  lcd.drawText(x + 108, 93, "A")

  -- display capacity bar %
  color = status.colors.red
  if perc > 50 then
    color = status.colors.green
  elseif perc <= 50 and perc > 25 then
    color = status.colors.yellow-- yellow
  end

  libs.drawLib.drawMinMaxBar(x+5, 116, 110, 27, color, perc, 0, 99, false)
  libs.drawLib.drawText(x+78, 128, "%", FONT_XL, status.colors.black, LEFT)
  libs.drawLib.drawText(x+78, 113, string.format("%02d", math.floor(perc+0.5)), FONT_XXL, status.colors.black, RIGHT)

  -- battery mah
  lcd.color(status.colors.white)
  lcd.font(FONT_L)
  local strmah = string.format("%.02f/%.01fAh",status.battery[10]/1000,status.battery[13]/1000)
  lcd.drawText(x+117, 150, strmah, RIGHT)

  libs.drawLib.drawText(546, 37, "R1", FONT_XS, lcd.RGB(100,100,100), LEFT)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
