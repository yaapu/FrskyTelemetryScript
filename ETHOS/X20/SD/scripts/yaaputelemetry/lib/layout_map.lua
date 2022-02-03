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

function panel.draw(widget)
  local w2, h2 = lcd.getWindowSize()
  local bitmap = lcd.loadBitmap("/bitmaps/system/default_glider.png")
  lcd.drawBitmap(10, 25, bitmap, w2 - 20, h2 - 35)

  libs.mapLib.drawMap(widget, 0, 0, status.mapZoomLevel, 8,3, status.telemetry.yaw)
  --libs.drawLib.drawStatusBar(widget,1)
  local alpha = 0.3
  lcd.color(lcd.RGB(0,0,0,alpha))
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0, 0, 784, 22)
  --lcd.drawFilledRectangle(0, 22, 100, 316-22)

  lcd.color(BLACK)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0, 316-22, 784, 22)
  libs.drawLib.drawMessages(widget, 316-23, 1)

  lcd.font(FONT_STD)
  lcd.color(status.colors.white)
  lcd.drawText(784, 0, status.telemetry.strLat.."  "..status.telemetry.strLon, RIGHT)

  lcd.font(FONT_STD)
  lcd.drawText(0, 0, string.format("zoom: %d", status.mapZoomLevel))
  lcd.drawText(0, 20, string.format("cog: %.0f", status.cog == nil and 0 or status.cog))

  lcd.font(FONT_XS)
  lcd.color(status.colors.green)
  lcd.drawText(784, 302, "map", RIGHT)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
