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


local HUD_W = 400
local HUD_H = 240
local HUD_X = (800 - HUD_W)/2
local HUD_Y = 36

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local panel = {}
local status = nil
local libs = nil

function panel.draw(widget)
  libs.mapLib.drawMap(widget, 0, 0, status.mapZoomLevel, 8, 4, status.telemetry.yaw)
  local alpha = 0.3
  lcd.color(lcd.RGB(0,0,0,alpha))
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0, 0, 800, 22)

  lcd.color(BLACK)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0, 480-22, 800, 22)
  libs.drawLib.drawStatusBar(widget,nil,2)

  lcd.font(FONT_STD)
  lcd.color(status.colors.white)
  lcd.drawText(800, 0, status.telemetry.strLat.."  "..status.telemetry.strLon, RIGHT)

  lcd.font(FONT_STD)
  lcd.drawText(0, 0, string.format("zoom: %d", status.mapZoomLevel))
  --lcd.drawText(0, 20, string.format("cog: %.0f", status.cog == nil and 0 or status.cog))

  --[[
  lcd.font(FONT_XS)
  lcd.color(status.colors.green)
  lcd.drawText(LCD_W, 302, "map", RIGHT)
  --]]
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

panel.showArmingStatus = false
panel.showFailsafe = false

return panel
