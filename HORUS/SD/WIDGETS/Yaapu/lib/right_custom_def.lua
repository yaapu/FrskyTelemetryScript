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


local customSensorXY = {
  { 478, 22, 478, 35, lcd.RGB(140,140,140)},
  { 478, 64, 478, 80, lcd.RGB(140,140,140)},
  { 478, 110, 478, 122, lcd.RGB(140,140,140)},
  { 392, 154, 392, 166},
  { 478, 154, 478, 166},
}

local customSensors = nil

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

function panel.draw(widget, x, battId)
  status.hidePower = 1
  status.hideEfficiency = 1

  if customSensors ~= nil then
    libs.drawLib.drawCustomSensors(0, customSensors, customSensorXY, lcd.RGB(140, 140, 140))
  else
    customSensors = utils.loadCustomSensors("right")
  end
end

function panel.background(myWidget)
end

return panel
