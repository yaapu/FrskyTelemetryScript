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

------------------------------------------------------------------------------------
-- On hybrid vehicle we have voltage and current from battery 1, mah from battery 2
------------------------------------------------------------------------------------
function panel.draw(widget, x, battId)
  status.hidePower = 1
  status.hideEfficiency = 1

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+17,20)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+17,20)
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+17,20)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+17,20)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  -- PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if status.battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+85+2, 16, status.battery[1+1] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+85+2, 16, (status.battery[1+1] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+86
  lcd.drawText(lx, 32, "V", flags)
  lcd.drawText(lx, 18, status.battsource, flags)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  -- battery current
  local lowAmp = status.battery[7+1]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+85,68+86,x+86,83+86,status.battery[7+1]*(lowAmp and 1 or 0.1),"A",DBLSIZE+RIGHT+CUSTOM_COLOR+(lowAmp and PREC1 or 0),0+CUSTOM_COLOR)
  -- battery mah is from battery 2
  -- we display remaining liters vs used liters as usual
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.01f/%.01fL",(status.battery[13+2]-status.battery[10+2])/1000,status.battery[13+2]/1000)
  lcd.drawText(x+102, 133, strmah, 0+RIGHT+CUSTOM_COLOR)
  -- fuel gauge from battery 2
  lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  libs.drawLib.drawGauge(383,54,"fuelgauge_75x75", 420, 94, 25, 8, status.battery[16+2], 125, CUSTOM_COLOR)
end

function panel.background(myWidget)
end

return panel
