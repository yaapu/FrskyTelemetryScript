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
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140, 140, 140))
  lcd.drawText(x+1,y+-2,"B1",0+CUSTOM_COLOR+SMLSIZE)
  lcd.drawText(x+1,y+63,"B2",0+CUSTOM_COLOR+SMLSIZE)

  local perc1 = status.battery[16+1]
  local perc2 = status.battery[16+2]
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- battery 1 current
  local flagUseDecimals = status.battery[7+1]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+100,y+-4,x+100,y+6,status.battery[7+1]*(flagUseDecimals and 1 or 0.1),"A",MIDSIZE+RIGHT+CUSTOM_COLOR+(flagUseDecimals and PREC1 or 0),SMLSIZE+CUSTOM_COLOR)
  -- battery 2 current
  flagUseDecimals = status.battery[7+2]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+100,y+-4+65,x+100,y+6+65,status.battery[7+2]*(flagUseDecimals and 1 or 0.1),"A",MIDSIZE+RIGHT+CUSTOM_COLOR+(flagUseDecimals and PREC1 or 0),SMLSIZE+CUSTOM_COLOR)
  -- battery 1 capacity bar %
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawFilledRectangle(x+10, y+25,100,18,CUSTOM_COLOR)
  if perc1 > 50 then
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(0,255,0))
  elseif perc1 <= 50 and perc1 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR, utils.colors.red)
  end
  lcd.drawGauge(x+10, y+25,100,18,perc1,100,CUSTOM_COLOR)
  -- battery 2 capacity bar %
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawFilledRectangle(x+10, y+25+65,100,18,CUSTOM_COLOR)
  if perc2 > 50 then
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(0,255,0))
  elseif perc2 <= 50 and perc2 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR, RED)
  end
  lcd.drawGauge(x+10, y+25+65,100,18,perc2,100,CUSTOM_COLOR)
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
  local strperc = string.format("%02d%%",perc1)
  lcd.drawText(x+52, y+24, strperc, 0+CUSTOM_COLOR)
  -- battery 2 percentage
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
  strperc = string.format("%02d%%",perc2)
  lcd.drawText(x+52, y+24+65, strperc, 0+CUSTOM_COLOR)
  -- battery 1 mah
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.02f/%.01fAh",status.battery[10+1]/1000,status.battery[13+1]/1000)
  lcd.drawText(x+110, y+44, strmah, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- label
  -- battery 2 mah
  strmah = string.format("%.02f/%.01fAh",status.battery[10+2]/1000,status.battery[13+2]/1000)
  lcd.drawText(x+110, y+44+65, strmah, SMLSIZE+RIGHT+CUSTOM_COLOR)

  -- GPS Altitude uses either RPM1 panel or overrides Efficiency panel
  local gpsAltX = x+92
  if conf.enableRPM == 2  or conf.enableRPM == 3 then
    status.hideEfficiency = 1
    gpsAltX = x+395
  end
  -- use power panel if RPM2 is enabled
  local homeDistX = x+192
  if conf.enableRPM == 3 then
    status.hidePower = 1
    homeDistX = x+478
  end
  -- home distance
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140,140,140))
  lcd.drawText(homeDistX, y+130, "HOME("..unitLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*unitScale)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(homeDistX, y+145, strdist, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  -- GPS Altitude and rangefinder
  if conf.rangeFinderMax > 0 then
    flags = 0
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,utils.colors.lightgrey)
    lcd.drawText(gpsAltX, y+130, "RNG("..unitLabel..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.drawFilledRectangle(gpsAltX-65, y+145+4,65,21,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(gpsAltX, y+145, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+RIGHT+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,12)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(140,140,140))
    lcd.drawText(gpsAltX, y+130, "GALT("..unitLabel..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    local stralt = string.format("%d",alt*unitScale)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(gpsAltX, y+145, stralt, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
end

function panel.background(myWidget)
end

return panel
