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
  status.hidePower = 1
  status.hideEfficiency = 1
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local perc = status.battery[16+battId]
  --  battery min cell
  local flags = 0
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white

  -- display capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+10, y+57,100,28,CUSTOM_COLOR)
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+10, y+57,100,28,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black

  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+40, y+53, strperc, DBLSIZE+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+30,y+14)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+30,y+14)
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+30,y+14)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+30,y+14)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if status.battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+101+2, y+10, status.battery[1+battId] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+101+2, y+10, (status.battery[1+battId] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+103
  lcd.drawText(lx, y+25, "V", flags)
  -- labels
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140, 140, 140))
  lcd.drawText(x+1,y+-2,battId == 0 and "B1+B2" or (battId == 1 and "B1" or "B2"),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(x+110, y+89, "IMU TEMP", SMLSIZE+RIGHT+CUSTOM_COLOR)

  -- IMU Temperature
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(x+110, y+98, string.format("%d%s",telemetry.imuTemp, conf.degSymbol), DBLSIZE+RIGHT+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+101+11, y+10 + 8,false,true)
  end
  
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(140, 140, 140))
  lcd.drawText(x+110, y+-2, string.format("%s CELL",string.upper(status.battsource)), SMLSIZE+RIGHT+CUSTOM_COLOR)
 
end

function panel.background(myWidget)
end

return panel
