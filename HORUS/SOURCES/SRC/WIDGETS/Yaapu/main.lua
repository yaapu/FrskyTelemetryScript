--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Horus X10 and X12 radios
--
-- Copyright (C) 2018-2019. Alessandro Apostoli
-- https://github.com/yaapu
-- OlliW MavSDK additions by Risto Kõiva
-- https://github.com/rotorman
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

---------------------
-- MAIN CONFIG
-- 480x272 LCD_W x LCD_H
---------------------

---------------------
-- VERSION
---------------------
-- load and compile of lua files
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable battery percentage based on voltage
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE

---------------------
-- DEV FEATURE CONFIG
---------------------
-- enable memory debuging 
--#define MEMDEBUG
-- enable dev code
--#define DEV
-- uncomment haversine calculation routine
--#define HAVERSINE
-- enable telemetry logging to file (experimental)
--#define LOGTELEMETRY
-- use radio channels imputs to generate fake telemetry data
--#define TESTMODE
-- enable debug of generated hash or short hash string
--#define HASHDEBUG
-- enable MESSAGES DEBUG
--#define DEBUG_MESSAGES
---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
-- #define BGTELERATE

---------------------
-- SENSOR IDS
---------------------
















-- Throttle and RC use RPM sensor IDs

---------------------
-- BATTERY DEFAULTS
---------------------
---------------------------------
-- BACKLIGHT SUPPORT
-- GV is zero based, GV 8 = GV 9 in OpenTX
---------------------------------
---------------------------------
-- CONF REFRESH GV
---------------------------------

--
--
--

--

----------------------
-- COMMON LAYOUT
----------------------
-- enable vertical bars HUD drawing (same as taranis)
--#define HUD_ALGO1
-- enable optimized hor bars HUD drawing
--#define HUD_ALGO2
-- enable hor bars HUD drawing, 2 px resolution
-- enable hor bars HUD drawing, 1 px resolution
--#define HUD_ALGO4






--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

--------------------------
-- UNIT OF MEASURE
--------------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
-- 


----------------------
--- COLORS
----------------------

--#define COLOR_LABEL 0x7BCF
--#define COLOR_BG 0x0169
--#define COLOR_BARSEX 0x10A3


--#define COLOR_SENSORS 0x0169

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------


--------------------------
-- CLIPPING ALGO DEFINES
--------------------------


local frameNames = {}
-- copter
frameNames[0]   = "GEN"
frameNames[2]   = "QUAD"
frameNames[3]   = "COAX"
frameNames[4]   = "HELI"
frameNames[13]  = "HEX"
frameNames[14]  = "OCTO"
frameNames[15]  = "TRI"
frameNames[29]  = "DODE"
-- plane
frameNames[1]   = "WING"
frameNames[16]  = "FLAP"
frameNames[19]  = "VTOL2"
frameNames[20]  = "VTOL4"
frameNames[20]  = "VTOL4"
frameNames[21]  = "VTOLT"
frameNames[22]  = "VTOL"
frameNames[23]  = "VTOL"
frameNames[24]  = "VTOL"
frameNames[25]  = "VTOL"
frameNames[28]  = "FOIL"
-- rover
frameNames[10]  = "ROV"
-- boat
frameNames[11]  = "BOAT"

local currentModel = nil
local frameTypes = {}

--[[
	MAV_TYPE_GENERIC=0,               /* Generic micro air vehicle. | */
	MAV_TYPE_FIXED_WING=1,            /* Fixed wing aircraft. | */
	MAV_TYPE_QUADROTOR=2,             /* Quadrotor | */
	MAV_TYPE_COAXIAL=3,               /* Coaxial helicopter | */
	MAV_TYPE_HELICOPTER=4,            /* Normal helicopter with tail rotor. | */
	MAV_TYPE_ANTENNA_TRACKER=5,       /* Ground installation | */
	MAV_TYPE_GCS=6,                   /* Operator control unit / ground control station | */
	MAV_TYPE_AIRSHIP=7,               /* Airship, controlled | */
	MAV_TYPE_FREE_BALLOON=8,          /* Free balloon, uncontrolled | */
	MAV_TYPE_ROCKET=9,                /* Rocket | */
	MAV_TYPE_GROUND_ROVER=10,         /* Ground rover | */
	MAV_TYPE_SURFACE_BOAT=11,         /* Surface vessel, boat, ship | */
	MAV_TYPE_SUBMARINE=12,            /* Submarine | */
  MAV_TYPE_HEXAROTOR=13,            /* Hexarotor | */
	MAV_TYPE_OCTOROTOR=14,            /* Octorotor | */
	MAV_TYPE_TRICOPTER=15,            /* Tricopter | */
	MAV_TYPE_FLAPPING_WING=16,        /* Flapping wing | */
	MAV_TYPE_KITE=17,                 /* Kite | */
	MAV_TYPE_ONBOARD_CONTROLLER=18,   /* Onboard companion controller | */
	MAV_TYPE_VTOL_DUOROTOR=19,        /* Two-rotor VTOL using control surfaces in vertical operation in addition. Tailsitter. | */
	MAV_TYPE_VTOL_QUADROTOR=20,       /* Quad-rotor VTOL using a V-shaped quad config in vertical operation. Tailsitter. | */
	MAV_TYPE_VTOL_TILTROTOR=21,       /* Tiltrotor VTOL | */
	MAV_TYPE_VTOL_RESERVED2=22,       /* VTOL reserved 2 | */
	MAV_TYPE_VTOL_RESERVED3=23,       /* VTOL reserved 3 | */
	MAV_TYPE_VTOL_RESERVED4=24,       /* VTOL reserved 4 | */
	MAV_TYPE_VTOL_RESERVED5=25,       /* VTOL reserved 5 | */
	MAV_TYPE_GIMBAL=26,               /* Onboard gimbal | */
	MAV_TYPE_ADSB=27,                 /* Onboard ADSB peripheral | */
	MAV_TYPE_PARAFOIL=28,             /* Steerable, nonrigid airfoil | */
	MAV_TYPE_DODECAROTOR=29,          /* Dodecarotor | */
]]

-- copter
frameTypes[0]   = "c"
frameTypes[2]   = "c"
frameTypes[3]   = "c"
frameTypes[4]   = "c"
frameTypes[13]  = "c"
frameTypes[14]  = "c"
frameTypes[15]  = "c"
frameTypes[29]  = "c"
-- plane
frameTypes[1]   = "p"
frameTypes[16]  = "p"
frameTypes[19]  = "p"
frameTypes[20]  = "p"
frameTypes[21]  = "p"
frameTypes[22]  = "p"
frameTypes[23]  = "p"
frameTypes[24]  = "p"
frameTypes[25]  = "p"
frameTypes[28]  = "p"
-- rover
frameTypes[10]  = "r"
-- boat
frameTypes[11]  = "b"


local soundFileBasePath = "/SOUNDS/yaapu0"
local gpsStatuses = {}

gpsStatuses[0]="NoGPS"
gpsStatuses[1]="NoLock"
gpsStatuses[2]="2D"
gpsStatuses[3]="3D"
gpsStatuses[4]="DGPS"
gpsStatuses[5]="RTK"
gpsStatuses[6]="RTK"

--[[
0	MAV_SEVERITY_EMERGENCY	System is unusable. This is a "panic" condition.
1	MAV_SEVERITY_ALERT	Action should be taken immediately. Indicates error in non-critical systems.
2	MAV_SEVERITY_CRITICAL	Action must be taken immediately. Indicates failure in a primary system.
3	MAV_SEVERITY_ERROR	Indicates an error in secondary/redundant systems.
4	MAV_SEVERITY_WARNING	Indicates about a possible future error if this is not resolved within a given timeframe. Example would be a low battery warning.
5	MAV_SEVERITY_NOTICE	An unusual event has occured, though not an error condition. This should be investigated for the root cause.
6	MAV_SEVERITY_INFO	Normal operational messages. Useful for logging. No action is required for these messages.
7	MAV_SEVERITY_DEBUG	Useful non-operational messages that can assist in debugging. These should not occur during normal operation.
--]]

local mavSeverity = {}
mavSeverity[0]="EMR"
mavSeverity[1]="ALR"
mavSeverity[2]="CRT"
mavSeverity[3]="ERR"
mavSeverity[4]="WRN"
mavSeverity[5]="NOT"
mavSeverity[6]="INF"
mavSeverity[7]="DBG"

------------------------------
-- TELEMETRY DATA
------------------------------
local telemetry = {}
-- STATUS 
telemetry.flightMode = 0
telemetry.simpleMode = 0
telemetry.landComplete = 0
telemetry.statusArmed = 0
telemetry.battFailsafe = 0
telemetry.ekfFailsafe = 0
telemetry.imuTemp = 0
-- GPS
telemetry.numSats = 0
telemetry.gpsStatus = 0
telemetry.gpsHdopC = 100
telemetry.gpsAlt = 0
-- BATT 1
telemetry.batt1volt = 0
telemetry.batt1current = 0
telemetry.batt1mah = 0
-- BATT 2
telemetry.batt2volt = 0
telemetry.batt2current = 0
telemetry.batt2mah = 0
-- HOME
telemetry.homeDist = 0
telemetry.homeAlt = 0
telemetry.homeAngle = -1
-- VELANDYAW
telemetry.vSpeed = 0
telemetry.hSpeed = 0
telemetry.yaw = 0
-- ROLLPITCH
telemetry.roll = 0
telemetry.pitch = 0
telemetry.range = 0 
-- PARAMS
telemetry.frameType = -1
telemetry.batt1Capacity = 0
telemetry.batt2Capacity = 0
-- GPS
telemetry.lat = nil
telemetry.lon = nil
telemetry.homeLat = nil
telemetry.homeLon = nil
telemetry.strLat = "N/A"
telemetry.strLon = "N/A"
-- WP
telemetry.wpNumber = 0
telemetry.wpDistance = 0
telemetry.wpXTError = 0
telemetry.wpBearing = 0
telemetry.wpCommands = 0
-- RC channels
telemetry.rcchannels = {}
-- VFR
telemetry.airspeed = 0
telemetry.throttle = 0
telemetry.baroAlt = 0
-- Total distance
telemetry.totalDist = 0
-- CRSF
telemetry.rssiCRSF = 0
-- MAVLink
telemetry.rssiMAVLink = 0
--------------------------------
-- STATUS DATA
--------------------------------
local status = {}
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
--------------------------------
status.cell1count = 0
status.cell2count = 0

status.battsource = "na"

status.batt1sources = {
  vs = false,
  fc = false
}
status.batt2sources = {
  vs = false,
  fc = false
}
-- SYNTH VSPEED SUPPORT
status.vspd = 0
status.synthVSpeedTime = 0
status.prevHomeAlt = 0
-- FLIGHT TIME
status.lastTimerStart = 0
status.timerRunning = 0
status.flightTime = 0
-- EVENTS
status.lastStatusArmed = 0
status.lastGpsStatus = 0
status.lastFlightMode = 0
status.lastSimpleMode = 0
-- battery levels
status.batLevel = 99
status.battLevel1 = false
status.battLevel2 = false
status.lastBattLevel = 14
-- MESSAGES
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
-- LINK STATUS
status.noTelemetryData = 1
status.hideNoTelemetry = false
status.showDualBattery = false
status.showMinMaxValues = false
-- MAP
status.screenTogglePage = 1
status.mapZoomLevel = 1
-- FLIGHTMODE
status.strFlightMode = nil
status.modelString = nil
-- HOME POS
status.homeGood = false
status.homelat = nil  -- somewhat duplicated unused telemetry.homeLat
status.homelon = nil  -- somewhat duplicates unused telemetry.homeLon
status.homealt = nil
status.homehdg = nil

---------------------------
-- BATTERY TABLE
---------------------------
local battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
---------------------------
-- LIBRARY LOADING
---------------------------
local basePath = "/SCRIPTS/YAAPU/"
local libBasePath = basePath.."LIB/"

-- loadable modules
local drawLibFile = "draw"
local menuLibFile = "menu"

local frame = {}
local drawLib = {}
local utils = {}

-------------------------------
-- MAIN SCREEN LAYOUT
-------------------------------
local layout = nil
local centerPanel = nil
local rightPanel = nil
local leftPanel = nil
-------------------------------
-- MP SCREEN LAYOUT
-------------------------------
local mapLayout = nil
-------------------------------
-- SENSORS
-------------------------------
local customSensors = nil

local backlightLastTime = 0

local resetPhase = 0
local resetPending = false
local loadConfigPending = false
local modelChangePending = false

local resetLayoutPhase = 0
local resetLayoutPending = false

---------------------------------
-- ALARMS
---------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]
local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , false, 1 , 0, false, 0 }, --MAX_ALT
    { false, 0 , false, 1 , 0, false, 0 }, --15
    { false, 0 , true, 1 , 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1 , 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 4, 4, false, 0 }, --BATT L2
    { false, 0 , false, 1 , 0, false, 0 } --MAX_HDOP
}

local transitions = {
  --{ last_value, last_changed, transition_done, delay }  
    { 0, 0, false, 30 },
}

-- SYNTH GPS DIST SUPPORT
local lastSpeed = 0
local lastUpdateTotDist = 0

local  paramId,paramValue

local batLevels = {0,5,10,15,20,25,30,40,50,60,70,80,90}
-- Blinking bitmap support
local bitmaps = {}
local blinktime = getTime()
local blinkon = false

local minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}


-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

local opentx = tonumber(maj..minor..rev)
-- widget selected page
local currentPage = 0
--------------------------------------------------------------------------------
-- CONFIGURATION MENU
--------------------------------------------------------------------------------
local conf = {
  language = "en",
  defaultBattSource = "na", -- auto
  battAlertLevel1 = 0,
  battAlertLevel2 = 0,
  battCapOverride1 = 0,
  battCapOverride2 = 0,
  disableAllSounds = false,
  disableMsgBeep = 1,
  enableHaptic = false,
  timerAlert = 0,
  repeatAlertsPeriod = 10,
  minAltitudeAlert = 0,
  maxAltitudeAlert = 0,
  maxDistanceAlert = 0,
  battConf = 1, -- 1=parallel,2=other
  cell1Count = 0,
  cell2Count = 0,
  enableBattPercByVoltage = false,
  rangeFinderMax=0,
  enableSynthVSpeed=false,
  horSpeedMultiplier=1,
  vertSpeedMultiplier=1,
  horSpeedLabel = "m/s",
  vertSpeedLabel = "m/s",
  maxHdopAlert = 2,
  enablePX4Modes = false,
  enableCRSF = false,
  enableMAVLink = true,
  centerPanel = 1,
  rightPanel = 1,
  leftPanel = 1,
  widgetLayout = 1,
  widgetLayoutFilename = "layout_1",
  centerPanelFilename = "hud_1",
  rightPanelFilename = "right_1",
  leftPanelFilename = "left_1",
  mapType = "sat_tiles", -- applies to gmapcacther only
  mapZoomMax = 17,
  mapZoomMin = -2,
  enableMapGrid = true,
  screenToggleChannelId = 0,
  screenWheelChannelId = 0,
  gpsFormat = 1, -- DMS
  mapProvider = 1, -- 1 GMapCatcher, 2 Google, 3 Yandex
}

-------------------------
-- message hash support
-------------------------
local shortHashes = {}
-- 16 bytes hashes
shortHashes[2730864352] = false -- Soaring: Too high
shortHashes[1698465616] = false -- Soaring: Too low
shortHashes[981284144] = false -- Soaring: Thermal ended
shortHashes[2913564252] = false -- Soaring: Drifted too far
shortHashes[1746499976] = false -- Soaring: Exit via RC switch
shortHashes[883458048] = false -- Soaring: Enabled.
shortHashes[2139150204] = false -- Soaring: thermal weak
shortHashes[1352994600] = false -- Soaring: reached upper altitude
shortHashes[4026147344] = false -- Soaring: reached lower altitude

shortHashes[4091124880] = true -- reached command:
shortHashes[3311875476] = true -- reached waypoint:
shortHashes[1997782032] = true -- Passed waypoint:
shortHashes[554623408] = false -- Takeoff complete
shortHashes[3025044912] = false -- Smart RTL deactivated
shortHashes[3956583920] = false -- GPS home acquired
shortHashes[1309405592] = false -- GPS home acquired

local shortHash = nil
local parseShortHash = false
local hashByteIndex = 0
local hash = 2166136261
-------------------------------
-- SCREEN DRAWING
-------------------------------
local drawMainLayout = nil
local drawMapLayout = nil


local function triggerReset()
  resetPending = true
  modelChangePending = true
end

local function calcCellCount()
  -- cellcount override from menu
  local c1 = 0
  local c2 = 0
  
  if conf.cell1Count ~= nil and conf.cell1Count > 0 then
    c1 = conf.cell1Count
  elseif status.batt1sources.vs == true and status.cell1count > 1 then
    c1 = status.cell1count
  else
    c1 = math.floor( ((status.cell1maxFC*0.1) / 4.35) + 1)
  end
  
  if conf.cell2Count ~= nil and conf.cell2Count > 0 then
    c2 = conf.cell2Count
  elseif status.batt2sources.vs == true and status.cell2count > 1 then
    c2 = status.cell2count
  else
    c2 = math.floor(((status.cell2maxFC*0.1)/4.35) + 1)
  end
  
  return c1,c2
end

--[[
  Example data based on a 18 minutes flight for quad, battery:5200mAh LiPO 10C, hover @15A
  Notes:
  - when motors are armed VOLTAGE_DROP offset is applied!
  - number of samples is fixed at 11 but percentage values can be anything and are not restricted to multiples of 10
  - voltage between samples is assumed to be linear
--]]
local battPercByVoltage = {}

utils.getBattPercByCell = function(voltage)
  if battPercByVoltage.dischargeCurve == nil then
    return 99
  end
  -- when disarmed apply voltage drop to use an "under load" curve
  if telemetry.statusArmed == 0 then
    voltage = voltage - battPercByVoltage.voltageDrop
  end
  
  if battPercByVoltage.useCellVoltage == false then
    voltage = voltage*calcCellCount()
  end
  if voltage == 0 then
    return 99
  end
  if voltage >= battPercByVoltage.dischargeCurve[#battPercByVoltage.dischargeCurve][1] then
    return 99
  end
  if voltage <= battPercByVoltage.dischargeCurve[1][1] then
    return 0
  end
  for i=2,#battPercByVoltage.dischargeCurve do                                  
    if voltage <= battPercByVoltage.dischargeCurve[i][1] then
      --
      local v0 = battPercByVoltage.dischargeCurve[i-1][1]
      local fv0 = battPercByVoltage.dischargeCurve[i-1][2]
      --
      local v1 = battPercByVoltage.dischargeCurve[i][1]
      local fv1 = battPercByVoltage.dischargeCurve[i][2]
      -- interpolation polinomial
      return fv0 + ((fv1 - fv0)/(v1-v0))*(voltage - v0)
    end
  end --for
end

local loadCycle = 0

utils.doLibrary = function(filename)
  local f = assert(loadScript(libBasePath..filename..".lua"))
  return f()
end
-----------------------------
-- clears the loaded table 
-- and recovers memory
-----------------------------
utils.clearTable = function(t)
  if type(t)=="table" then
    for i,v in pairs(t) do
      if type(v) == "table" then
        utils.clearTable(v)
      end
      t[i] = nil
    end
  end
  t = nil
  collectgarbage()
  collectgarbage()
end  

local function resetLayouts()
  if resetLayoutPending == true then
    if resetLayoutPhase == -1 then
      -- empty step
      resetLayoutPhase = 0
    elseif resetLayoutPhase == 0 then
      utils.clearTable(layout)
      layout = nil
      resetLayoutPhase = 1
    elseif resetLayoutPhase == 1 then
      utils.clearTable(centerPanel)
      centerPanel = nil
      resetLayoutPhase = 2
    elseif resetLayoutPhase == 2 then
      utils.clearTable(rightPanel)
      rightPanel = nil
      resetLayoutPhase = 3
    elseif resetLayoutPhase == 3 then
      utils.clearTable(leftPanel)
      leftPanel = nil
      resetLayoutPhase = 4
    elseif resetLayoutPhase == 4 then
      utils.clearTable(mapLayout)
      mapLayout = nil
      drawMainLayout = layoutLoad
      resetLayoutPhase = 0
      resetLayoutPending = false
    end
  end
end

utils.getBitmap = function(name)
  if bitmaps[name] == nil then
    bitmaps[name] = Bitmap.open("/SCRIPTS/YAAPU/IMAGES/"..name..".png")
  end
  return bitmaps[name],Bitmap.getSize(bitmaps[name])
end

utils.unloadBitmap = function(name)
  if bitmaps[name] ~= nil then
    bitmaps[name] = nil
    -- force call to luaDestroyBitmap()
    collectgarbage()
    collectgarbage()
  end
end

utils.lcdBacklightOn = function()
  model.setGlobalVariable(8,0,1)
  backlightLastTime = getTime()/100 -- seconds
end

utils.playSound = function(soundFile,skipHaptic)
  if conf.enableHaptic and skipHaptic == nil then
    playHaptic(15,0)
  end
  if conf.disableAllSounds then
    return
  end
  utils.lcdBacklightOn()
  playFile(soundFileBasePath .."/"..conf.language.."/".. soundFile..".wav")
end

----------------------------------------------
-- sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
utils.playSoundByFlightMode = function(flightMode)
  if conf.enableHaptic then
    playHaptic(15,0)
  end
  if conf.disableAllSounds then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      utils.lcdBacklightOn()
      -- rover sound files differ because they lack "flight" word
      playFile(soundFileBasePath.."/"..conf.language.."/".. string.lower(frame.flightModes[flightMode]) .. ((frameTypes[telemetry.frameType]=="r" or frameTypes[telemetry.frameType]=="b") and "_r.wav" or ".wav"))
    end
  end
end


local function formatMessage(severity,msg)
  local clippedMsg = msg
  
  if #msg > 50 then
    clippedMsg = string.sub(msg,1,50)
    msg = nil
  end
  
  if status.lastMessageCount > 1 then
    return string.format("%02d:%02d %s (x%d) %s", status.flightTime/60, status.flightTime%60, mavSeverity[severity], status.lastMessageCount, clippedMsg)
  else
    return string.format("%02d:%02d %s %s", status.flightTime/60, status.flightTime%60, mavSeverity[severity], clippedMsg)
  end
end

utils.pushMessage = function(severity, msg)
  if conf.enableHaptic then
    playHaptic(15,0)
  end
  if conf.disableAllSounds == false then
    if ( severity < 5 and conf.disableMsgBeep < 3) then
      utils.playSound("../err",true)
    else
      if conf.disableMsgBeep < 2 then
        utils.playSound("../inf",true)
      end
    end
  end
  
  if msg == status.lastMessage then
    status.lastMessageCount = status.lastMessageCount + 1
  else  
    status.lastMessageCount = 1
    status.messageCount = status.messageCount + 1
  end
  local msgIndex = (status.messageCount-1) % 200
  if status.messages[msgIndex] == nil then
    status.messages[msgIndex] = {}
  end
  status.messages[msgIndex][1] = formatMessage(severity,msg)
  status.messages[msgIndex][2] = severity
  
  status.lastMessage = msg
  status.lastMessageSeverity = severity
  -- each new message scrolls all messages to the end (offset is absolute)
  if status.messageAutoScroll == true then
    status.messageOffset = math.max(0, status.messageCount - 20)
  end
end


utils.getHomeFromAngleAndDistance = function(telemetry)
--[[
  la1,lo1 coordinates of first point
  d be distance (m),
  R as radius of Earth (m),
  Ad be the angular distance i.e d/R and
  Theta be the bearing in deg
  
  la2 =  asin(sin la1 * cos Ad  + cos la1 * sin Ad * cos Theta), and
  lo2 = lo1 + atan2(sin Theta * sin Ad * cos la1 , cos Ad – sin la1 * sin la2)
--]]
  if telemetry.lat == nil or telemetry.lon == nil then
    return nil,nil
  end
  
  local lat1 = math.rad(telemetry.lat)
  local lon1 = math.rad(telemetry.lon)
  local Ad = telemetry.homeDist/(6371000) --meters
  local lat2 = math.asin( math.sin(lat1) * math.cos(Ad) + math.cos(lat1) * math.sin(Ad) * math.cos( math.rad(telemetry.homeAngle)) )
  local lon2 = lon1 + math.atan2( math.sin( math.rad(telemetry.homeAngle) ) * math.sin(Ad) * math.cos(lat1) , math.cos(Ad) - math.sin(lat1) * math.sin(lat2))
  return math.deg(lat2), math.deg(lon2)
end


utils.decToDMS = function(dec,lat)
  local D = math.floor(math.abs(dec))
  local M = (math.abs(dec) - D)*60
  local S = (math.abs((math.abs(dec) - D)*60) - M)*60
	return D .. string.format("\64%04.2f", M) .. (lat and (dec >= 0 and "E" or "W") or (dec >= 0 and "N" or "S"))
end

utils.decToDMSFull = function(dec,lat)
  local D = math.floor(math.abs(dec))
  local M = math.floor((math.abs(dec) - D)*60)
  local S = (math.abs((math.abs(dec) - D)*60) - M)*60
	return D .. string.format("\64%d'%04.1f", M, S) .. (lat and (dec >= 0 and "E" or "W") or (dec >= 0 and "N" or "S"))
end

utils.updateTotalDist = function()
  if telemetry.armingStatus == 0 then
    lastUpdateTotDist = getTime()
    return
  end
  local delta = getTime() - lastUpdateTotDist
  local avgSpeed = (telemetry.hSpeed + lastSpeed)/2
  lastUpdateTotDist = getTime()
  lastSpeed = telemetry.hSpeed
  if avgSpeed * 0.1 > 1 then
    telemetry.totalDist = telemetry.totalDist + (avgSpeed * 0.1 * delta * 0.01) --hSpeed dm/s, getTime()/100 secs
  end
end

utils.drawBlinkBitmap = function(bitmap,x,y)
  if blinkon == true then
      lcd.drawBitmap(utils.getBitmap(bitmap),x,y)
  end
end

local function getSensorsConfigFilename()
  local info = model.getInfo()
  local cfg = "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "").."_sensors.lua")
  local file = io.open(cfg,"r")
  
  if file == nil then
    cfg = "/SCRIPTS/YAAPU/CFG/default_sensors.lua"
  else
    io.close(file)
  end
  
  return cfg
end

local function getBattConfigFilename()
  local info = model.getInfo()
  return "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "").."_batt.lua")
end

--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------

utils.loadCustomSensors = function()
  local success, sensorScript = pcall(loadScript,getSensorsConfigFilename())
  if success then
    if sensorScript == nil then
      customSensors = nil
      return
    end
    customSensors = sensorScript()
    -- handle nil values for warning and critical levels
    for i=1,6
    do
      if customSensors.sensors[i] ~= nil then 
        local sign = customSensors.sensors[i][6] == "+" and 1 or -1
        if customSensors.sensors[i][9] == nil then
          customSensors.sensors[i][9] = math.huge*sign
        end
        if customSensors.sensors[i][8] == nil then
          customSensors.sensors[i][8] = math.huge*sign
        end
      end
    end
  else
    customSensors = nil
  end
end

-------------------------------------------
-- Battery Percentage By Voltage
-------------------------------------------
utils.loadBatteryConfigFile = function()
  local success, battConfig = pcall(loadScript,getBattConfigFilename())
  if success then
    if battConfig == nil then
      battPercByVoltage = {}
      return
    end
    battPercByVoltage = battConfig()
    --utils.pushMessage(6,"battery curve loaded")
  else
    battPercByVoltage = {}
  end
end

local function startTimer()
  status.lastTimerStart = getTime()/100
  model.setTimer(2,{mode=1})
end

local function stopTimer()
  model.setTimer(2,{mode=0})
  status.lastTimerStart = 0
end


-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
local function updateHash(c)
  hash = bit32.bxor(hash, c)
  hash = (hash * 16777619) % 2^32
  hashByteIndex = hashByteIndex+1
  -- check if this hash matches any 16bytes prefix hash
  if hashByteIndex == 16 then
     parseShortHash = shortHashes[hash]
     shortHash = hash
  end
end

local function playHash()
  -- try to play the hash sound file without checking for existence
  -- OpenTX will gracefully ignore it :-)
  utils.playSound(tostring(shortHash == nil and hash or shortHash),true)
  -- if required parse parameter and play it!
  if parseShortHash == true then
    local param = string.match(status.msgBuffer, ".*#(%d+).*")
    if param ~= nil then
      playNumber(tonumber(param),0)
    end
  end
end

local function resetHash()
  -- reset hash for next string
  parseShortHash = false
  shortHash = nil
  hash = 2166136261
  hashByteIndex = 0
end

local function MarkHome() -- inspired by Mav2PT
  if telemetry.gpsStatus >= 3 and telemetry.statusArmed == 1 then
	status.homeGood = true
	-- save current position
	status.homelat = telemetry.lat
	status.homelon = telemetry.lon
	status.homealt = telemetry.gpsAlt
	status.homehdg = telemetry.yaw
  end
end

-- processes OlliW MavSDK (MAVLink enhanced OpenTX) data
local function processMAVLink()
	-- telemetry.roll
	local roll = mavsdk.getAttRollDeg()
	if roll ~= nil then telemetry.roll = roll end
	-- telemetry.pitch
	local pitch = mavsdk.getAttPitchDeg()
	if pitch ~= nil then telemetry.pitch = pitch end
	-- telemetry.range
	local range = mavsdk.apGetRangefinder()
	if range ~= nil then telemetry.range = range * 100 end -- from m to cm
	-- telemetry.vSpeed
	local vSpeed = mavsdk.getVfrClimbRate()
	if vSpeed ~= nil then telemetry.vSpeed = vSpeed * 10 end -- from m/s to dm/s 
	-- telemetry.hSpeed
	local hSpeed = mavsdk.getVfrGroundSpeed()
	if hSpeed ~= nil then telemetry.hSpeed =  hSpeed * 10 end -- from m/s to dm/s
	-- telemetry.yaw
	local yaw = mavsdk.getVfrHeadingDeg()
	if yaw ~= nil then telemetry.yaw = yaw end
	-- telemetry.flightMode
	local fm = mavsdk.getFlightMode()
	if fm ~= nil then telemetry.flightMode = fm + 1 end -- needs to be incremented by one from MAVLink standard output
	-- telemetry.simpleMode
	telemetry.simpleMode = 0
	-- telemetry.statusArmed and telemetry.landComplete
	local armed = mavsdk.isArmed()
	if armed ~= nil then
		if armed then
		  telemetry.statusArmed = 1
		  telemetry.landComplete = 1
		else
		  telemetry.statusArmed = 0
		  telemetry.landComplete = 0
		end
        if not status.homeGood then
		  MarkHome()
		end
	end
	-- telemetry.ekfFailsafe
	telemetry.ekfFailsafe = 0
	-- telemetry.imuTemp -- [°C] value not yet parsed by OlliW
	-- telemetry.numSats
	local gpssat = mavsdk.getGpsSat()
	if gpssat ~= nil then
	  if gpssat > 99 then gpssat = 0 end
	  telemetry.numSats = gpssat
	end
	-- telemetry.gpsStatus
	local gpsStatus = mavsdk.getGpsFix()
	if gpsStatus ~= nil then
		telemetry.gpsStatus = gpsStatus
	    if not status.homeGood then
		  MarkHome()
		end
	end
	-- telemetry.gpsHdopC
	local Hdop = mavsdk.getGpsHDop() -- here NOT divided with 10 to keep the original dilution scale
	if Hdop ~= nil then telemetry.gpsHdopC = Hdop end
	-- telemetry.gpsAlt
	local gpsAlt = mavsdk.getGpsAltitudeMsl()
	if gpsAlt ~= nil then telemetry.gpsAlt = gpsAlt * 10 end -- from m to dm
	-- telemetry.batt1volt
	local batt1Volt = mavsdk.getBatVoltage()
	if batt1Volt ~= nil then telemetry.batt1volt = batt1Volt * 10 end -- from V to dV
	-- telemetry.batt1current
	local BatCurrent = mavsdk.getBatCurrent()
	if BatCurrent ~= nil then telemetry.batt1current = BatCurrent end
	-- telemetry.batt1mah
	local BatCharge = mavsdk.getBatChargeConsumed()
	if BatCharge ~= nil then telemetry.batt1mah = BatCharge end
	-- telemetry.batt2volt
	local batt2Volt = mavsdk.getBat2Voltage()
	if batt2Volt ~= nil then telemetry.batt2volt = batt2Volt * 10 end -- from V to dV
	-- telemetry.batt2current
	local Bat2current = mavsdk.getBat2Current()
	if Bat2current ~= nil then telemetry.batt2current = Bat2current end
	-- telemetry.batt2mah
	local Bat2Charge = mavsdk.getBat2ChargeConsumed()
	if Bat2Charge ~= nil then telemetry.batt2mah = Bat2Charge end
	-- telemetry.lat and telemetry.lon
	local latlon = mavsdk.getGpsLatLonInt()
	if latlon.lat ~= nil then
	  telemetry.lat = latlon.lat / 10000000	-- converted to degrees.fraction
	end
	if latlon.lon ~= nil then
	  telemetry.lon = latlon.lon / 10000000 -- converted to degrees.fraction
	end
	-- telemetry.homeAngle and telemetry.homeDist
	if status.homeGood and status.homelon ~= nil and status.homelat ~= nil and telemetry.lon ~= nil and telemetry.lat ~= nil then
	  -- Equations from Mav2PT FrSky_Ports.h
	  local lon1 = status.homelon/180*math.pi;  -- home position, converted from degrees to radians
      local lat1 = status.homelat/180*math.pi;
      local lon2 = telemetry.lon/180*math.pi; -- current position
      local lat2 = telemetry.lat/180*math.pi;
	  local dLat = (lat2-lat1); -- latitude difference
      local dLon = (lon2-lon1); -- longitude difference
      -- telemetry.homeAngle
	  -- Calculate azimuth bearing of craft from home
	  local ab = math.atan2(math.sin(lon2-lon1)*math.cos(lat2), math.cos(lat1)*math.sin(lat2)-math.sin(lat1)*math.cos(lat2)*math.cos(lon2-lon1)) * 180/math.pi - 180
	  if ab < 0 then ab = ab + 360 end
	  if ab > 359 then ab = ab - 360 end
	  telemetry.homeAngle = ab
	  -- telemetry.homeDist
      local a = math.sin(dLat/2) * math.sin(dLat/2) + math.sin(dLon/2) * math.sin(dLon/2) * math.cos(lat1) * math.cos(lat2); 
	  if a == 0 then
	    telemetry.homeDist = 0
	  else
		telemetry.homeDist = 6371000 * 2 * math.asin(math.sqrt(a)) -- radius of the Earth is 6371km
	  end
	end
	-- telemetry.homeAlt
	local homeAlt = mavsdk.getPositionAltitudeRelative() -- getVfrAltitudeMsl()
	if homeAlt ~= nil then telemetry.homeAlt = homeAlt * 10 end -- from m to dm
	-- messages
	if mavsdk.isStatusTextAvailable() then
	  local severity, txt = mavsdk.getStatusText()
	  utils.pushMessage(severity, txt)
	  playHash()
      resetHash()
	end
	-- telemetry.frameType
	local frameType = mavsdk.getVehicleType()
	if frameType ~= nil then telemetry.frameType = frameType end
	-- telemetry.batt1Capacity
	local batt1Capacity = mavsdk.getBatCapacity()
	if batt1Capacity ~= nil then telemetry.batt1Capacity = batt1Capacity end 
    -- telemetry.batt2Capacity
	local batt2Capacity = mavsdk.getBat2Capacity()
	if batt2Capacity ~= nil then telemetry.batt2Capacity = batt2Capacity end
	-- telemetry.wpNumber and telemetry.wpCommands
	local mission = mavsdk.getMission()
	if mission.current_seq ~= nil and mission.current_seq ~= 65535 then telemetry.wpNumber = mission.current_seq end -- OlliW initializes to UINT16_MAX, need to discard this value
	if mission.count ~= nil then telemetry.wpCommands = mission.count end
    -- telemetry.wpDistance
	local navcontroller = mavsdk.getNavController()
	if navcontroller.wp_dist ~= nil then telemetry.wpDistance = navcontroller.wp_dist end -- unit m
    -- telemetry.wpXTError not yet used in telemetry script further and also not yet parsed by OlliW
    -- telemetry.wpBearing
	local cog = mavsdk.getGpsCourseOverGroundDeg()
	if navcontroller.target_bearing ~= nil and cog ~= nil then
	  -- Equation from Mav2PT FrSky_Ports.h
	  local angle = math.fmod (navcontroller.target_bearing - cog, 360.0);
      if angle < 0 then angle = angle + 360.0 end -- shift, if necessary, to be in range between 0 and 360
	  telemetry.wpBearing = ((angle + 22.5) / 45.0) % 8 -- convert into nearest 45° bearing offset from COG (to match FrSky PT)
	end
	-- telemetry.airspeed
    local airspeed = mavsdk.getVfrAirSpeed()
	if airspeed ~= nil then telemetry.airspeed = airspeed * 10 end -- from m/s to dm/s
	-- telemetry.throttle
	local throttle = mavsdk.getVfrThrottle()
	if throttle ~= nil then telemetry.throttle = throttle end -- unit [%]
    -- telemetry.baroAlt
	local baroAlt = mavsdk.getVfrAltitudeMsl()
	if baroAlt ~= nil then telemetry.baroAlt = baroAlt end
	-- RSSI
	local rssi = mavsdk.getRadioRssiScaled()
	if rssi ~= nil then telemetry.rssiMAVLink = rssi end -- scaling 0 to 100 (FrSky 0 to 99)
end

local function processFrSkyPTtelemetry(DATA_ID,VALUE)
  if DATA_ID == 0x5006 then -- ROLLPITCH
    -- roll [0,1800] ==> [-180,180]
    telemetry.roll = (math.min(bit32.extract(VALUE,0,11),1800) - 900) * 0.2
    -- pitch [0,900] ==> [-90,90]
    telemetry.pitch = (math.min(bit32.extract(VALUE,11,10),900) - 450) * 0.2
    -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
    telemetry.range = bit32.extract(VALUE,22,10) * (10^bit32.extract(VALUE,21,1)) -- cm
  elseif DATA_ID == 0x5005 then -- VELANDYAW
    telemetry.vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1)) * (bit32.extract(VALUE,8,1) == 1 and -1 or 1)-- dm/s 
    telemetry.hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1)) -- dm/s
    telemetry.yaw = bit32.extract(VALUE,17,11) * 0.2
  elseif DATA_ID == 0x5001 then -- AP STATUS
    telemetry.flightMode = bit32.extract(VALUE,0,5)
    telemetry.simpleMode = bit32.extract(VALUE,5,2)
    telemetry.landComplete = bit32.extract(VALUE,7,1)
    telemetry.statusArmed = bit32.extract(VALUE,8,1)
    telemetry.battFailsafe = bit32.extract(VALUE,9,1)
    telemetry.ekfFailsafe = bit32.extract(VALUE,10,2)
    -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
    telemetry.imuTemp = bit32.extract(VALUE,26,6) + 19 -- °C
  elseif DATA_ID == 0x5002 then -- GPS STATUS
    telemetry.numSats = bit32.extract(VALUE,0,4)
    -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
    -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
    telemetry.gpsStatus = bit32.extract(VALUE,4,2) + bit32.extract(VALUE,14,2)
    telemetry.gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
    telemetry.gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1)-- dm
  elseif DATA_ID == 0x5003 then -- BATT
    telemetry.batt1volt = bit32.extract(VALUE,0,9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell1Count == 12 and telemetry.batt1volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt1volt = 512 + telemetry.batt1volt
    end
    telemetry.batt1current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
    telemetry.batt1mah = bit32.extract(VALUE,17,15)
  elseif DATA_ID == 0x5008 then -- BATT2
    telemetry.batt2volt = bit32.extract(VALUE,0,9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell2Count == 12 and telemetry.batt2volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt2volt = 512 + telemetry.batt2volt
    end
    telemetry.batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
    telemetry.batt2mah = bit32.extract(VALUE,17,15)
  elseif DATA_ID == 0x5004 then -- HOME
    telemetry.homeDist = bit32.extract(VALUE,2,10) * (10^bit32.extract(VALUE,0,2))
    telemetry.homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1 * (bit32.extract(VALUE,24,1) == 1 and -1 or 1)
    telemetry.homeAngle = bit32.extract(VALUE, 25,  7) * 3
  elseif DATA_ID == 0x5000 then -- MESSAGES
    if VALUE ~= status.lastMsgValue then
      status.lastMsgValue = VALUE
      local c
      local msgEnd = false
      for i=3,0,-1
      do
        c = bit32.extract(VALUE,i*8,7)
        if c ~= 0 then
          status.msgBuffer = status.msgBuffer .. string.char(c)
          updateHash(c)
        else
          msgEnd = true;
          break;
        end
      end
      if msgEnd then
        local severity = (bit32.extract(VALUE,7,1) * 1) + (bit32.extract(VALUE,15,1) * 2) + (bit32.extract(VALUE,23,1) * 4)
        utils.pushMessage( severity, status.msgBuffer)
        playHash()
        resetHash()
        status.msgBuffer = nil
        status.msgBuffer = ""
      end
    end
  elseif DATA_ID == 0x5007 then -- PARAMS
    paramId = bit32.extract(VALUE,24,4)
    paramValue = bit32.extract(VALUE,0,24)
    if paramId == 1 then
      telemetry.frameType = paramValue
    elseif paramId == 4 then
      telemetry.batt1Capacity = paramValue
    elseif paramId == 5 then
      telemetry.batt2Capacity = paramValue
    elseif paramId == 6 then
      telemetry.wpCommands = paramValue
    end 
  elseif DATA_ID == 0x5009 then -- WAYPOINTS @1Hz
    telemetry.wpNumber = bit32.extract(VALUE,0,10) -- wp index
    telemetry.wpDistance = bit32.extract(VALUE,12,10) * (10^bit32.extract(VALUE,10,2)) -- meters
    telemetry.wpXTError = bit32.extract(VALUE,23,4) * (10^bit32.extract(VALUE,22,1)) * (bit32.extract(VALUE,27,1) == 1 and -1 or 1)-- meters
    telemetry.wpBearing = bit32.extract(VALUE,29,3) -- offset from cog with 45° resolution 
  --[[
  elseif DATA_ID == 0x50F1 then -- RC CHANNELS
    -- channels 1 - 32
    local offset = bit32.extract(VALUE,0,4) * 4
    rcchannels[1 + offset] = 100 * (bit32.extract(VALUE,4,6)/63) * (bit32.extract(VALUE,10,1) == 1 and -1 or 1) 
    rcchannels[2 + offset] = 100 * (bit32.extract(VALUE,11,6)/63) * (bit32.extract(VALUE,17,1) == 1 and -1 or 1)
    rcchannels[3 + offset] = 100 * (bit32.extract(VALUE,18,6)/63) * (bit32.extract(VALUE,24,1) == 1 and -1 or 1)
    rcchannels[4 + offset] = 100 * (bit32.extract(VALUE,25,6)/63) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1)
  --]]
  elseif DATA_ID == 0x50F2 then -- VFR
    telemetry.airspeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1)) -- dm/s
    telemetry.throttle = bit32.extract(VALUE,8,7)
    telemetry.baroAlt = bit32.extract(VALUE,17,10) * (10^bit32.extract(VALUE,15,2)) * 0.1 * (bit32.extract(VALUE,27,1) == 1 and -1 or 1)
  end
end

local function telemetryEnabled()
  if conf.enableMAVLink then
	if not mavsdk.isReceiving() then
	  status.noTelemetryData = 1
	end
    return status.noTelemetryData == 0
  end
  -- not MAVLink  
  if getRSSI() == 0 then
    status.noTelemetryData = 1
  end
  return status.noTelemetryData == 0
end

utils.getMaxValue = function(value,idx)
  minmaxValues[idx] = math.max(value,minmaxValues[idx])
  return status.showMinMaxValues == true and minmaxValues[idx] or value
end

local function calcMinValue(value,min)
  return min == 0 and value or math.min(value,min)
end

-- returns the actual minimun only if both are > 0
local function getNonZeroMin(v1,v2)
  return v1 == 0 and v2 or ( v2 == 0 and v1 or math.min(v1,v2))
end

local function getBatt1Capacity()
  return conf.battCapOverride1 > 0 and conf.battCapOverride1*10 or telemetry.batt1Capacity
end

local function getBatt2Capacity()
  -- this is a fix for passthrough telemetry reporting batt2 capacity > 0 even if BATT2_MONITOR = 0
  return conf.battCapOverride2 > 0 and conf.battCapOverride2*10 or ( status.batt2sources.fc and telemetry.batt2Capacity or 0 )
end

-- gets the voltage based on source and min value, battId = [1|2]
local function getMinVoltageBySource(source, cell, cellFC, battId)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > 4.35*2 or cellFC > 4.35*2 then
    offset = 2
  end
  --
  if source == "vs" then
    return status.showMinMaxValues == true and minmaxValues[2+offset+battId] or cell
  elseif source == "fc" then
      -- FC only tracks batt1 and batt2 no cell voltage tracking
      local minmax = (offset == 2 and minmaxValues[battId] or minmaxValues[battId]/calcCellCount())
      return status.showMinMaxValues == true and minmax or cellFC
  end
  --
  return 0
end

local function calcFLVSSBatt(battIdx)
  local cellMin,cellSum,cellCount
  local battSources = battIdx == 1 and status.batt1sources or status.batt2sources

  local cellResult = battIdx == 1 and getValue("Cels") or getValue("Cel2")
  
  if type(cellResult) == "table" then
    cellMin = 4.35
    cellSum = 0
    -- cellcount is global and shared
    cellCount = #cellResult
    for i, v in pairs(cellResult) do
      cellSum = cellSum + v
      if cellMin > v then
        cellMin = v
      end
    end
    -- if connected after scritp started
    if battSources.vs == false then
      status.battsource = "na"
    end
    if status.battsource == "na" then
      status.battsource = "vs"
    end
    battSources.vs = true
  else
    battSources.vs = false
    cellMin = 0
    cellSum = 0
  end
  return cellMin,cellSum,cellCount
end

local function calcBattery()
  ------------
  -- FLVSS 1
  ------------
  status.cell1min, status.cell1sum, status.cell1count = calcFLVSSBatt(1) --1 = Cels
  
  ------------
  -- FLVSS 2
  ------------
  status.cell2min, status.cell2sum, status.cell2count = calcFLVSSBatt(2) --2 = Cel2
  
  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if telemetry.batt1volt > 0 then
    status.cell1sumFC = telemetry.batt1volt*0.1
    status.cell1maxFC = math.max(telemetry.batt1volt,status.cell1maxFC)
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    status.batt1sources.fc = true
  else
    status.batt1sources.fc = false
    status.cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if telemetry.batt2volt > 0 then
    status.cell2sumFC = telemetry.batt2volt*0.1
    status.cell2maxFC = math.max(telemetry.batt2volt,status.cell2maxFC)
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    status.batt2sources.fc = true
  else
    status.batt2sources.fc = false
    status.cell2sumFC = 0
  end
  -- batt fc
  minmaxValues[1] = calcMinValue(status.cell1sumFC,minmaxValues[1])
  minmaxValues[2] = calcMinValue(status.cell2sumFC,minmaxValues[2])
  -- cell flvss
  minmaxValues[3] = calcMinValue(status.cell1min,minmaxValues[3])
  minmaxValues[4] = calcMinValue(status.cell2min,minmaxValues[4])
  -- batt flvss
  minmaxValues[5] = calcMinValue(status.cell1sum,minmaxValues[5])
  minmaxValues[6] = calcMinValue(status.cell2sum,minmaxValues[6])
  --
  ------------------------------------------
  -- table to pass battery info to panes
  -- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
  -- value = offset + [0 aggregate|1 for batt 1| 2 for batt2]
  -- batt2 = 4 + 2 = 6
  ------------------------------------------
  
  -- 1 1
  -- 4 4
  -- 7 7
  -- 10 10
  -- 13 13
  -- 16 16
  -- possible battery configs
  -- 1, 2, 3, 4, 5, 6
  
  -- Note: these can be calculated. not necessary to track them as min/max 
  -- cell1minFC = cell1sumFC/calcCellCount()
  -- cell2minFC = cell2sumFC/calcCellCount()
  -- cell1minA2 = cell1sumA2/calcCellCount()
  --
  local count1,count2 = calcCellCount()
  
  battery[1+1] = getMinVoltageBySource(status.battsource, status.cell1min, status.cell1sumFC/count1, 1)*100 --cel1m
  battery[1+2] = getMinVoltageBySource(status.battsource, status.cell2min, status.cell2sumFC/count2, 2)*100 --cel2m

  battery[4+1] = getMinVoltageBySource(status.battsource, status.cell1sum, status.cell1sumFC, 1)*10 --batt1
  battery[4+2] = getMinVoltageBySource(status.battsource, status.cell2sum, status.cell2sumFC, 2)*10 --batt2

  battery[7+1] = utils.getMaxValue(telemetry.batt1current,8) --curr1
  battery[7+2] = utils.getMaxValue(telemetry.batt2current,9) --curr2

  battery[10+1] = telemetry.batt1mah --mah1
  battery[10+2] = telemetry.batt2mah --mah2
  
  battery[13+1] = getBatt1Capacity() --cap1
  battery[13+2] = getBatt2Capacity() --cap2
  
  if (conf.battConf == 1) then
    battery[1] = getNonZeroMin(battery[2], battery[3])
    battery[4] = getNonZeroMin(battery[5],battery[6])
    battery[7] = utils.getMaxValue(telemetry.batt1current + telemetry.batt2current, 7)    
    battery[10] = telemetry.batt1mah + telemetry.batt2mah
    battery[13] = getBatt2Capacity() + getBatt1Capacity()
  elseif (conf.battConf == 2) then
    battery[1] = getNonZeroMin(battery[2], battery[3])
    battery[4] = battery[5] + battery[6]
    battery[7] = utils.getMaxValue(telemetry.batt1current,7)
    battery[10] = telemetry.batt1mah
    battery[13] = getBatt1Capacity()
  elseif (conf.battConf == 3) then
    -- independent batteries, alerts and capacity % on battery 1
    battery[1] = battery[2]
    battery[4] = battery[5]
    battery[7] = utils.getMaxValue(telemetry.batt1current,7)    
    battery[10] = telemetry.batt1mah
    battery[13] = getBatt1Capacity()
  elseif (conf.battConf == 4) then
    -- independent batteries, alerts and capacity % on battery 2
    battery[1] = battery[3]
    battery[4] = battery[6]
    battery[7] = utils.getMaxValue(telemetry.batt2current,7)    
    battery[10] = telemetry.batt2mah
    battery[13] = getBatt2Capacity()
  elseif (conf.battConf == 5) then
    -- independent batteries, voltage alerts on battery 1, capacity % on battery 2
    battery[1] = battery[2]
    battery[4] = battery[5]
    battery[7] = utils.getMaxValue(telemetry.batt2current,7)    
    battery[10] = telemetry.batt2mah
    battery[13] = getBatt2Capacity()
  elseif (conf.battConf == 6) then
    -- independent batteries, voltage alerts on battery 2, capacity % on battery 1
    battery[1] = battery[3]
    battery[4] = battery[6]
    battery[7] = utils.getMaxValue(telemetry.batt1current,7)    
    battery[10] = telemetry.batt1mah
    battery[13] = getBatt1Capacity()
  end
  
  --[[
    discharge curve is based on battery under load, when motors are disarmed
    cellvoltage needs to be corrected by subtracting the "under load" voltage drop
  --]]
  if conf.enableBattPercByVoltage == true then
    for battId=0,2
    do
      if telemetry.statusArmed == 1 then
        battery[16+battId] = utils.getBattPercByCell(0.01*battery[1+battId])
      else
        battery[16+battId] = utils.getBattPercByCell((0.01*battery[1+battId])-0.15)
      end
    end
  else
  for battId=0,2
  do
    if (battery[13+battId] > 0) then
      battery[16+battId] = (1 - (battery[10+battId]/battery[13+battId]))*100
      if battery[16+battId] > 99 then
        battery[16+battId] = 99
      elseif battery[16+battId] < 0 then
        battery[16+battId] = 0
      end
    else
      battery[16+battId] = 99
    end
  end
  end
  
  if status.showDualBattery == true and conf.battConf ==  1 then
    -- dual parallel battery: do I have also dual current monitor?
    if battery[7+1] > 0 and battery[7+2] == 0  then
      -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
      battery[7+1] = battery[7+1]/2 --curr1
      battery[7+2] = battery[7+1]   --curr2
      --
      battery[10+1]  = battery[10+1]/2  --mah1
      battery[10+2]  = battery[10+1]    --mah2
      --
      battery[13+1] = battery[13+1]/2   --cap1
      battery[13+2] = battery[13+1]     --cap2
      --
      battery[16+1] = battery[16+1]/2   --perc1
      battery[16+2] = battery[16+1]     --perc2
    end
  end
end

local function checkLandingStatus()
  if ( status.timerRunning == 0 and telemetry.landComplete == 1 and status.lastTimerStart == 0) then
    startTimer()
  end
  if (status.timerRunning == 1 and telemetry.landComplete == 0 and status.lastTimerStart ~= 0) then
    stopTimer()
    -- play landing complete only if motors are armed
    if telemetry.statusArmed == 1 then
      utils.playSound("landing")
    end
  end
  status.timerRunning = telemetry.landComplete
end

local function drainTelemetryQueues()
  if conf.enableCRSF == false then
    -- SPORT
    local i = 0  
    -- empty sport queue
    local a,b,c,d = sportTelemetryPop()
    while a ~= null and i < 50 do
      a,b,c,d = sportTelemetryPop()
      i = i + 1
    end
  else
    -- CRSF
    local i = 0  
    -- empty sport queue
    local a,b = crossfireTelemetryPop()
    while a ~= null and i < 50 do
      a,b = crossfireTelemetryPop()
      i = i + 1
    end
  end
end

local function drawRssi()
  -- RSSI
  if conf.enableMAVLink then
    -- MavSDK RSSI can have up to 3 digits. Need to be more left in comparison to FrSky 2 digit RSSI output
    lcd.drawText(294, 0, "RSSI:", 0 +CUSTOM_COLOR)
    lcd.drawText(294 + 47, 0, telemetry.rssiMAVLink, 0 +CUSTOM_COLOR)
  else
    -- only 2 RSSI digits max with FrSky
    lcd.drawText(304, 0, "RSSI:", 0 +CUSTOM_COLOR)
    lcd.drawText(304 + 47, 0, getRSSI(), 0 +CUSTOM_COLOR)  
  end  
end

local function drawRssiCRSF()
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- RSSI
  lcd.drawText(323 - 128, 0, "RTP:", 0 +CUSTOM_COLOR+SMLSIZE)
  lcd.drawText(323, 0, "RS:", 0 +CUSTOM_COLOR+SMLSIZE)
  lcd.drawText(323 - 128 + 30, 0, string.format("%d/%d/%d",getValue("RQly"),getValue("TQly"),getValue("TPWR")), 0 +CUSTOM_COLOR+SMLSIZE)  
  lcd.drawText(323 + 22, 0, string.format("%d/%d", status.rssiCRSF, getValue("RFMD")), 0 +CUSTOM_COLOR+SMLSIZE)
end

local function resetTelemetry()
  -----------------------------
  -- TELEMETRY
  -----------------------------
  -- AP STATUS 
  telemetry.flightMode = 0
  telemetry.simpleMode = 0
  telemetry.landComplete = 0
  telemetry.statusArmed = 0
  telemetry.battFailsafe = 0
  telemetry.ekfFailsafe = 0
  telemetry.imuTemp = 0
  -- GPS
  telemetry.numSats = 0
  telemetry.gpsStatus = 0
  telemetry.gpsHdopC = 100
  telemetry.gpsAlt = 0
  -- BATT 1
  telemetry.batt1volt = 0
  telemetry.batt1current = 0
  telemetry.batt1mah = 0
  -- BATT 2
  telemetry.batt2volt = 0
  telemetry.batt2current = 0
  telemetry.batt2mah = 0
  -- HOME
  telemetry.homeDist = 0
  telemetry.homeAlt = 0
  telemetry.homeAngle = -1
  -- VELANDYAW
  telemetry.vSpeed = 0
  telemetry.hSpeed = 0
  telemetry.yaw = 0
  -- ROLLPITCH
  telemetry.roll = 0
  telemetry.pitch = 0
  telemetry.range = 0 
  -- PARAMS
  telemetry.frameType = -1
  telemetry.batt1Capacity = 0
  telemetry.batt2Capacity = 0
  -- GPS
  telemetry.lat = nil
  telemetry.lon = nil
  telemetry.homeLat = nil
  telemetry.homeLon = nil
  -- WP
  telemetry.wpNumber = 0
  telemetry.wpDistance = 0
  telemetry.wpXTError = 0
  telemetry.wpBearing = 0
  telemetry.wpCommands = 0
  -- RC channels
  telemetry.rcchannels = {}
  -- VFR
  telemetry.airspeed = 0
  telemetry.throttle = 0
  telemetry.baroAlt = 0
  --
  telemetry.totalDist = 0
end

local function resetStatus()
  -----------------------------
  -- SCRIPT STATUS
  -----------------------------
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
  -- BATT
  status.cell1count = 0
  status.cell2count = 0
  
  status.battsource = "na"
  -- BATT 1
  status.batt1sources = {
    vs = false,
    fc = false
  }
  -- BATT 2
  status.batt2sources = {
    vs = false,
    fc = false
  }
  -- TELEMETRY
  status.noTelemetryData = 1
  -- MESSAGES
  status.msgBuffer = ""
  status.lastMsgValue = 0
  status.lastMsgTime = 0
  -- FLIGHT TIME
  status.lastTimerStart = 0
  status.timerRunning = 0
  status.flightTime = 0
  -- EVENTS
  status.lastStatusArmed = 0
  status.lastGpsStatus = 0
  status.lastFlightMode = 0
  status.lastSimpleMode = 0
  -- battery levels
  status.batLevel = 99
  status.battLevel1 = false
  status.battLevel2 = false
  status.lastBattLevel = 14
  -------------------------
  -- BATTERY ARRAY
  -------------------------
  battery = {0,0,0,0,0,0,0,0,0,0,0,0}
end

local function resetMessages()
  -- MESSAGES
  utils.clearTable(status.messages)
  
  status.msgBuffer = ""
  status.lastMsgValue = 0
  status.lastMsgTime = 0
  status.lastMessage = nil
  status.lastMessageSeverity = 0
  status.lastMessageCount = 1
  status.messageCount = 0
  status.messages = {}
end

local function resetAlarms()
  -- reset alarms
  alarms[1] = { false, 0 , false, 0, 0, false, 0} --MIN_ALT
  alarms[2] = { false, 0 , true, 1 , 0, false, 0 } --MAX_ALT
  alarms[3] = { false, 0 , true, 1 , 0, false, 0 } --15
  alarms[4] = { false, 0 , true, 1 , 0, false, 0 } --FS_EKF
  alarms[5] = { false, 0 , true, 1 , 0, false, 0 } --FS_BAT
  alarms[6] = { false, 0 , true, 2, 0, false, 0 } --FLIGTH_TIME
  alarms[7] = { false, 0 , false, 3, 4, false, 0 } --BATT L1
  alarms[8] = { false, 0 , false, 4, 4, false, 0 } --BATT L2
  alarms[9] = { false, 0 , false, 1 , 0, false, 0 } --MAX_HDOP
end

local function resetTimers()
  -- stop and reset timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
end

local function reset()
  if resetPending then
    if resetPhase == 0 then
      -- reset frame
      utils.clearTable(frame.frameTypes)
      drainTelemetryQueues()
      resetPhase = 1
    elseif resetPhase == 1 then
      resetTelemetry()
      resetPhase = 2
    elseif resetPhase == 2 then
      resetStatus()
      resetPhase = 3
    elseif resetPhase == 3 then
      resetAlarms()
      resetPhase = 4
    elseif resetPhase == 4 then
      resetTimers()
      resetMessages()
      resetPhase = 5
    elseif resetPhase == 5 then
      currentPage = 0
      minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      status.showMinMaxValues = false
      status.showDualBattery = false
      status.strFlightMode = nil
      status.modelString = nil
      frame = {}
      resetPhase = 6
    elseif resetPhase == 6 then
      -- custom sensors
      utils.clearTable(customSensors)
      customSensors = nil
      utils.loadCustomSensors()
      -- done
      resetPhase = 7
    elseif resetPhase == 7 then
      utils.pushMessage(7,"Yaapu v1.9.3b2 w. OlliW v21 MavSDK by Risto")
      utils.playSound("yaapu")
      -- on model change reload config!
      if modelChangePending == true then
        -- force load model config
        loadConfigPending = true
        model.setGlobalVariable(8, 8, 1)
      end
      resetPhase = 0
      resetPending = false
    end
  end
end

local function calcFlightTime()
  -- update local variable with timer 3 value
  if ( model.getTimer(2).value < status.flightTime and telemetry.statusArmed == 0) then
    triggerReset()
  end
  if (model.getTimer(2).value < status.flightTime and telemetry.statusArmed == 1) then
    model.setTimer(2,{value=status.flightTime})
    utils.pushMessage(4,"Reset ignored while armed")
  end
  status.flightTime = model.getTimer(2).value
end

local function setSensorValues()
  if not conf.enableMAVLink then
    -- only if MAVLink is not enabled
    if (not telemetryEnabled()) then
      return
    end
    local battmah = telemetry.batt1mah
    local battcapacity = getBatt1Capacity()
    if telemetry.batt2mah > 0 then
      battcapacity =  getBatt1Capacity() + getBatt2Capacity()
      battmah = telemetry.batt1mah + telemetry.batt2mah
    end
  
    local perc = 0
  
    if (battcapacity > 0) then
      perc = math.min(math.max((1 - (battmah/battcapacity))*100,0),99)
    end

    -- CRSF
    if not conf.enableCRSF then
      setTelemetryValue(0x060F, 0, 0, perc, 13 , 0 , "Fuel")
      setTelemetryValue(0x020F, 0, 0, telemetry.batt1current+telemetry.batt2current, 2 , 1 , "CURR")
      setTelemetryValue(0x084F, 0, 0, math.floor(telemetry.yaw), 20 , 0 , "Hdg")
      setTelemetryValue(0x010F, 0, 0, telemetry.homeAlt*10, 9 , 1 , "Alt")
      setTelemetryValue(0x083F, 0, 0, telemetry.hSpeed*0.1, 5 , 0 , "GSpd")
    end
  
    setTelemetryValue(0x021F, 0, 0, getNonZeroMin(telemetry.batt1volt,telemetry.batt2volt)*10, 1 , 2 , "VFAS")
    setTelemetryValue(0x011F, 0, 0, telemetry.vSpeed, 5 , 1 , "VSpd")
    setTelemetryValue(0x082F, 0, 0, math.floor(telemetry.gpsAlt*0.1), 9 , 0 , "GAlt")
    setTelemetryValue(0x041F, 0, 0, telemetry.imuTemp, 11 , 0 , "IMUt")
    setTelemetryValue(0x060F, 0, 1, telemetry.statusArmed*100, 0 , 0 , "ARM")
  end
end

utils.drawTopBar = function()
  lcd.setColor(CUSTOM_COLOR,0x0000)  
  -- black bar
  lcd.drawFilledRectangle(0,0, LCD_W, 18, CUSTOM_COLOR)
  -- frametype and model name
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  if status.modelString ~= nil then
    lcd.drawText(2, 0, status.modelString, CUSTOM_COLOR)
  end
  -- flight time
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, 0, strtime, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- RSSI
  if telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR,0xF800)    
    lcd.drawText(323-36, 0, "NO TELEM", 0 +CUSTOM_COLOR)
  else
    utils.drawRssi()
  end
  lcd.setColor(CUSTOM_COLOR,0xFFFF)    
  -- tx voltage
  local vtx = string.format("%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(391,0, vtx, 0+CUSTOM_COLOR+SMLSIZE)
end

local function drawMessageScreen()
  local row = 0
  local offsetStart = status.messageOffset
  local offsetEnd = math.min(status.messageCount-1, status.messageOffset + 20 - 1)
  
  for i=offsetStart,offsetEnd  do
    if status.messages[i % 200][2] == 4 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255,0))
    elseif status.messages[i % 200][2] < 4 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,70,0))  
    else
      lcd.setColor(CUSTOM_COLOR,0xFFFF)
    end
    lcd.drawText(0,4+12*row, status.messages[i % 200][1],SMLSIZE+CUSTOM_COLOR)
    row = row+1
  end
  lcd.setColor(CUSTOM_COLOR,0x0AB1)
  lcd.drawFilledRectangle(405,0,75,272,CUSTOM_COLOR)
  
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- print info on the right
  -- CELL
  if battery[1] * 0.01 < 10 then
    lcd.drawNumber(410, 0, battery[1] + 0.5, PREC2+0+MIDSIZE+CUSTOM_COLOR)
  else
    lcd.drawNumber(410, 0, (battery[1] + 0.5)*0.1, PREC1+0+MIDSIZE+CUSTOM_COLOR)
  end
  lcd.drawText(410+50, 1, status.battsource, SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(410+50, 11, "V", SMLSIZE+CUSTOM_COLOR)
  -- ALT
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(410, 25, "Alt("..unitLabel..")", SMLSIZE+0+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawNumber(410,37,telemetry.homeAlt*unitScale,MIDSIZE+CUSTOM_COLOR+0)
  -- SPEED
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(410, 60, "Spd("..conf.horSpeedLabel..")", SMLSIZE+0+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawNumber(410,72,telemetry.hSpeed*0.1* conf.horSpeedMultiplier,MIDSIZE+CUSTOM_COLOR+0)
  -- VSPEED
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(410, 95, "VSI("..conf.vertSpeedLabel..")", SMLSIZE+0+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawNumber(410,107, telemetry.vSpeed*0.1*conf.vertSpeedMultiplier, MIDSIZE+CUSTOM_COLOR+0)
  -- DIST
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(410, 130, "Dist("..unitLabel..")", SMLSIZE+0+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawNumber(410, 142, telemetry.homeDist*unitScale, MIDSIZE+0+CUSTOM_COLOR)
  -- HDG
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(410, 165, "Heading", SMLSIZE+0+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawNumber(410, 177, telemetry.yaw, MIDSIZE+0+CUSTOM_COLOR)
  -- HOMEDIR
  lcd.setColor(CUSTOM_COLOR,0xFE60)
  drawLib.drawRArrow(442,235,22,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
  -- AUTOSCROLL
  if status.messageAutoScroll == true then
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
  else
    lcd.setColor(CUSTOM_COLOR,0xFE60)
  end
  local maxPages = tonumber(math.ceil((#status.messages+1)/20))
  local currentPage = 1+tonumber(maxPages - (status.messageCount - status.messageOffset)/20)
  
  lcd.drawText(LCD_W-2, LCD_H-16, string.format("%d/%d",currentPage,maxPages), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,0x7BCF)
  lcd.drawLine(0,LCD_H-20,405,LCD_H-20,SOLID,CUSTOM_COLOR)
  
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  if status.strFlightMode ~= nil then
    lcd.drawText(0,LCD_H-20,status.strFlightMode,CUSTOM_COLOR)
  end
  lcd.drawTimer(402, LCD_H-20, model.getTimer(2).value, CUSTOM_COLOR+RIGHT)
end

---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
utils.checkAlarm = function(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms except battery alerts
  if status.timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0, 0, false, 0} 
    elseif alarms[idx][4] == 1  then
      alarms[idx] = { false, 0, true, 1 , 0, false, 0}
    elseif  alarms[idx][4] == 2 then
      alarms[idx] = { false, 0, true, 2, 0, false, 0}
    elseif  alarms[idx][4] == 3 then
      alarms[idx] = { false, 0 , false, 3, 4, false, 0}
    elseif  alarms[idx][4] == 4 then
      alarms[idx] = { false, 0 , false, 4, 4, false, 0}
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level  
  if alarms[idx][3] == false and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][3] = true
  end

  if alarms[idx][4] == 2 then
    if status.flightTime > 0 and math.floor(status.flightTime) %  delay == 0 then
      if alarms[idx][1] == false then 
        alarms[idx][1] = true
        utils.playSound(sound)
        playDuration(status.flightTime,(status.flightTime > 3600 and 1 or 0)) -- minutes,seconds
      end
    else
        alarms[idx][1] = false
    end
  else
    if alarms[idx][3] == true then
      if level > 0 and sign*value > sign*level then
        -- value is outside level 
        if alarms[idx][2] == 0 then
          -- first time outside level after last reset
          alarms[idx][2] = status.flightTime
          -- status: START
        end
      else
        -- value back to normal ==> reset
        alarms[idx][2] = 0
        alarms[idx][1] = false
        alarms[idx][6] = false
        -- status: RESET
      end
      if alarms[idx][2] > 0 and (status.flightTime ~= alarms[idx][2]) and (status.flightTime - alarms[idx][2]) >= alarms[idx][5] then
        -- enough time has passed after START
        alarms[idx][6] = true
        -- status: READY
      end

      if alarms[idx][6] == true and alarms[idx][1] == false then 
        utils.playSound(sound)
        alarms[idx][1] = true
        alarms[idx][7] = status.flightTime
        -- status: BEEP
      end
      -- all but battery alarms
      if alarms[idx][4] ~= 3 then
        if alarms[idx][6] == true and status.flightTime ~= alarms[idx][7] and (status.flightTime - alarms[idx][7]) %  delay == 0 then
          alarms[idx][1] = false
          -- status: REPEAT
        end
      end
    end
  end
end

local function loadFlightModes()
  if frame.flightModes then
    return
  end
  if telemetry.frameType ~= -1 then
    if frameTypes[telemetry.frameType] == "c" then
      frame = utils.doLibrary(conf.enablePX4Modes and "copter_px4" or "copter")
    elseif frameTypes[telemetry.frameType] == "p" then
      frame = utils.doLibrary(conf.enablePX4Modes and "plane_px4" or "plane")
    elseif frameTypes[telemetry.frameType] == "r" or frameTypes[telemetry.frameType] == "b" then
      frame = utils.doLibrary("rover")
    end
  end
end

---------------------------------
-- This function checks state transitions and only returns true if a specific delay has passed
-- new transitions reset the delay timer
---------------------------------
local function checkTransition(idx,value)
  if value ~= transitions[idx][1] then
    -- value has changed 
    transitions[idx][1] = value
    transitions[idx][2] = getTime()
    transitions[idx][3] = false
    -- status: RESET
    return false
  end
  if transitions[idx][3] == false and (getTime() - transitions[idx][2]) > transitions[idx][4] then
    -- enough time has passed after RESET
    transitions[idx][3] = true
    -- status: FIRE
    return true;
  end
end

local function checkEvents(celm)
  loadFlightModes()
  
  -- silence alarms when showing min/max values
  if status.showMinMaxValues == false then
    utils.checkAlarm(conf.minAltitudeAlert,telemetry.homeAlt,1,-1,"minalt",conf.repeatAlertsPeriod)
    utils.checkAlarm(conf.maxAltitudeAlert,telemetry.homeAlt,2,1,"maxalt",conf.repeatAlertsPeriod)  
    utils.checkAlarm(conf.maxDistanceAlert,telemetry.homeDist,3,1,"maxdist",conf.repeatAlertsPeriod)  
    utils.checkAlarm(1,2*telemetry.ekfFailsafe,4,1,"ekf",conf.repeatAlertsPeriod)  
    utils.checkAlarm(1,2*telemetry.battFailsafe,5,1,"lowbat",conf.repeatAlertsPeriod)  
    utils.checkAlarm(conf.timerAlert,status.flightTime,6,1,"timealert",conf.timerAlert)
  end
  
  --[[
  -- default is use battery 1
  local capacity = getBatt1Capacity()
  local mah = telemetry.batt1mah
  -- only if dual battery has been detected use battery 2
  if (status.batt2sources.fc or status.batt2sources.vs) and conf.battConf == BATTCONF_PARALLEL then
      capacity = capacity + getBatt2Capacity()
      mah = mah  + telemetry.batt2mah
  end
  --]]
  if conf.enableBattPercByVoltage == true then
  -- discharge curve is based on battery under load, when motors are disarmed
  -- cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    if telemetry.statusArmed == 1 then
      status.batLevel = utils.getBattPercByCell(celm*0.01)
    else
      status.batLevel = utils.getBattPercByCell((celm*0.01)-0.15)
    end
  else
  if (battery[13] > 0) then
    status.batLevel = (1 - (battery[10]/battery[13]))*100
  else
    status.batLevel = 99
  end
  end
  
  for l=1,13 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    if status.batLevel <= batLevels[l] + 1 and l < status.lastBattLevel then
      status.lastBattLevel = l
      utils.playSound("bat"..batLevels[l])
      break
    end
  end
  
  if telemetry.statusArmed == 1 and status.lastStatusArmed == 0 then
    status.lastStatusArmed = telemetry.statusArmed
    utils.playSound("armed")
    -- reset home on arming
    telemetry.homeLat = nil
    telemetry.homeLon = nil
    status.homeGood = false
  elseif telemetry.statusArmed == 0 and status.lastStatusArmed == 1 then
    status.lastStatusArmed = telemetry.statusArmed
    utils.playSound("disarmed")
  end

  if telemetry.gpsStatus > 2 and status.lastGpsStatus <= 2 then
    status.lastGpsStatus = telemetry.gpsStatus
    utils.playSound("gpsfix")
  elseif telemetry.gpsStatus <= 2 and status.lastGpsStatus > 2 then
    status.lastGpsStatus = telemetry.gpsStatus
    utils.playSound("gpsnofix")
  end
  
  -- home detecting code
  if telemetry.homeLat == nil then
    if telemetry.gpsStatus > 2 and telemetry.homeAngle ~= -1 then
      telemetry.homeLat, telemetry.homeLon = utils.getHomeFromAngleAndDistance(telemetry)
    end
  end
   
  -- flightmode transitions have a grace period to prevent unwanted flightmode call out
  -- on quick radio mode switches
  if telemetry.frameType ~= -1 and checkTransition(1,telemetry.flightMode) then
    utils.playSoundByFlightMode(telemetry.flightMode)
  end

  if telemetry.simpleMode ~= status.lastSimpleMode then
    if telemetry.simpleMode == 0 then
      utils.playSound( status.lastSimpleMode == 1 and "simpleoff" or "ssimpleoff" )
    else
      utils.playSound( telemetry.simpleMode == 1 and "simpleon" or "ssimpleon" )
    end
    status.lastSimpleMode = telemetry.simpleMode
  end
end

local function checkCellVoltage(celm)
  -- check alarms
  utils.checkAlarm(conf.battAlertLevel1,celm,7,-1,"batalert1",conf.repeatAlertsPeriod)
  utils.checkAlarm(conf.battAlertLevel2,celm,8,-1,"batalert2",conf.repeatAlertsPeriod)
  -- cell bgcolor is sticky but gets triggered with alarms
  if status.battLevel1 == false then status.battLevel1 = alarms[7][1] end
  if status.battLevel2 == false then status.battLevel2 = alarms[8][1] end
end
--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
--
local bgclock = 0



-- telemetry pop function, either SPort or CRSF
local telemetryPop = nil

local function crossfirePop()
    local command, data = crossfireTelemetryPop()
    if (command == 0x80 or command == 0x7F) and data ~= nil then
      -- actual payload starts at data[2]
      if #data >= 7 and data[1] == 0xF0 then
        local app_id = bit32.lshift(data[3],8) + data[2]
        local value =  bit32.lshift(data[7],24) + bit32.lshift(data[6],16) + bit32.lshift(data[5],8) + data[4]
        return 0x00, 0x10, app_id, value
      elseif #data > 4 and data[1] == 0xF1 then
        local severity = data[2]
        -- copy the terminator as well
        for i=3,#data
        do
          status.msgBuffer = status.msgBuffer .. string.char(data[i])
          -- hash support
          updateHash(data[i])
        end
        utils.pushMessage(severity, status.msgBuffer)
        -- hash audio support
        playHash()
        -- hash reset
        resetHash()
        status.msgBuffer = nil
        status.msgBuffer = ""
      elseif #data > 48 and data[1] == 0xF2 then
        -- passthrough array
        local app_id, value
        for i=0,data[2]-1
        do
          app_id = bit32.lshift(data[4+(6*i)],8) + data[3+(6*i)]
          value =  bit32.lshift(data[8+(6*i)],24) + bit32.lshift(data[7+(6*i)],16) + bit32.lshift(data[6+(6*i)],8) + data[5+(6*i)]
          --utils.pushMessage(7,string.format("CRSF:%d - %04X:%08X",i, app_id, value), true)
          processFrSkyPTtelemetry(app_id, value)
        end
        status.noTelemetryData = 0
        status.hideNoTelemetry = true
      end
    end
    return nil, nil ,nil ,nil
end

local function loadConfig(init)
  -- load menu library
  local menuLib = utils.doLibrary("../"..menuLibFile)
  menuLib.loadConfig(conf)
  -- ok configuration loaded
  status.battsource = conf.defaultBattSource
  -- CRSF or SPORT?
  telemetryPop = sportTelemetryPop
  utils.drawRssi = drawRssi
  if conf.enableCRSF then
    telemetryPop = crossfirePop
    utils.drawRssi = drawRssiCRSF
  end
  -- do not reset layout on boot
  if init == nil then
    resetLayoutPending = true
    resetLayoutPhase = -1
  end
  status.mapZoomLevel=conf.mapProvider == 1 and conf.mapZoomMin or conf.mapZoomMax 
  loadConfigPending = false
end

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local timerPage = getTime()
local timerWheel = getTime()

local function backgroundTasks(myWidget,telemetryLoops)
  -- don't process telemetry while resetting to prevent CPU kill
  if resetPending == false and resetLayoutPending == false and loadConfigPending == false then
    if conf.enableMAVLink then
		if mavsdk.isReceiving() then
		   status.noTelemetryData = 0
           -- no telemetry dialog only shown once
		   status.hideNoTelemetry = true
	       processMAVLink()
		end
    else							   
	  for i=1,telemetryLoops
      do
        local sensor_id,frame_id,data_id,value = telemetryPop()
      
        if frame_id == 0x10 then
          status.noTelemetryData = 0
          -- no telemetry dialog only shown once
          status.hideNoTelemetry = true
          processFrSkyPTtelemetry(data_id,value)
        end
      end
    end
  end
  -- SLOW: this runs around 2.5Hz
  if bgclock % 2 == 1 then
    calcFlightTime()
    -- update gps telemetry data
    local gpsData = getValue("GPS")
    
    if type(gpsData) == "table" and gpsData.lat ~= nil and gpsData.lon ~= nil then
      telemetry.lat = gpsData.lat
      telemetry.lon = gpsData.lon
    end
    -- export OpenTX sensor values
    setSensorValues()
    -- update total distance as often as po
    utils.updateTotalDist()
    
    -- handle page emulation
    if getTime() - timerPage > 50 then
      status.screenTogglePage = utils.getScreenTogglePage(myWidget,conf,status)
      timerPage = getTime()
    end
    -- handle wheel emulation
    if getTime() - timerWheel > 200 then
      local chValue = getValue(conf.screenWheelChannelId)
      status.mapZoomLevel = utils.getMapZoomLevel(myWidget,conf,status,chValue)
      status.messageOffset = utils.getMessageOffset(myWidget,conf,status,chValue)
      timerWheel = getTime()
    end
    
    -- flight mode
    if frame.flightModes then
      status.strFlightMode = frame.flightModes[telemetry.flightMode]
      if status.strFlightMode ~= nil and telemetry.simpleMode > 0 then
        local strSimpleMode = telemetry.simpleMode == 1 and "(S)" or "(SS)"
        status.strFlightMode = string.format("%s%s",status.strFlightMode,strSimpleMode)
      end
    end
    
    -- top bar model frame and name
    if status.modelString == nil then
      -- frametype and model name
      local info = model.getInfo()
      local fn = frameNames[telemetry.frameType]
      local strmodel = info.name
      if fn ~= nil then
        status.modelString = fn..": "..info.name
      end      
    end
    
    if conf.enableCRSF then
      -- take the best signal and apply same algo used by ardupilot to estimate a 0-100 rssi value
      -- rssi = roundf((1.0f - (rssi_dbm - 50.0f) / 70.0f) * 255.0f);
      status.rssiCRSF = math.min(100, math.floor(0.5 + ((1-(math.min(getValue("1RSS"), getValue("2RSS")) - 50)/70)*100)))
    end
  end
  
  -- SLOWER: this runs around 1.25Hz but not when the previous block runs
  if bgclock % 4 == 0 then
    -- update battery
    calcBattery()
    -- prepare celm based on status.battsource
    local count1,count2 = calcCellCount()
    local cellVoltage = 0
    
    if conf.battConf == 3 or conf.battConf == 5 then
      -- voltage alarms are based on battery 1
      cellVoltage = 100*(status.battsource == "vs" and status.cell1min or status.cell1sumFC/count1)
    elseif conf.battConf == 4 or conf.battConf == 6 then
      -- voltage alarms are based on battery 2
      cellVoltage = 100*(status.battsource == "vs" and status.cell2min or status.cell2sumFC/count2)
    else
      -- alarms are based on battery 1 and battery 2
      cellVoltage = 100*(status.battsource == "vs" and getNonZeroMin(status.cell1min,status.cell2min) or getNonZeroMin(status.cell1sumFC/count1,status.cell2sumFC/count2))
    end
    
    checkEvents(cellVoltage)
    checkLandingStatus()
    -- no need for alarms if reported voltage is 0
    if cellVoltage > 0 then
      checkCellVoltage(cellVoltage)
    end
  
    local batcurrent = 0
    
    if conf.battConf == 1 then
      batcurrent = telemetry.batt1current + telemetry.batt2current
    elseif conf.battConf == 2 or conf.battConf == 3 or conf.battConf == 5 then
      batcurrent = telemetry.batt1current    
    elseif conf.battConf == 4 or conf.battConf == 6 then
      batcurrent = telemetry.batt2current 
    end
    -- aggregate value
    minmaxValues[7] = math.max(batcurrent, minmaxValues[7])
    
    -- indipendent values
    minmaxValues[8] = math.max(telemetry.batt1current,minmaxValues[8])
    minmaxValues[9] = math.max(telemetry.batt2current,minmaxValues[9])
  end
  
  -- SLOWER: this runs around 1.25Hz but not when the previous block runs
  if bgclock % 4 == 2 then
    -- reset backlight panel
    if (model.getGlobalVariable(8,0) > 0 and getTime()/100 - backlightLastTime > 5) then
      model.setGlobalVariable(8,0,0)
    end
    -- reload config
    if (model.getGlobalVariable(8,8) > 0) then
      loadConfig()
      model.setGlobalVariable(8,8,0)
    end
    -- call custom panel background functions
    if leftPanel ~= nil then
      leftPanel.background(myWidget,conf,telemetry,status,utils)
    end
    if centerPanel ~= nil then
      centerPanel.background(myWidget,conf,telemetry,status,utils)
    end
    if rightPanel ~= nil then
      rightPanel.background(myWidget,conf,telemetry,status,utils)
    end
  
    if telemetry.lat ~= nil then
      if conf.gpsFormat == 1 then
        -- DMS
        telemetry.strLat = utils.decToDMSFull(telemetry.lat)
        telemetry.strLon = utils.decToDMSFull(telemetry.lon, telemetry.lat)
      else
        -- decimal
        telemetry.strLat = string.format("%.06f", telemetry.lat)
        telemetry.strLon = string.format("%.06f", telemetry.lon)
      end
    end
  end

  bgclock = (bgclock%4)+1
  
  -- blinking support
  if (getTime() - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = getTime()
  end
  return 0
end

local function init()
  -- initialize flight timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
  -- load configuration at boot and only refresh if GV(8,8) = 1
  loadConfig(true)
  -- ok configuration loaded
  status.battsource = conf.defaultBattSource
  -- load draw library
  drawLib = utils.doLibrary(drawLibFile)
  currentModel = model.getInfo().name
  -- load custom sensors
  utils.loadCustomSensors()
  -- load battery config
  utils.loadBatteryConfigFile()
  -- ok done
  utils.pushMessage(7,"Yaapu v1.9.3b2 w. OlliW v21 MavSDK by Risto")
  utils.playSound("yaapu")
  -- fix for generalsettings lazy loading...
  unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
  unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
  unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
  unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"
end

--------------------------------------------------------------------------------
-- 4 pages
-- page 1 single battery view
-- page 2 message history
-- page 3 min max
-- page 4 dual battery view
-- page 5 map view
local options = {
  { "page", VALUE, 1, 1, 5},
}
-- shared init flag
local initDone = 0
-- This function is runned once at the creation of the widget
local function create(zone, options)
  -- this vars are widget scoped, each instance has its own set
  local vars = {
  }
  -- all local vars are shared between widget instances
  -- init() needs to be called only once!
  if initDone == 0 then
    init(zone)
    initDone = 1
  end
  --
  return { zone=zone, options=options, vars=vars }
end
-- This function allow updates when you change widgets settings
local function update(myWidget, options)
  myWidget.options = options
  -- reload menu settings
  loadConfig()
end

utils.getScreenTogglePage = function(myWidget,conf,status)
  local screenChValue = status.hideNoTelemetry == false and 0 or getValue(conf.screenToggleChannelId)
  
  if conf.screenToggleChannelId > -1 then
    if screenChValue < -600 then
      -- message history
      return 2
    end
    
    if screenChValue > 600 then
      -- map view
      return 5
    end
  end
  return myWidget.options.page
end


utils.getMessageOffset = function(myWidget,conf,status,chValue)
  if myWidget.options.page ~= 2 and status.screenTogglePage ~= 2 then
    return status.messageOffset
  end
  if conf.screenWheelChannelId > -1 then
    -- SW up
    if chValue < -600 then
      local offset = math.min(status.messageOffset + 20, math.max(0,status.messageCount - 20))
      if offset >= (status.messageCount - 20) then
        status.messageAutoScroll = true
      else
        status.messageAutoScroll = false
      end
      return offset
    end
    -- SW down
    if chValue > 600 then
      status.messageAutoScroll = false
      return math.max(0,math.max(status.messageCount - 200,status.messageOffset - 20))
    end
  end
  return status.messageOffset
end

utils.getMapZoomLevel = function(myWidget,conf,status,chValue)
  if myWidget.options.page ~= 5 and status.screenTogglePage ~= 5 then
    return status.mapZoomLevel
  end

  if conf.screenWheelChannelId > -1 then
    -- SW up (increase zoom level)
    if chValue < -600 then
      if conf.mapProvider == 1 then
        return status.mapZoomLevel > conf.mapZoomMin and status.mapZoomLevel - 1 or status.mapZoomLevel
      end
      return status.mapZoomLevel < conf.mapZoomMax and status.mapZoomLevel + 1 or status.mapZoomLevel
    end
    -- SW down (decrease zoom level)
    if chValue > 600 then
      if conf.mapProvider == 1 then
        return status.mapZoomLevel < conf.mapZoomMax and status.mapZoomLevel + 1 or status.mapZoomLevel
      end
      return status.mapZoomLevel > conf.mapZoomMin and status.mapZoomLevel - 1 or status.mapZoomLevel
    end
  end
  -- SW mid
  return status.mapZoomLevel
end

-- called when widget instance page changes
local function onChangePage(myWidget)
  if myWidget.options.page == 3 then
    -- when page 3 goes to foreground show minmax values
    status.showMinMaxValues = true
  elseif myWidget.options.page == 4 then
    -- when page 4 goes to foreground show dual battery view
    status.showDualBattery = true
  end
  -- reset HUD counters
  myWidget.vars.hudcounter = 0
end

-- Called when script is hidden @20Hz
local function background(myWidget)
  -- when page 1 goes to background run bg tasks
  if myWidget.options.page == 1 then
    -- run bg tasks
    backgroundTasks(myWidget,15)
    return
  end
  -- when page 3 goes to background hide minmax values
  if myWidget.options.page == 3 then
    status.showMinMaxValues = false
    return
  end
  -- when page 4 goes to background hide dual battery view
  if myWidget.options.page == 4 then
    status.showDualBattery = false
    return
  end
end

local slowTimer = getTime()
local fastTimer = getTime()

local function fullScreenRequired(myWidget)
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0, 0))
  lcd.drawText(myWidget.zone.x,myWidget.zone.y,"Yaapu requires",SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(myWidget.zone.x,myWidget.zone.y+16,"full screen",SMLSIZE+CUSTOM_COLOR)
end


local function loadLayout()
  -- Layout start
  if leftPanel == nil and loadCycle == 1 then
    leftPanel = utils.doLibrary(conf.leftPanelFilename)
  end

  if centerPanel == nil and loadCycle == 2 then
    centerPanel = utils.doLibrary(conf.centerPanelFilename)
  end

  if rightPanel == nil and loadCycle == 4 then
    rightPanel = utils.doLibrary(conf.rightPanelFilename)
  end

  if layout == nil and loadCycle == 6 and leftPanel ~= nil and centerPanel ~= nil and rightPanel ~= nil then
    layout = utils.doLibrary(conf.widgetLayoutFilename)
  end

  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawFilledRectangle(88,74, 304, 84, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0x10A3)
  lcd.drawFilledRectangle(90,76, 300, 80, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawText(120, 95, "loading layout...", DBLSIZE+CUSTOM_COLOR)
end

local function loadMapLayout()
  -- Layout start
  if loadCycle == 3 then
    mapLayout = utils.doLibrary("layout_map")
  end
end

local function drawInitialingMsg()
  lcd.clear(CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawFilledRectangle(88,74, 304, 84, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0x10A3)
  lcd.drawFilledRectangle(90,76, 300, 80, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawText(155, 95, "initializing...", DBLSIZE+CUSTOM_COLOR)
end

local fgclock = 0

-- Called when script is visible
local function drawFullScreen(myWidget)
  -- when page 1 goes to foreground run bg tasks
  if myWidget.options.page == 1 then
    -- run bg tasks only if we are not resetting, this prevent cpu limit kill
    if not (resetPending or resetLayoutPending) then
      backgroundTasks(myWidget,15)
    end
  end
  lcd.setColor(CUSTOM_COLOR, 0x0AB1)
  
  if not (resetPending or resetLayoutPending or loadConfigPending) then
    if myWidget.options.page == 2 or status.screenTogglePage == 2 then
      ------------------------------------
      -- Widget Page 2: MESSAGES
      ------------------------------------
      -- message history has black background
      lcd.setColor(CUSTOM_COLOR, 0x0000)
      lcd.clear(CUSTOM_COLOR)
      
      drawMessageScreen()
    elseif myWidget.options.page == 5 or status.screenTogglePage == 5 then
      ------------------------------------
      -- Widget Page 5: MAP
      ------------------------------------
      lcd.clear(CUSTOM_COLOR)
      
      if mapLayout ~= nil then
        mapLayout.draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
      else
        loadMapLayout()
      end
    else
      ------------------------------------
      -- Widget Page 1: HUD
      ------------------------------------
      lcd.clear(CUSTOM_COLOR)
      if layout ~= nil then
        layout.draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
      else
        loadLayout();
      end
    end  
  else
    -- not ready to draw yet
    drawInitialingMsg()
  end
  
  if fgclock % 2 == 1 then
    -- reset phase 2 if reset pending
    if resetLayoutPending == true then
      resetLayouts()
    elseif resetPending == true then
      reset()
    end
  end
  
  if fgclock % 4 == 0 then
    if currentPage ~= myWidget.options.page then
      currentPage = myWidget.options.page
      onChangePage(myWidget)
    end
  end
  
  if fgclock % 8 == 2 then
    -- frametype and model name
    local info = model.getInfo()
    -- model change event
    if currentModel ~= info.name then
      currentModel = info.name
      -- trigger reset
      triggerReset()
    end
  end
  fgclock = (fgclock % 8) + 1
  
  -- no telemetry/minmax outer box
  if telemetryEnabled() == false then
    -- no telemetry inner box
    if not status.hideNoTelemetry then
      drawLib.drawNoTelemetryData(status,telemetry,utils,telemetryEnabled)
    end
    utils.drawBlinkBitmap("warn",0,0)  
  else
    if status.showMinMaxValues == true then
      utils.drawBlinkBitmap("minmax",0,0)  
    end
  end
  
  drawLib.drawFailsafe(telemetry,utils);
  
  loadCycle=(loadCycle+1)%8
end

-- are we full screen? if 
local function drawScreen(myWidget)
    if myWidget.zone.h < 250 then 
      fullScreenRequired(myWidget)
      return
    end
    drawFullScreen(myWidget)
end

function refresh(myWidget)
  drawScreen(myWidget)
end

return { name="Yaapu", options=options, create=create, update=update, background=background, refresh=refresh }
