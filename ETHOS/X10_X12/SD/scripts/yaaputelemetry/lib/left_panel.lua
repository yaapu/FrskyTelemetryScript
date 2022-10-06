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
  --[[
  lcd.color(255,0,255)
  lcd.font(FONT_XXL)
  lcd.drawText(0, 20, "XXL")
  lcd.font(FONT_XL)
  lcd.drawText(0, 60, "XL")
  lcd.font(FONT_L)
  lcd.drawText(0, 90, "L")
  lcd.font(FONT_STD)
  lcd.drawText(0, 110, "STD")
  lcd.font(FONT_BOLD)
  lcd.drawText(80, 110, "BOLD")
  lcd.font(FONT_ITALIC)
  lcd.drawText(220, 110, "ITALIC",RIGHT)
  lcd.font(FONT_S)
  lcd.drawText(5, 130, "S")
  lcd.font(FONT_XS)
  lcd.drawText(5, 150, "XS")
  --]]
  -- 245 x 168
  lcd.color(status.colors.panelLabel)
  lcd.font(FONT_STD)
  if status.conf.rangeFinderMax > 0 then
    local rng = libs.utils.getMaxValue(status.telemetry.range, 16)
    if rng*0.01*status.conf.distUnitScale < 10 then
      libs.drawLib.drawPanelSensor(106, 17, rng*0.01*status.conf.distUnitScale, 1, "RNG", status.conf.distUnitLabel, FONT_XXL, FONT_S, FONT_STD, status.colors.panelText, status.colors.panelLabel,true)
    else
      libs.drawLib.drawPanelSensor(106, 17, rng*0.01*status.conf.distUnitScale, 0, "RNG", status.conf.distUnitLabel,FONT_XXL, FONT_S, FONT_STD, status.colors.panelText, status.colors.panelLabel,true)
    end
  else
    local blink = true
    local alt = status.telemetry.gpsAlt/10
    if status.telemetry.gpsStatus  > 2 then
      -- update max only with 3d or better lock
      alt = libs.utils.getMaxValue(alt,12)
      blink = false
    end
    libs.drawLib.drawPanelSensor(106, 17, status.telemetry.gpsStatus > 2 and alt*status.conf.distUnitScale or nil, 0, "GALT", status.conf.distUnitLabel, FONT_XXL, FONT_S, FONT_STD, status.colors.panelText, status.colors.panelLabel, true, blink)
  end

  -- home distance
  blink = false
  if status.telemetry.homeAngle == -1 then
    blink = true
  end
  local dist = libs.utils.getMaxValue(status.telemetry.homeDist,15)
  if dist*status.conf.distUnitScale > 999 then
    libs.drawLib.drawPanelSensor(106, 63, dist*status.conf.distUnitLongScale, 2,"HOME",status.conf.distUnitLongLabel, FONT_XXL, FONT_S, FONT_STD, status.colors.panelText, status.colors.panelLabel,true, blink)
  else
    libs.drawLib.drawPanelSensor(106, 63, dist*status.conf.distUnitScale, 0,"HOME",status.conf.distUnitLabel, FONT_XXL, FONT_S, FONT_STD, status.colors.panelText, status.colors.panelLabel,true, blink)
  end
  -- travel distance
  libs.drawLib.drawPanelSensor(106, 109, status.telemetry.totalDist*status.conf.distUnitLongScale, 2,"TRAVEL",status.conf.distUnitLongLabel, FONT_XXL, FONT_S, FONT_STD, status.colors.panelText, status.colors.panelLabel,true)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
