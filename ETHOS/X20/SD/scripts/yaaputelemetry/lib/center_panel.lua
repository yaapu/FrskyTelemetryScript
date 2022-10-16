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
  libs.hudLib.drawHud(widget, HUD_X, HUD_Y, HUD_W, HUD_H)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
