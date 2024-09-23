--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry script for the Taranis class radios
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

-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

local function doGarbageCollect()
    collectgarbage()
    collectgarbage()
end


local menuLibFile = "menu7"

local menuLib = nil
local libBasePath = "/SCRIPTS/TELEMETRY/yaapu/"

------------------------
-- CONFIGURATION
------------------------
local conf = {
  language = "en",
  battAlertLevel1 = 0,
  battAlertLevel2 = 0,
  battCapOverride1 = 0,
  battCapOverride2 = 0,
  disableAllSounds = false,
  disableMsgBeep = 1,
  timerAlert = 0,
  minAltitudeAlert = 0,
  maxAltitudeAlert = 0,
  maxDistanceAlert = 0,
  repeatAlertsPeriod = 10,
  battConf = 1, -- 1=parallel,2=other
  cell1Count = 0,
  cell2Count = 0,
  rangeFinderMax = 0,
  horSpeedMultiplier = 1,
  vertSpeedMultiplier = 1,
  horSpeedLabel = "m",
  vertSpeedLabel = "m/s",
  centerPanel = nil,
  rightPanel = nil,
  leftPanel = nil,
  altView = nil,
  defaultBattSource = "na",
  enablePX4Modes = false,
  enableHaptic = false,
  enableCRSF = false
}

local function doLibrary(filename)
  local success,f = pcall(loadScript, libBasePath..filename..".lua")
  if success then
    local ret = f()
    doGarbageCollect()
    return ret
  else
    doGarbageCollect()
    return nil
  end
end

local function background()
end

local function run(event)
  lcd.clear()
  menuLib.drawConfigMenu(event)

  if event == EVT_VIRTUAL_EXIT then
    menuLib.saveConfig(conf)
    doGarbageCollect()
    return 1
  end

  return 0
end

local function init()
  menuLib = doLibrary(menuLibFile)
  if menuLib ~= nil then
    menuLib.loadConfig(conf)
    doGarbageCollect()
  end
end

return {run=run, init=init}



