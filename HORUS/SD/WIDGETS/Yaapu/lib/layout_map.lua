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

local MAP_X = 90
local MAP_Y = 18
local TILES_X = 3
local TILES_Y = 2

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

local layout = {}

local conf
local telemetry
local status
local utils
local libs

function layout.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

local function drawMiniHud()
  libs.drawLib.drawArtificialHorizon(22, 22, 48, 36, nil, lcd.RGB(0x7B, 0x9D, 0xFF), lcd.RGB(0x63, 0x30, 0x00), 6, 6.5)
  lcd.drawBitmap(utils.getBitmap("hud_48x48a"), 22-1, 22-10)
end

function layout.draw(widget)
  libs.mapLib.drawMap(widget, MAP_X, MAP_Y, status.mapZoomLevel, TILES_X, TILES_Y)
  libs.drawLib.drawLeftRightTelemetry(myWidget)
  lcd.drawBitmap(utils.getBitmap("graph_bg_120x30"),266,184)
  libs.drawLib.drawGraph("map_alt", 266, 184, 120, 30, utils.colors.darkyellow, telemetry.homeAlt, false, true, "m")
  drawMiniHud()
  utils.drawTopBar()
  libs.drawLib.drawStatusBar(2)
  libs.drawLib.drawArmStatus()
  libs.drawLib.drawFailsafe()
  local nextX = libs.drawLib.drawTerrainStatus(93,38)
  libs.drawLib.drawFenceStatus(nextX,38)
end

function layout.background(widget)
  libs.drawLib.updateGraph("map_alt", telemetry.homeAlt)
end

return layout

