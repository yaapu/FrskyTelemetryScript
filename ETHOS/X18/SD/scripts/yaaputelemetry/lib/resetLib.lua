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


local HUD_W = 240
local HUD_H = 150
local HUD_X = (480 - HUD_W)/2
local HUD_Y = 18

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local resetLib = {}
local status = nil
local libs = nil

-----------------------------
-- clears the loaded table
-- and recovers memory
-----------------------------
function resetLib.clearTable(t)
  if type(t)=="table" then
    for i,v in pairs(t) do
      if type(v) == "table" then
        resetLib.clearTable(v)
      end
      t[i] = nil
    end
  end
  t = nil
end

function resetLib.resetLayout(widget)
  -- layout
  status.loadCycle = 0

  resetLib.clearTable(status.layout)
  resetLib.clearTable(widget.centerPanel)
  resetLib.clearTable(widget.leftPanel)
  resetLib.clearTable(widget.rightPanel)

  status.layout = {nil, nil, nil}

  widget.centerPanel = nil
  widget.rightPanel = nil
  widget.leftPanel = nil
  widget.ready = false

  collectgarbage()
  collectgarbage()
end

function resetLib.resetStatus(widget)
  -- FLVSS 1
  status.cell1min = 0
  status.cell1sum = 0
  -- FLVSS 2
  status.cell2min = 0
  status.cell2sum = 0
  -- FC 1
  status.cell1sumFC = 0
  status.cell1maxFC = 0
  -- FC 2
  status.cell2sumFC = 0
  status.cell2maxFC = 0
  -- battery
  status.cell1count = 0
  status.cell2count = 0
  status.battsource = "fc"
  status.batt1sources = {
    vs = false,
    fc = false
  }
  status.batt2sources = {
    vs = false,
    fc = false
  }
  -- flight time
  status.lastTimerStart = 0
  status.timerRunning = 0
  status.flightTime = 0
  -- events
  status.lastStatusArmed = 0
  status.lastGpsStatus = 0
  status.lastFlightMode = 0
  status.lastSimpleMode = 0
  -- battery levels
  status.batLevel = 99
  status.battLevel1 = false
  status.battLevel2 = false
  status.lastBattLevel = 14
  -- messages
  status.messages = {}
  status.msgBuffer = ""
  status.lastMsgValue = 0
  status.lastMsgTime = 0
  status.lastMessage = nil
  status.lastMessageSeverity = 0
  status.lastMessageCount = 1
  status.messageCount = 0
  status.messageOffset = 0
  status.messageAutoScroll = true
  -- telemetry status
  status.noTelemetryData = 1
  status.hideNoTelemetry = false
  status.showDualBattery = false
  status.showMinMaxValues = false
  -- maps
  status.screenTogglePage = 1
  status.mapZoomLevel = 19
  -- flightmode
  status.strFlightMode = nil
  status.modelString = nil
  -- terrain
  status.terrainEnabled = 0
  status.terrainLastData = getTime()
  -- airspeed
  status.airspeedEnabled = 0
  -- PLOT data
  status.plotSources = nil
  -- waypoint
  status.cog = nil
  status.lastLat = nil
  status.lastLon = nil
  status.wpEnabled = 0
  status.wpEnabledMode = 0
  -- dynamic layout element hiding
  status.hidePower = 0
  status.hideEfficiency = 0
  -- blinking suppport
  status.blinkon = false
  -- top bar
  status.linkQualitySource = nil
  -- traveled distance support
  status.avgSpeed = 0
  status.lastUpdateTotDist = 0

  -- telemetry params
  status.paramId = nil
  status.paramValue = nil

  -- message hash support
  status.shortHash = nil
  status.parseShortHash = false
  status.hashByteIndex = 0
  status.hash = 0
  status.hash_a = 0
  status.hash_b = 0

end

function resetLib.resetTelemetry(widget)
  -- STATUS
  status.telemetry.flightMode = 0
  status.telemetry.simpleMode = 0
  status.telemetry.landComplete = 0
  status.telemetry.statusArmed = 0
  status.telemetry.battFailsafe = 0
  status.telemetry.ekfFailsafe = 0
  status.telemetry.failsafe = 0
  status.telemetry.imuTemp = 0
  status.telemetry.fencePresent = 0
  status.telemetry.fenceBreached = 0
  -- GPS
  status.telemetry.numSats = 0
  status.telemetry.gpsStatus = 0
  status.telemetry.gpsHdopC = 100
  status.telemetry.gpsAlt = 0
  -- BATT 1
  status.telemetry.batt1volt = 0
  status.telemetry.batt1current = 0
  status.telemetry.batt1mah = 0
  -- BATT 2
  status.telemetry.batt2volt = 0
  status.telemetry.batt2current = 0
  status.telemetry.batt2mah = 0
  -- HOME
  status.telemetry.homeDist = 0
  status.telemetry.homeAlt = 0
  status.telemetry.homeAngle = -1
  -- VELANDYAW
  status.telemetry.vSpeed = 0
  status.telemetry.hSpeed = 0
  status.telemetry.yaw = 0
  -- ROLLPITCH
  status.telemetry.roll = 0
  status.telemetry.pitch = 0
  status.telemetry.range = 0
  -- PARAMS
  status.telemetry.frameType = -1
  status.telemetry.batt1Capacity = 0
  status.telemetry.batt2Capacity = 0
  -- GPS
  status.telemetry.lat = nil
  status.telemetry.lon = nil
  status.telemetry.homeLat = nil
  status.telemetry.homeLon = nil
  status.telemetry.strLat = "N/A"
  status.telemetry.strLon = "N/A"
  -- WP
  status.telemetry.wpNumber = 0
  status.telemetry.wpDistance = 0
  status.telemetry.wpXTError = 0
  status.telemetry.wpBearing = 0
  status.telemetry.wpCommands = 0
  status.telemetry.wpOffsetFromCog = 0
  -- VFR
  status.telemetry.airspeed = 0
  status.telemetry.throttle = 0
  status.telemetry.baroAlt = 0
  -- Total distance
  status.telemetry.totalDist = 0
  -- RPM
  status.telemetry.rpm1 = 0
  status.telemetry.rpm2 = 0
  -- TERRAIN
  status.telemetry.heightAboveTerrain = 0
  status.telemetry.terrainUnhealthy = 0
  -- WIND
  status.telemetry.trueWindSpeed = 0
  status.telemetry.trueWindAngle = 0
  status.telemetry.apparentWindSpeed = 0
  status.telemetry.apparentWindAngle = 0
  -- RSSI
  status.telemetry.rssi = 0
  status.telemetry.rssiCRSF = 0

  status.alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , false, 1, 0, false, 0 }, --MAX_ALT
    { false, 0 , false, 1, 0, false, 0 }, --15
    { false, 0 , true, 1, 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1, 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 4, 4, false, 0 }, --BATT L2
    { false, 0 , true, 1, 0, false, 0 }, --FS
    { false, 0 , true, 1, 0, false, 0 }, --FENCE
    { false, 0 , true, 1, 0, false, 0 }, --TERRAIN
  }

  status.transitions = {
  --{ last_value, last_changed, transition_done, delay }
    { 0, 0, false, 30 },
  }

  ---------------------------
  -- BATTERY TABLE
  ---------------------------
  status.battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  status.batLevels = {0,5,10,15,20,25,30,40,50,60,70,80,90}
  status.minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

  collectgarbage()
  collectgarbage()
end

function resetLib.reset(widget)
  status.modelString = nil
  resetLib.resetLayout(widget)
  resetLib.resetTelemetry(widget)
  resetLib.resetStatus(widget)
  libs.utils.resetTimer()
  libs.utils.playSound("yaapu")
  libs.utils.pushMessage(7, "Yaapu Telemetry Widget 1.0.0f dev".. " ("..'355026f'..")")
  collectgarbage()
  collectgarbage()
end

function resetLib.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return resetLib
end

return resetLib
