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

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local panel = {}
local status = nil
local libs = nil

function panel.draw(widget,x)
  local x_right = 784 - 10
  local x_left = x
  local perc = status.battery[16]
  --  battery min cell
  local flags = 0

  local color = status.colors.white
  lcd.pen(SOLID)
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      lcd.color(status.colors.red)
      libs.drawLib.drawBlinkRectangle(x+120,40,115,46,3)
      libs.drawLib.resetBacklightTimeout()
    elseif status.battLevel2 == true then
      lcd.color(status.colors.red)
      lcd.drawFilledRectangle(x+120,40,115,46,3)
      libs.drawLib.resetBacklightTimeout()
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      lcd.color(status.colors.yellow)
      libs.drawLib.drawBlinkRectangle(x+120,40,115,46,3)
      libs.drawLib.resetBacklightTimeout()
    elseif status.battLevel1 == true then
      color = status.colors.black
      lcd.color(status.colors.yellow)
      lcd.drawFilledRectangle(x+120,40,115,46,3)
      libs.drawLib.resetBacklightTimeout()
    end
  end

  -- cell voltage
  if status.battery[1] * 0.01 < 10 then
    libs.drawLib.drawNumber(x + 209, 40, status.battery[1]*0.01,2, FONT_XXL, color, RIGHT)
  else
    libs.drawLib.drawNumber(x + 209, 40, status.battery[1]*0.01, 1, FONT_XXL, color, RIGHT)
  end
  libs.drawLib.drawText(x+209, 40, status.battsource, FONT_STD, color)
  libs.drawLib.drawText(x+209, 61, "V", FONT_STD, color)

  color = status.colors.white
  -- battery voltage
  libs.drawLib.drawNumber(x + 209, 101, status.battery[4]*0.1, 1, FONT_XL, color, RIGHT)
  libs.drawLib.drawText(x+209, 110, "V", FONT_STD, color)

  libs.drawLib.drawText(x+85, 56, "%", FONT_L, color, LEFT)
  libs.drawLib.drawText(x+85, 40, string.format("%02d", math.floor(perc+0.5)), FONT_XXL, color, RIGHT)

  -- battery current
  if status.battery[7]*0.1 < 10 then
    libs.drawLib.drawNumber(x + 85, 91, status.battery[7]*0.1, 1, FONT_XXL,color, RIGHT)
  else
    libs.drawLib.drawNumber(x + 85, 91, status.battery[7]*0.1, 0, FONT_XXL, color, RIGHT)
  end
  libs.drawLib.drawText(x+85, 106, "A", FONT_L, color)

  -- display capacity bar %
  color = status.colors.red
  if perc > 50 then
    color = status.colors.green
  elseif perc <= 50 and perc > 25 then
    color = status,colors.yellow-- yellow
  end
  libs.drawLib.drawMinMaxBar(x+15, 139, 220, 40, color, perc, 0, 99, false)

  -- battery mah
  lcd.color(status.colors.black)
  lcd.font(FONT_XL)
  local strmah = string.format("%.02f/%.01fAh",status.battery[10]/1000,status.battery[13]/1000)
  lcd.drawText(x+128, 143, strmah, CENTERED)

  --[[
  lcd.color(CUSTOM_COLOR,lcd.RGB(230, 230, 230))
  local battLabel = "B1B2"
  if battId == 0 then
    if conf.battConf ==  BATTCONF_OTHER then
      -- alarms are based on battery 1
      battLabel = "B1"
    elseif conf.battConf ==  BATTCONF_OTHER2 then
      -- alarms are based on battery 2
      battLabel = "B2"
    end
  else
    battLabel = (battId == 1 and "B1" or "B2")
  end
  lcd.drawText(x+BATTLABEL_X, BATTLABEL_Y, battLabel, SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(x+BATTMAH_XUNIT, BATTLABEL_Y, "Ah", SMLSIZE+RIGHT+CUSTOM_COLOR)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+11, BATTCELL_Y + 8,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+11,BATTVOLT_Y + 3, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+11,BATTCURR_Y + 10,true,false,utils)
  end
  --]]
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
