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

local panel = {}

local conf
local telemetry
local status
local utils
local libs

function panel.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

function panel.draw(widget, x, y, battId)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local perc = status.battery[16+battId]
  --  battery min cell
  local flags = 0
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink",x+20,y+12)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red"),x+20,y+12)
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
      utils.drawBlinkBitmap("cell_orange_blink",x+20,y+12)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange"),x+20,y+12)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if status.battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+70+2, y+9, status.battery[1+battId] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+70+2, y+9, (status.battery[1+battId] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+71
  lcd.drawText(lx, y+24, "V", flags+SMLSIZE)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  -- battery voltage
  libs.drawLib.drawNumberWithDim(x+28,y+60,x+28, y+65, status.battery[4+battId],"V",RIGHT+PREC1+CUSTOM_COLOR,SMLSIZE+CUSTOM_COLOR)
  -- battery current
  local lowAmp = status.battery[7+battId]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+71,y+49,x+71,y+65,status.battery[7+battId]*(lowAmp and 1 or 0.1),"A",DBLSIZE+RIGHT+CUSTOM_COLOR+(lowAmp and PREC1 or 0),SMLSIZE+CUSTOM_COLOR)
  -- display capacity bar %
  local color = lcd.RGB(255,0, 0)
  if perc > 50 then
    color = lcd.RGB(0, 255, 0) -- red
  elseif perc <= 50 and perc > 25 then
    color = lcd.RGB(255, 204, 0) -- yellow
  end
  libs.drawLib.drawMinMaxBar(x+3, y+79,73,19,color,perc,0,100,MIDSIZE)
  -- battery mah
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.02f/%.01fAh",status.battery[10+battId]/1000,status.battery[13+battId]/1000)
  --lcd.drawText(x+73, 99+2, "Ah", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+73, y+99, strmah, 0+RIGHT+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140, 140, 140))
  local battLabel = "B1B2"
  if battId == 0 then
    if conf.battConf ==  3 then
      -- alarms are based on battery 1
      battLabel = "B1"
    elseif conf.battConf ==  4 then
      -- alarms are based on battery 2
      battLabel = "B2"
    end
  else
    battLabel = (battId == 1 and "B1" or "B2")
  end

  lcd.drawText(x+1, y+-2, battLabel, SMLSIZE+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    libs.drawLib.drawVArrow(x+70+11, y+9 + 8,false,true)
    libs.drawLib.drawVArrow(x+28+11, y+60 + 3, false,true)
    libs.drawLib.drawVArrow(x+71+11, y+49 + 10,true,false)
  end
  --]]
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(140, 140, 140))
  lcd.drawText(x+73, y+-2, string.format("%s CELL",string.upper(status.battsource)), SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+73, y+41, "CURR", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+30, y+41, "BATT", SMLSIZE+RIGHT+CUSTOM_COLOR)
end

function panel.background(myWidget)
end

return panel
