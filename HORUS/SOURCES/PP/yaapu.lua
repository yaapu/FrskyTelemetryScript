#include "includes/yaapu_inc.lua"

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
local frameType = nil

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
]]--

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

#ifdef TESTMODE
-- undefined
frameTypes[5] = ""
frameTypes[6] = ""
frameTypes[7] = ""
frameTypes[8] = ""
frameTypes[9] = ""
frameTypes[12] = ""
frameTypes[17] = ""
frameTypes[18] = ""
frameTypes[26] = ""
frameTypes[27] = ""
frameTypes[30] = ""
#endif --TESTMODE

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
-- LINK STATUS
status.noTelemetryData = 1
status.hideNoTelemetry = false
status.showDualBattery = false
status.showMinMaxValues = false
-- FLIGHTMODE
status.strFlightMode = nil
status.modelString = nil
---------------------------
-- BATTERY TABLE
---------------------------
local battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
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

local customSensors = nil

local backlightLastTime = 0
local resetPending = false

local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, ALARM_TYPE_MIN, 0, false, 0}, --MIN_ALT
    { false, 0 , false, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_ALT
    { false, 0 , false, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_DIST
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_EKF
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_BAT
    { false, 0 , true, ALARM_TYPE_TIMER, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0 }, --BATT L1
    { false, 0 , false, ALARM_TYPE_BATT_CRT, ALARM_TYPE_BATT_GRACE, false, 0 }, --BATT L2
    { false, 0 , false, ALARM_TYPE_MAX, 0, false, 0 } --MAX_HDOP
}

local transitions = {
  --{ last_value, last_changed, transition_done, delay }  
    { 0, 0, false, 30 },
}

-- SYNTH GPS DIST SUPPORT
local prevDist = 0
local lastSpeed = 0
local lastYaw = 0
local lastUpdateTotDist = 0

local  paramId,paramValue

local batLevels = {0,5,10,15,20,25,30,40,50,60,70,80,90}
-- Blinking bitmap support
local bitmaps = {}
local blinktime = getTime()
local blinkon = false

local minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

#ifdef LOGTELEMETRY
local logfile
local logfilename
#endif --LOGTELEMETRY

#ifdef TESTMODE
-- TEST MODE
local thrOut = 0
#endif --TESTMODE
-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
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
  battConf = BATTCONF_PARALLEL, -- 1=parallel,2=other
  cell1Count = 0,
  cell2Count = 0,
  enableBattPercByVoltage = false,
  rangeMax=0,
  enableSynthVSpeed=false,
  horSpeedMultiplier=1,
  vertSpeedMultiplier=1,
  horSpeedLabel = "m/s",
  vertSpeedLabel = "m/s",
  maxHdopAlert = 2,
  enablePX4Modes = false,
  centerPanel = 1,
  rightPanel = 1,
  leftPanel = 1,
  widgetLayout = 1,
  widgetLayoutFilename = nil,
  centerPanelFilename = nil,
  rightPanelFilename = nil,
  leftPanelFilename = nil,
  screenToggleChannelId = nil,
}

#ifdef FNV_HASH
-------------------------
-- message hash support
-------------------------
local shortHashes = { 
  -- 16 bytes hashes
  {554623408},      -- "554623408.wav", "Takeoff complete"
  {3025044912},     -- "3025044912.wav", "SmartRTL deactiv"
  {3956583920},     -- "3956583920.wav", "EKF2 IMU0 is usi"
  {1309405592},     -- "1309405592.wav", "EKF3 IMU0 is usi"
  {4091124880,true}, -- "4091124880.wav", "Reached command "
  {3311875476,true}, -- "3311875476.wav", "Reached waypoint"
  {1997782032,true}, -- "1997782032.wav", "Passed waypoint "
}

local shortHash = nil
local parseShortHash = false
local hashByteIndex = 0
local hash = 2166136261
#endif --FNV_HASH

local loadCycle = 0

utils.doLibrary = function(filename)
#ifdef LOADSCRIPT
  local f = assert(loadScript(libBasePath..filename..".lua"))
#else
#ifdef LOAD_LUA
  local f = assert(loadfile(libBasePath..filename..".lua"))
#else
  local f = assert(loadfile(libBasePath..filename..".luac"))
#endif
#endif
  collectgarbage()
  collectgarbage()
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
  maxmem = 0
end  
  
local function loadConfig()
  -- load menu library
  menuLib = loadMenuLib()
  menuLib.loadConfig(conf)
#ifdef COMPILE
  menuLib.compileLayouts()
#endif  
  -- ok configuration loaded
  status.battsource = conf.defaultBattSource
  -- unload libraries
  utils.clearTable(menuLib)
  utils.clearTable(layout)
  layout = nil
  utils.clearTable(centerPanel)
  centerPanel = nil
  utils.clearTable(rightPanel)
  rightPanel = nil
  utils.clearTable(leftPanel)
  leftPanel = nil
  collectgarbage()
  collectgarbage()
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
  model.setGlobalVariable(BACKLIGHT_GV,0,1)
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

#ifdef LOGTELEMETRY
local function getLogFilename(date)
  local info = model.getInfo()
  local modelName = string.lower(string.gsub(info.name, "[%c%p%s%z]", ""))
  return string.format("/LOGS/%s-%04d%02d%02d_%02d%02d%02d.plog",modelName,date.year,date.mon,date.day,date.hour,date.min,date.sec)
end
#endif --LOGTELEMETRY

#define MAX_MESSAGES 20

local function formatMessage(severity,msg)
  local clippedMsg = msg
  
  if #msg > 50 then
    clippedMsg = string.sub(msg,1,50)
    msg = nil
    collectgarbage()
    collectgarbage()
  end
  
  if status.lastMessageCount > 1 then
    return string.format("%02d:%s (x%d) %s", status.messageCount, mavSeverity[severity], status.lastMessageCount, clippedMsg)
  else
    return string.format("%02d:%s %s", status.messageCount, mavSeverity[severity], clippedMsg)
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
  if status.messages[(status.messageCount-1) % MAX_MESSAGES] == nil then
    status.messages[(status.messageCount-1) % MAX_MESSAGES] = {}
  end
  status.messages[(status.messageCount-1) % MAX_MESSAGES][1] = formatMessage(severity,msg)
  status.messages[(status.messageCount-1) % MAX_MESSAGES][2] = severity
  
  status.lastMessage = msg
  status.lastMessageSeverity = severity
  -- Collect Garbage
  collectgarbage()
  collectgarbage()
end

#ifdef HAVERSINE
utils.haversine = function(lat1, lon1, lat2, lon2)
    lat1 = lat1 * math.pi / 180
    lon1 = lon1 * math.pi / 180
    lat2 = lat2 * math.pi / 180
    lon2 = lon2 * math.pi / 180
    
    lat_dist = lat2-lat1
    lon_dist = lon2-lon1
    lat_hsin = math.pow(math.sin(lat_dist/2),2)
    lon_hsin = math.pow(math.sin(lon_dist/2),2)

    a = lat_hsin + math.cos(lat1) * math.cos(lat2) * lon_hsin
    return 2 * 6372.8 * math.asin(math.sqrt(a)) * 1000
end
#endif --HAVERSINE

utils.getHomeFromAngleAndDistance = function(telemetry)
--[[
  la1,lo1 coordinates of first point
  d be distance (m),
  R as radius of Earth (m),
  Ad be the angular distance i.e d/R and
  θ be the bearing in deg
  
  la2 =  asin(sin la1 * cos Ad  + cos la1 * sin Ad * cos θ), and
  lo2 = lo1 + atan2(sin θ * sin Ad * cos la1 , cos Ad – sin la1 * sin la2)
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
  return "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "").."_sensors.lua")
end

--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------
#define SENSOR_LABEL 1
#define SENSOR_NAME 2
#define SENSOR_PREC 3
#define SENSOR_UNIT 4
#define SENSOR_MULT 5
#define SENSOR_MAX 6
#define SENSOR_FONT 7
#define SENSOR_WARN 8
#define SENSOR_CRIT 9

utils.loadCustomSensors = function()
  local success, sensorScript = pcall(loadScript,getSensorsConfigFilename())
  if success then
    if sensorScript == nil then
      customSensors = nil
      return
    end
    collectgarbage()
    customSensors = sensorScript()
    -- handle nil values for warning and critical levels
    for i=1,6
    do
      if customSensors.sensors[i] ~= nil then 
        local sign = customSensors.sensors[i][SENSOR_MAX] == "+" and 1 or -1
        if customSensors.sensors[i][SENSOR_CRIT] == nil then
          customSensors.sensors[i][SENSOR_CRIT] = math.huge*sign
        end
        if customSensors.sensors[i][SENSOR_WARN] == nil then
          customSensors.sensors[i][SENSOR_WARN] = math.huge*sign
        end
      end
    end
    collectgarbage()
    collectgarbage()
  else
    customSensors = nil
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

#ifdef TESTMODE
-----------------------------------------------------
-- TEST MODE
-----------------------------------------------------
local function symTimer()
  thrOut = getValue("thr")
  if (thrOut > 200 ) then
    telemetry.landComplete = 1
  else
    telemetry.landComplete = 0
  end
end

local function symGPS()
  thrOut = getValue("thr")
  if thrOut > 500 then
    telemetry.numSats = 15
    telemetry.gpsStatus = 4
    telemetry.gpsHdopC = 6
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 0
    status.noTelemetryData = 0
    telemetry.statusArmed = 1
  elseif thrOut > 200 then
    telemetry.numSats = 12
    telemetry.gpsStatus = 3
    telemetry.gpsHdopC = 25
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 0
    status.noTelemetryData = 0
    telemetry.statusArmed = 1
  elseif thrOut < 200 and thrOut > 0  then
    status.vnumSats = 13
    telemetry.gpsStatus = 5
    telemetry.gpsHdopC = 1000
    telemetry.ekfFailsafe = 1
    telemetry.battFailsafe = 0
    status.noTelemetryData = 0
    telemetry.statusArmed = 1
  elseif thrOut > -500  then
    telemetry.numSats = 6
    telemetry.gpsStatus = 1
    telemetry.gpsHdopC = 120
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 1
    status.noTelemetryData = 0
    telemetry.statusArmed = 0
  else
    telemetry.numSats = 0
    telemetry.gpsStatus = 0
    telemetry.gpsHdopC = 100
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 0
    status.noTelemetryData = 1
    telemetry.statusArmed = 0
  end
end

local function symFrameType()
  local ch11 = getValue("ch11")
  if ch11 < -300 then
    telemetry.frameType = 2
  elseif ch11 < 300 then
    telemetry.frameType = 1
  else
    telemetry.frameType = 10
  end
end

local function symBatt()
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
#ifdef DEMO
    if telemetry.battFailsafe == 1 then
      minmaxValues[MIN_BATT1_FC] = CELLCOUNT * 3.40 * 10
      minmaxValues[MIN_BATT2_FC] = CELLCOUNT * 3.43 * 10
      minmaxValues[MAX_CURR] = 341 + 335
      minmaxValues[MAX_CURR1] = 341
      minmaxValues[MAX_CURR2] = 335
      minmaxValues[MAX_POWER] = (CELLCOUNT * 3.43)*(34.1 + 33.5)
      -- battery voltage
      telemetry.batt1current = 235
      telemetry.batt1volt = CELLCOUNT * 3.43 * 10
      telemetry.batt1Capacity = 5200
      telemetry.batt1mah = 4400
#ifdef BATT2TEST
      telemetry.batt2current = 238
      telemetry.batt2volt = CELLCOUNT  * 3.44 * 10
      telemetry.batt2Capacity = 5200
      telemetry.batt2mah = 4500
#endif --BATT2TEST
    else
      minmaxValues[MIN_BATT1_FC] = CELLCOUNT * 3.75 * 10
      minmaxValues[MIN_BATT2_FC] = CELLCOUNT * 3.77 * 10
      minmaxValues[MAX_CURR] = 341+335
      minmaxValues[MAX_CURR1] = 341
      minmaxValues[MAX_CURR2] = 335
      minmaxValues[MAX_POWER] = (CELLCOUNT * 3.89)*(34.1+33.5)
      -- battery voltage
      telemetry.batt1current = 235
      telemetry.batt1volt = CELLCOUNT * 3.87 * 10
      telemetry.batt1Capacity = 5200
      telemetry.batt1mah = 2800
#ifdef BATT2TEST
      telemetry.batt2current = 238
      telemetry.batt2volt = CELLCOUNT * 3.89 * 10
      telemetry.batt2Capacity = 5200
      telemetry.batt2mah = 2700
#endif --BATT2TEST
    end
#else --DEMO
    -- battery voltage
    telemetry.batt1current = 100 +  ((thrOut)*0.01 * 30)
    telemetry.batt1volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    telemetry.batt1Capacity = 5200
    telemetry.batt1mah = math.abs(1000*(thrOut/200))
#ifdef BATT2TEST
    telemetry.batt2current = 100 +  ((thrOut)*0.01 * 30)
    telemetry.batt2volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    telemetry.batt2Capacity = 5200
    telemetry.batt2mah = math.abs(1000*(thrOut/200))
#endif --BATT2TEST
#endif --DEMO
  -- flightmode
#ifdef DEMO
    telemetry.flightMode = 1
    minmaxValues[MAX_GPSALT] = 270*0.1
    minmaxValues[MAX_DIST] = 130
    telemetry.gpsAlt = 200
    telemetry.homeDist = 95
#else --DEMO
    telemetry.flightMode = math.floor(20 * math.abs(thrOut)*0.001)
    telemetry.gpsAlt = math.floor(10 * math.abs(thrOut)*0.1)
    telemetry.homeDist = math.floor(10 * math.abs(thrOut)*0.1)
#endif --DEMO
  else
    telemetry.batt1mah = 0
  end
end

-- simulates attitude by using channel 1 for roll, channel 2 for pitch and channel 4 for yaw
local function symAttitude()
#ifdef DEMO
  telemetry.roll = 14
  telemetry.pitch = -0.8
  telemetry.yaw = 33
#else --DEMO
  local rollCh = 0
  local pitchCh = 0
  local yawCh = 0
  -- roll [-1024,1024] ==> [-180,180]
  rollCh = getValue("ch1") * 0.088 * 2
  -- clipping
  rollCH = rollCh > 0 and math.min(rollCh,180) or math.max(rollCh,-180)
  -- pitch [1024,-1024] ==> [-90,90]
  pitchCh = getValue("ch2") * 0.088 -- -90<-->90)
  -- clipping
  pitchCh = pitchCh > 0 and math.min(pitchCh,90) or math.max(pitchCh,-90)
  -- yaw [-1024,1024] ==> [0,360]
  yawCh = getValue("ch10")
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  telemetry.roll = rollCh
  telemetry.pitch = pitchCh
  telemetry.yaw = yawCh
#endif --DEMO
end

local function symHome()
  local yawCh = 0
  local S2Ch = 0
  -- home angle in deg [0-360]
  S2Ch = getValue("ch12")
  yawCh = getValue("ch4")
#ifdef DEMO
  minmaxValues[MINMAX_ALT] = 45
  minmaxValues[MAX_VSPEED] = 4
  minmaxValues[MAX_HSPEED] = 77
  telemetry.homeAlt = 24
  telemetry.vSpeed = 24
  telemetry.hSpeed = 34
#else --DEMO
  telemetry.homeAlt = yawCh * 0.1
  telemetry.range = 10 * yawCh * 0.1
  telemetry.vSpeed = yawCh * 0.1
  telemetry.hSpeed = telemetry.vSpeed
  telemetry.throttle = math.abs(yawCh/10)
#endif --DEMO
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  telemetry.yaw = yawCh
  if ( S2Ch >= 0) then
    S2Ch = S2Ch * 0.175
  else
    S2Ch = 360 + (S2Ch * 0.175)
  end
  if (thrOut > 0 ) then
    telemetry.homeAngle = S2Ch
  else
    telemetry.homeAngle = -1
  end
  telemetry.wpNumber = math.min(telemetry.homeDist,1023)
  telemetry.wpDistance = telemetry.homeDist
  telemetry.totalDist = telemetry.homeDist * 100
  telemetry.wpBearing = (telemetry.yaw / 45) % 8
end

local function symMode()
  symGPS()
  symAttitude()
  symTimer()
  symHome()
  symBatt()
  symFrameType()
end
#endif --TESTMODE

-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
#ifdef LOGTELEMETRY
local lastAttiLogTime = 0
#endif --LOGTELEMETRY

local function processTelemetry(DATA_ID,VALUE)
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
    telemetry.imuTemp = bit32.extract(VALUE,26,6) + 19 -- C°
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
#ifdef BATT2TEST
    telemetry.batt2volt = bit32.extract(VALUE,0,9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell2Count == 12 and telemetry.batt2volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt2volt = 512 + telemetry.batt2volt
    end
    telemetry.batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
    telemetry.batt2mah = bit32.extract(VALUE,17,15)
#endif --BATT2TEST
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
          collectgarbage()
          collectgarbage()
#ifdef FNV_HASH
          hash = bit32.bxor(hash, c)
          hash = (hash * 16777619) % 2^32
          hashByteIndex = hashByteIndex+1
          -- check if this hash matches any 16bytes prefix hash
          if hashByteIndex == 16 then
            for i=1,#shortHashes
            do
              if hash == shortHashes[i][1] then
                shortHash = hash
                -- check if needs parsing
                parseShortHash = shortHashes[i][2] == nil and false or true
                break;
              end
            end
          end
#endif --FNV_HASH          
        else
          msgEnd = true;
          break;
        end
      end
      if msgEnd then
        local severity = (bit32.extract(VALUE,7,1) * 1) + (bit32.extract(VALUE,15,1) * 2) + (bit32.extract(VALUE,23,1) * 4)
#ifdef HASHDEBUG
        utils.pushMessage( severity, (shortHash == nil and "H:" or "SH:") .. tostring(shortHash == nil and hash or shortHash) .. " "..status.msgBuffer)
#else
        utils.pushMessage( severity, status.msgBuffer)
#endif
#ifdef FNV_HASH
        -- try to play the hash sound file without checking
        -- for existence, OpenTX will gracefully ignore it :-)
        utils.playSound(tostring(shortHash == nil and hash or shortHash),true)
        -- if required parse parameter and play it!
        if parseShortHash then
          local param = string.match(status.msgBuffer, ".*#(%d+).*")
          collectgarbage()
          if param ~= nil then
            playNumber(tonumber(param),0)
            collectgarbage()
          end
        end
        -- reset hash for next string
        parseShortHash = false
        shortHash = nil
        hash = 2166136261
        hashByteIndex = 0
#endif --FNV_HASH
        status.msgBuffer = nil
        -- recover memory
        collectgarbage()
        collectgarbage()
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
#ifdef BATT2TEST
      telemetry.batt2Capacity = paramValue
#endif --BATT2TEST
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

#ifdef TESTMODE
local function telemetryEnabled(status)
  return true
end
#else --TESTMODE
local function telemetryEnabled()
  if getRSSI() == 0 then
    status.noTelemetryData = 1
  end
  return status.noTelemetryData == 0
end
#endif --TESTMODE

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

local function calcCellCount()
  -- cellcount override from menu
  local c1 = 0
  local c2 = 0
  
  if conf.cell1Count ~= nil and conf.cell1Count > 0 then
    c1 = conf.cell1Count
  elseif status.batt1sources.vs == true and status.cell1count > 1 then
    c1 = status.cell1count
  else
    c1 = math.floor( ((status.cell1maxFC*0.1) / CELLFULL) + 1)
  end
  
  if conf.cell2Count ~= nil and conf.cell2Count > 0 then
    c2 = conf.cell2Count
  elseif status.batt2sources.vs == true and status.cell2count > 1 then
    c2 = status.cell2count
  else
    c2 = math.floor(((status.cell2maxFC*0.1)/CELLFULL) + 1)
  end
  
  return c1,c2
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
  if cell > CELLFULL*2 or cellFC > CELLFULL*2 then
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

#ifdef FLVSS2TEST
  local cellResult = battIdx == 1 and getValue("Cels") or getValue("Cels")
#else
  local cellResult = battIdx == 1 and getValue("Cels") or getValue("Cel2")
#endif  
  
  if type(cellResult) == "table" then
    cellMin = CELLFULL
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
  minmaxValues[MIN_BATT1_FC] = calcMinValue(status.cell1sumFC,minmaxValues[MIN_BATT1_FC])
  minmaxValues[MIN_BATT2_FC] = calcMinValue(status.cell2sumFC,minmaxValues[MIN_BATT2_FC])
  -- cell flvss
  minmaxValues[MIN_CELL1_VS] = calcMinValue(status.cell1min,minmaxValues[MIN_CELL1_VS])
  minmaxValues[MIN_CELL2_VS] = calcMinValue(status.cell2min,minmaxValues[MIN_CELL2_VS])
  -- batt flvss
  minmaxValues[MIN_BATT1_VS] = calcMinValue(status.cell1sum,minmaxValues[MIN_BATT1_VS])
  minmaxValues[MIN_BATT2_VS] = calcMinValue(status.cell2sum,minmaxValues[MIN_BATT2_VS])
  --
  ------------------------------------------
  -- table to pass battery info to panes
  -- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
  -- value = offset + [0 aggregate|1 for batt 1| 2 for batt2]
  -- batt2 = 4 + 2 = 6
  ------------------------------------------
  -- Note: these can be calculated. not necessary to track them as min/max 
  -- cell1minFC = cell1sumFC/calcCellCount()
  -- cell2minFC = cell2sumFC/calcCellCount()
  -- cell1minA2 = cell1sumA2/calcCellCount()
  --
  local count1,count2 = calcCellCount()
  
  battery[BATT_CELL+1] = getMinVoltageBySource(status.battsource, status.cell1min, status.cell1sumFC/count1, 1)*100 --cel1m
  battery[BATT_CELL+2] = getMinVoltageBySource(status.battsource, status.cell2min, status.cell2sumFC/count2, 2)*100 --cel2m
  battery[BATT_CELL] = (conf.battConf ==  BATTCONF_OTHER and battery[2] or getNonZeroMin(battery[2], battery[3]) )

  battery[BATT_VOLT+1] = getMinVoltageBySource(status.battsource, status.cell1sum, status.cell1sumFC, 1)*10 --batt1
  battery[BATT_VOLT+2] = getMinVoltageBySource(status.battsource, status.cell2sum, status.cell2sumFC, 2)*10 --batt2
  battery[BATT_VOLT] = (conf.battConf ==  BATTCONF_OTHER and battery[5] or (conf.battConf == BATTCONF_SERIAL and battery[5]+battery[6] or getNonZeroMin(battery[5],battery[6]))) 

  battery[BATT_CURR] = utils.getMaxValue((conf.battConf ==  BATTCONF_OTHER and telemetry.batt1current or telemetry.batt1current + telemetry.batt2current),MAX_CURR)
  battery[BATT_CURR+1] = utils.getMaxValue(telemetry.batt1current,MAX_CURR1) --curr1
  battery[BATT_CURR+2] = utils.getMaxValue(telemetry.batt2current,MAX_CURR2) --curr2

  battery[BATT_MAH] = (conf.battConf ==  BATTCONF_OTHER and telemetry.batt1mah or telemetry.batt1mah + telemetry.batt2mah)
  battery[BATT_MAH+1] = telemetry.batt1mah --mah1
  battery[BATT_MAH+2] = telemetry.batt2mah --mah2
  
  battery[BATT_CAP] = (conf.battConf ==  BATTCONF_PARALLEL and getBatt1Capacity() + getBatt2Capacity() or getBatt1Capacity())
  battery[BATT_CAP+1] = getBatt1Capacity() --cap1
  battery[BATT_CAP+2] = getBatt2Capacity() --cap2
  
  if status.showDualBattery == true and conf.battConf ==  BATTCONF_PARALLEL then
    -- dual parallel battery: do I have also dual current monitor?
    if battery[BATT_CURR+1] > 0 and battery[BATT_CURR+2] == 0  then
      -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
      battery[BATT_CURR+1] = battery[BATT_CURR+1]/2 --curr1
      battery[BATT_CURR+2] = battery[BATT_CURR+1]   --curr2
      --
      battery[BATT_MAH+1]  = battery[BATT_MAH+1]/2  --mah1
      battery[BATT_MAH+2]  = battery[BATT_MAH+1]    --mah2
      --
      battery[BATT_CAP+1] = battery[BATT_CAP+1]/2   --cap1
      battery[BATT_CAP+2] = battery[BATT_CAP+1]     --cap2
    end
  end
end

local function checkLandingStatus()
  if ( status.timerRunning == 0 and telemetry.landComplete == 1 and status.lastTimerStart == 0) then
    startTimer()
  end
  if (status.timerRunning == 1 and telemetry.landComplete == 0 and status.lastTimerStart ~= 0) then
    stopTimer()
    -- play landing complete anly if motorts are armed
    if telemetry.statusArmed == 1 then
      utils.playSound("landing")
    end
  end
  status.timerRunning = telemetry.landComplete
end

local resetLib = {}
#ifdef LOAD_LUA
local resetFile = libBasePath.."reset.lua"
#else --LOAD_LUA
local resetFile = libBasePath.."reset.luac"
#endif --LOAD_LUA

local function reset()
  -- ERRORE reset da kill CPU limit!!!!!!!!
  -- 2 stage reset
  if resetPending == false then
    -- initialize status
    if resetLib.resetWidget == nil then
      resetLib = dofile(resetFile)
      collectgarbage()
      collectgarbage()
    end
    -- reset frame
    utils.clearTable(frame.frameTypes)
    -- reset widget pages
    currentPage = 0
    
    minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    
    status.showMinMaxValues = false
    status.showDualBattery = false
    status.strFlightMode = nil
    status.modelString = nil
    
    frame = {}
    -- reset all
    resetLib.resetTelemetry(status,telemetry,battery,alarms,utils)
    -- release resources
    utils.clearTable(resetLib)
    -- force load model config
    model.setGlobalVariable(CONF_GV,CONF_FM_GV,1)
    collectgarbage()
    collectgarbage()
    utils.pushMessage(6,"telemetry reset done!")
    resetPending = true
  else
    -- custom sensors
    utils.clearTable(customSensors)
    customSensors = nil
    utils.loadCustomSensors()
    -- done
    utils.playSound("yaapu")
    collectgarbage()
    collectgarbage()
    resetPending = false
  end
end

local function calcFlightTime()
  -- update local variable with timer 3 value
  if ( model.getTimer(2).value < status.flightTime and telemetry.statusArmed == 0) then
    reset()
  end
  if (model.getTimer(2).value < status.flightTime and telemetry.statusArmed == 1) then
    model.setTimer(2,{value=status.flightTime})
    utils.pushMessage(4,"Reset ignored while armed")
  end
  status.flightTime = model.getTimer(2).value
end

local function setSensorValues()
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

  setTelemetryValue(Fuel_ID, Fuel_SUBID, Fuel_INSTANCE, perc, 13 , Fuel_PRECISION , Fuel_NAME)
  setTelemetryValue(VFAS_ID, VFAS_SUBID, VFAS_INSTANCE, getNonZeroMin(telemetry.batt1volt,telemetry.batt2volt)*10, 1 , VFAS_PRECISION , VFAS_NAME)
  setTelemetryValue(CURR_ID, CURR_SUBID, CURR_INSTANCE, telemetry.batt1current+telemetry.batt2current, 2 , CURR_PRECISION , CURR_NAME)
  setTelemetryValue(VSpd_ID, VSpd_SUBID, VSpd_INSTANCE, telemetry.vSpeed, 5 , VSpd_PRECISION , VSpd_NAME)
  setTelemetryValue(GSpd_ID, GSpd_SUBID, GSpd_INSTANCE, telemetry.hSpeed*0.1, 5 , GSpd_PRECISION , GSpd_NAME)
  setTelemetryValue(Alt_ID, Alt_SUBID, Alt_INSTANCE, telemetry.homeAlt*10, 9 , Alt_PRECISION , Alt_NAME)
  setTelemetryValue(GAlt_ID, GAlt_SUBID, GAlt_INSTANCE, math.floor(telemetry.gpsAlt*0.1), 9 , GAlt_PRECISION , GAlt_NAME)
  setTelemetryValue(Hdg_ID, Hdg_SUBID, Hdg_INSTANCE, math.floor(telemetry.yaw), 20 , Hdg_PRECISION , Hdg_NAME)
  setTelemetryValue(IMUTmp_ID, IMUTmp_SUBID, IMUTmp_INSTANCE, telemetry.imuTemp, 11 , IMUTmp_PRECISION , IMUTmp_NAME)
  setTelemetryValue(ARM_ID, ARM_SUBID, ARM_INSTANCE, telemetry.statusArmed*100, 0 , ARM_PRECISION , ARM_NAME)
end

utils.drawTopBar = function()
  lcd.setColor(CUSTOM_COLOR,COLOR_BARS)  
  -- black bar
  lcd.drawFilledRectangle(0,0, LCD_W, 18, CUSTOM_COLOR)
  -- frametype and model name
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  if status.modelString ~= nil then
    lcd.drawText(2, RSSI_Y, status.modelString, CUSTOM_COLOR)
  end
  -- flight time
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, RSSI_Y+4, strtime, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- RSSI
  if telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR,COLOR_RED)    
    lcd.drawText(RSSI_X-23, RSSI_Y, "NO TELEM", RSSI_FLAGS+CUSTOM_COLOR)
  else
    lcd.drawText(RSSI_X, RSSI_Y, "RS:", RSSI_FLAGS+CUSTOM_COLOR)
#ifdef DEMO
    lcd.drawText(RSSI_X + 30,RSSI_Y, 87, RSSI_FLAGS+CUSTOM_COLOR)  
#else --DEMO
    lcd.drawText(RSSI_X + 30,RSSI_Y, getRSSI(), RSSI_FLAGS+CUSTOM_COLOR)  
#endif --DEMO
  end
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)    
  -- tx voltage
  local vtx = string.format("Tx:%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(TXVOLTAGE_X,TXVOLTAGE_Y, vtx, TXVOLTAGE_FLAGS+CUSTOM_COLOR)
end

local function drawMessageScreen()
  for i=0,#status.messages do
    if  status.messages[(status.messageCount + i) % (#status.messages+1)][2] == 4 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255,0))
    elseif status.messages[(status.messageCount + i) % (#status.messages+1)][2] < 4 then
      --lcd.setColor(CUSTOM_COLOR,COLOR_RED)
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,70,0))  
    else
      lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    end
    lcd.drawText(0,2+13*i, status.messages[(status.messageCount + i) % (#status.messages+1)][1],SMLSIZE+CUSTOM_COLOR)
  end
  
  lcd.setColor(CUSTOM_COLOR,COLOR_BG)
  lcd.drawFilledRectangle(405,0,75,272,CUSTOM_COLOR)
  
  #define TXT_X 410
  #define TXT_ALIGN 0
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  -- print info on the right
  -- CELL
  if battery[BATT_CELL] * 0.01 < 10 then
    lcd.drawNumber(TXT_X, 0, battery[BATT_CELL] + 0.5, PREC2+TXT_ALIGN+MIDSIZE+CUSTOM_COLOR)
  else
    lcd.drawNumber(TXT_X, 0, (battery[BATT_CELL] + 0.5)*0.1, PREC1+TXT_ALIGN+MIDSIZE+CUSTOM_COLOR)
  end
  lcd.drawText(TXT_X+50, 1, status.battsource, SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(TXT_X+50, 11, "V", SMLSIZE+CUSTOM_COLOR)
  -- ALT
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(TXT_X, 25, "Alt("..UNIT_ALT_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  lcd.drawNumber(TXT_X,37,telemetry.homeAlt*UNIT_ALT_SCALE,MIDSIZE+CUSTOM_COLOR+TXT_ALIGN)
  -- SPEED
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(TXT_X, 60, "Spd("..UNIT_HSPEED_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  lcd.drawNumber(TXT_X,72,telemetry.hSpeed*0.1* UNIT_HSPEED_SCALE,MIDSIZE+CUSTOM_COLOR+TXT_ALIGN)
  -- VSPEED
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(TXT_X, 95, "VSI("..UNIT_VSPEED_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  lcd.drawNumber(TXT_X,107, telemetry.vSpeed*0.1*UNIT_VSPEED_SCALE, MIDSIZE+CUSTOM_COLOR+TXT_ALIGN)
  -- DIST
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(TXT_X, 130, "Dist("..UNIT_DIST_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  lcd.drawNumber(TXT_X, 142, telemetry.homeDist*UNIT_DIST_SCALE, MIDSIZE+TXT_ALIGN+CUSTOM_COLOR)
  -- HDG
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(TXT_X, 165, "Heading", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  lcd.drawNumber(TXT_X, 177, telemetry.yaw, MIDSIZE+TXT_ALIGN+CUSTOM_COLOR)
  -- HOMEDIR
  lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
  drawLib.drawRArrow(442,235,22,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
end

#ifdef COMPASS_ROSE
#define COMPASS_CHARSIZE 10
#define COMPASS_RADIUS 30
#define COMPASS_LINE 5

local compassPoints = {}

compassPoints[0] = "N"
compassPoints[1] = nil
compassPoints[2] = "E"
compassPoints[3] = nil
compassPoints[4] = "S"
compassPoints[5] = nil
compassPoints[6] = "W"
compassPoints[7] = nil

local function drawCompassRose()
  local hw = math.floor(YAW_WIDTH/2)
  local yawRounded = roundTo(telemetry.yaw,1)
  local homeRounded = roundTo(telemetry.homeAngle,1)
  local minY = TOPBAR_Y + TOPBAR_HEIGHT - 1
  local Hdy = math.sin(math.rad(270+homeRounded-yawRounded))*COMPASS_RADIUS
  local Hdx = math.cos(math.rad(270+homeRounded-yawRounded))*COMPASS_RADIUS
  for ang=0,7
  do
    local Rdy = math.sin(math.rad(45*ang+270-yawRounded))*COMPASS_RADIUS
    local Rdx = math.cos(math.rad(45*ang+270-yawRounded))*COMPASS_RADIUS
    local Ldy = math.sin(math.rad(45*ang+270-yawRounded))*(COMPASS_RADIUS-COMPASS_LINE)
    local Ldx = math.cos(math.rad(45*ang+270-yawRounded))*(COMPASS_RADIUS-COMPASS_LINE)
    if compassPoints[ang] == nil then
      lcd.drawLine(HOMEDIR_X+Ldx,HOMEDIR_Y+Ldy,HOMEDIR_X+Rdx,HOMEDIR_Y+Rdy,SOLID,2)
    else
      lcd.drawText(HOMEDIR_X+Rdx-(COMPASS_CHARSIZE/2),HOMEDIR_Y+Rdy-(COMPASS_CHARSIZE/2),compassPoints[ang],0)
    end
  end
  drawLib.drawHomeIcon(HOMEDIR_X+Hdx-(COMPASS_CHARSIZE/2),HOMEDIR_Y+Hdy-(COMPASS_CHARSIZE/2),utils)
  --
  local xx = 0
  if ( telemetry.yaw < 10) then
    xx = 1
  elseif (telemetry.yaw < 100) then
    xx = -8
  else
    xx = -12
  end
  lcd.drawNumber(HOMEDIR_X + xx - 5, HOMEDIR_Y - COMPASS_RADIUS - 24, telemetry.yaw, INVERS)
end
#endif
---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
utils.checkAlarm = function(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms except battery alerts
  if status.timerRunning == 0 then
    if alarms[idx][ALARM_TYPE] == ALARM_TYPE_MIN then
      alarms[idx] = { false, 0, false, ALARM_TYPE_MIN, 0, false, 0} 
    elseif alarms[idx][ALARM_TYPE] == ALARM_TYPE_MAX then
      alarms[idx] = { false, 0, true, ALARM_TYPE_MAX, 0, false, 0}
    elseif  alarms[idx][ALARM_TYPE] == ALARM_TYPE_TIMER then
      alarms[idx] = { false, 0, true, ALARM_TYPE_TIMER, 0, false, 0}
    elseif  alarms[idx][ALARM_TYPE] == ALARM_TYPE_BATT then
      alarms[idx] = { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0}
    elseif  alarms[idx][ALARM_TYPE] == ALARM_TYPE_BATT_CRT then
      alarms[idx] = { false, 0 , false, ALARM_TYPE_BATT_CRT, ALARM_TYPE_BATT_GRACE, false, 0}
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level  
  if alarms[idx][ALARM_ARMED] == false and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][ALARM_ARMED] = true
  end

  if alarms[idx][ALARM_TYPE] == ALARM_TYPE_TIMER then
    if status.flightTime > 0 and math.floor(status.flightTime) %  delay == 0 then
      if alarms[idx][ALARM_NOTIFIED] == false then 
        alarms[idx][ALARM_NOTIFIED] = true
        utils.playSound(sound)
        playDuration(status.flightTime,(status.flightTime > 3600 and 1 or 0)) -- minutes,seconds
      end
    else
        alarms[idx][ALARM_NOTIFIED] = false
    end
  else
    if alarms[idx][ALARM_ARMED] == true then
      if level > 0 and sign*value > sign*level then
        -- value is outside level 
        if alarms[idx][ALARM_START] == 0 then
          -- first time outside level after last reset
          alarms[idx][ALARM_START] = status.flightTime
          -- status: START
        end
      else
        -- value back to normal ==> reset
        alarms[idx][ALARM_START] = 0
        alarms[idx][ALARM_NOTIFIED] = false
        alarms[idx][ALARM_READY] = false
        -- status: RESET
      end
      if alarms[idx][ALARM_START] > 0 and (status.flightTime ~= alarms[idx][ALARM_START]) and (status.flightTime - alarms[idx][ALARM_START]) >= alarms[idx][ALARM_GRACE] then
        -- enough time has passed after START
        alarms[idx][ALARM_READY] = true
        -- status: READY
      end

      if alarms[idx][ALARM_READY] == true and alarms[idx][ALARM_NOTIFIED] == false then 
        utils.playSound(sound)
        alarms[idx][ALARM_NOTIFIED] = true
        alarms[idx][ALARM_LAST_ALARM] = status.flightTime
        -- status: BEEP
      end
      -- all but battery alarms
      if alarms[idx][ALARM_TYPE] ~= ALARM_TYPE_BATT then
        if alarms[idx][ALARM_READY] == true and status.flightTime ~= alarms[idx][ALARM_LAST_ALARM] and (status.flightTime - alarms[idx][ALARM_LAST_ALARM]) %  delay == 0 then
          alarms[idx][ALARM_NOTIFIED] = false
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
    collectgarbage()
    collectgarbage()
    maxmem = 0
  end
end
--[[
local function loadFlightModes()
  if frame.flightModes then
    return
  end

  if telemetry.frameType ~= -1 then
#ifdef LOAD_LUA
    if frameTypes[telemetry.frameType] == "c" then
      frame = dofile(libBasePath..(conf.enablePX4Modes and "copter_px4.lua" or "copter.lua"))
    elseif frameTypes[telemetry.frameType] == "p" then
      frame = dofile(libBasePath..(conf.enablePX4Modes and "plane_px4.lua" or "plane.lua"))
    elseif frameTypes[telemetry.frameType] == "r" then
      frame = dofile(libBasePath.."rover.lua")
    end
#else
    if frameTypes[telemetry.frameType] == "c" then
      frame = dofile(libBasePath..(conf.enablePX4Modes and "copter_px4.luac" or "copter.luac"))
    elseif frameTypes[telemetry.frameType] == "p" then
      frame = dofile(libBasePath..(conf.enablePX4Modes and "plane_px4.luac" or "plane.luac"))
    elseif frameTypes[telemetry.frameType] == "r" then
      frame = dofile(libBasePath.."rover.luac")
    end
#endif
    collectgarbage()
    maxmem = 0
  end
end
--]]

---------------------------------
-- This function checks state transitions and only returns true if a specific delay has passed
-- new transitions reset the delay timer
---------------------------------
local function checkTransition(idx,value)
  if value ~= transitions[idx][TRANSITION_LASTVALUE] then
    -- value has changed 
    transitions[idx][TRANSITION_LASTVALUE] = value
    transitions[idx][TRANSITION_LASTCHANGED] = getTime()
    transitions[idx][TRANSITION_DONE] = false
    -- status: RESET
    return false
  end
  if transitions[idx][TRANSITION_DONE] == false and (getTime() - transitions[idx][TRANSITION_LASTCHANGED]) > transitions[idx][TRANSITION_DELAY] then
    -- enough time has passed after RESET
    transitions[idx][TRANSITION_DONE] = true
    -- status: FIRE
    return true;
  end
end

local function checkEvents(celm)
  loadFlightModes()
  
  -- silence alarms when showing min/max values
  if status.showMinMaxValues == false then
    utils.checkAlarm(conf.minAltitudeAlert,telemetry.homeAlt,ALARMS_MIN_ALT,-1,"minalt",conf.repeatAlertsPeriod)
    utils.checkAlarm(conf.maxAltitudeAlert,telemetry.homeAlt,ALARMS_MAX_ALT,1,"maxalt",conf.repeatAlertsPeriod)  
    utils.checkAlarm(conf.maxDistanceAlert,telemetry.homeDist,ALARMS_MAX_DIST,1,"maxdist",conf.repeatAlertsPeriod)  
    utils.checkAlarm(1,2*telemetry.ekfFailsafe,ALARMS_FS_EKF,1,"ekf",conf.repeatAlertsPeriod)  
    utils.checkAlarm(1,2*telemetry.battFailsafe,ALARMS_FS_BATT,1,"lowbat",conf.repeatAlertsPeriod)  
    utils.checkAlarm(conf.timerAlert,status.flightTime,ALARMS_TIMER,1,"timealert",conf.timerAlert)
#ifdef HDOP_ALERT    
    if telemetry.gpsStatus  > 2 then
      utils.checkAlarm(conf.maxHdopAlert,telemetry.gpsHdopC,ALARMS_MAX_HDOP,1,"badgps",conf.repeatAlertsPeriod)  
    end
#endif
  end
  
  -- default is use battery 1
  local capacity = getBatt1Capacity()
  local mah = telemetry.batt1mah
  -- only if dual battery has been detected use battery 2
  if (status.batt2sources.fc or status.batt2sources.vs) and conf.battConf == BATTCONF_PARALLEL then
      capacity = capacity + getBatt2Capacity()
      mah = mah  + telemetry.batt2mah
  end
  --
#ifdef BATTPERC_BY_VOLTAGE
  if conf.enableBattPercByVoltage == true then
  -- discharge curve is based on battery under load, when motors are disarmed
  -- cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    if telemetry.statusArmed then
      status.batLevel = getBattPercByCell(celm*0.01)
    else
      status.batLevel = getBattPercByCell((celm*0.01)-VOLTAGE_DROP)
    end
  else
#endif
    if (capacity > 0) then
      status.batLevel = (1 - (mah/capacity))*100
    else
      status.batLevel = 99
    end
#ifdef BATTPERC_BY_VOLTAGE
  end
#endif
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
  if telemetry.frameType ~= -1 and checkTransition(TRANSITIONS_FLIGHTMODE,telemetry.flightMode) then
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
  utils.checkAlarm(conf.battAlertLevel1,celm,ALARMS_BATT_L1,-1,"batalert1",conf.repeatAlertsPeriod)
  utils.checkAlarm(conf.battAlertLevel2,celm,ALARMS_BATT_L2,-1,"batalert2",conf.repeatAlertsPeriod)
  -- cell bgcolor is sticky but gets triggered with alarms
  if status.battLevel1 == false then status.battLevel1 = alarms[ALARMS_BATT_L1][ALARM_NOTIFIED] end
  if status.battLevel2 == false then status.battLevel2 = alarms[ALARMS_BATT_L2][ALARM_NOTIFIED] end
end

local function cycleBatteryInfo()
  if status.showDualBattery == false and (status.batt2sources.fc or status.batt2sources.vs) and conf.battConf ~= BATTCONF_SERIAL then
    status.showDualBattery = true
    return
  end
  status.battsource = status.battsource == "vs" and "fc" or "vs" 
end
--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
--
local bgclock = 0
#ifdef BGTELERATE
local bgtelecounter = 0
local bgtelerate = 0
local bgtelestart = 0
#endif --BGTELERATE

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local timer2Hz = getTime()
local function backgroundTasks(myWidget,telemetryLoops)
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,telemetryLoops
  do
    local sensor_id,frame_id,data_id,value = sportTelemetryPop()
    
    if frame_id == 0x10 then
      status.noTelemetryData = 0
      -- no telemetry dialog only shown once
      status.hideNoTelemetry = true
      processTelemetry(data_id,value)
#ifdef LOGTELEMETRY
      -- log pitch and roll at max 3Hz
      if lastAttiLogTime == 0 then
        io.write(logfile, getTime(),";" , flightTime, ";", data_id, ";", value, "\r\n")
        lastAttiLogTime = getTime()
      elseif DATA_ID == 0x5006 and getTime() - lastAttiLogTime > 33 then -- 330ms
        io.write(logfile, getTime(),";" , flightTime, ";", data_id, ";", value, "\r\n")        
        lastAttiLogTime = getTime()
      else
        io.write(logfile, getTime(),";" , flightTime, ";", data_id, ";", value, "\r\n")        
      end
#endif --LOGTELEMETRY
    end
#ifdef BGTELERATE
    ------------------------
    -- CALC BG TELE PROCESSING RATE
    ------------------------
    -- skip first iteration
    local now = getTime()
    
    if bgtelecounter == 0 then
      bgtelestart = now
    else
      bgtelerate = bgtelerate*0.8 + 100*0.2*bgtelecounter/(now - bgtelestart + 1)
    end
    --
    bgtelecounter=bgtelecounter+1
    
    if now - bgtelestart > 1000 then
      bgtelecounter = 0
    end
#endif --BGTELERATE
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
    --export OpenTX sensor values
    setSensorValues()
    -- update total distance as often as po
    utils.updateTotalDist()
    
    if getTime() - timer2Hz > 50 then
      status.screenTogglePage = utils.getScreenTogglePage(myWidget,conf,status)
      timer2Hz = getTime()
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
 end
  
  -- SLOWER: this runs around 1.25Hz but not when the previous block runs
  -- because bgclock%4 == 0 is always different than bgclock%2==1
  if bgclock % 4 == 0 then
    -- update battery
    calcBattery()
    -- prepare celm based on status.battsource
    local count1,count2 = calcCellCount()
    local cellVoltage = 0
    
    if conf.battConf ==  BATTCONF_OTHER then
      -- alarms are based on battery 1
      cellVoltage = 100*(status.battsource == "vs" and status.cell1min or status.cell1sumFC/count1)
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
    -- aggregate value
    minmaxValues[MAX_CURR] = math.max((conf.battConf ==  BATTCONF_OTHER and telemetry.batt1current or telemetry.batt1current+telemetry.batt2current), minmaxValues[MAX_CURR])
    
    -- indipendent values
    minmaxValues[MAX_CURR1] = math.max(telemetry.batt1current,minmaxValues[MAX_CURR1])
    minmaxValues[MAX_CURR2] = math.max(telemetry.batt2current,minmaxValues[MAX_CURR2])
    
    -- reset backlight panel
    if (model.getGlobalVariable(BACKLIGHT_GV,0) > 0 and getTime()/100 - backlightLastTime > BACKLIGHT_DURATION) then
      model.setGlobalVariable(BACKLIGHT_GV,0,0)
    end
    -- reload config
    if (model.getGlobalVariable(CONF_GV,CONF_FM_GV) > 0) then
      loadConfig()
      model.setGlobalVariable(CONF_GV,CONF_FM_GV,0)
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
        
    bgclock = 0
  end
  bgclock = bgclock+1
  -- blinking support
  if (getTime() - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = getTime()
#ifdef LOGTELEMETRY
    -- flush
    pcall(io.close,logfile)
    logfile = io.open(logfilename,"a")
#endif --LOGTELEMETRY
  end
  collectgarbage()
  collectgarbage()
  return 0
end

local showSensorPage = false
local showMessages = false

local function init()
#ifdef COMPILE
  loadScript("/SCRIPTS/YAAPU/menu.lua","c")
  loadScript(libBasePath.."reset.lua","c")
  loadScript(libBasePath.."copter.lua","c")
  loadScript(libBasePath.."plane.lua","c")
  loadScript(libBasePath.."copter_px4.lua","c")
  loadScript(libBasePath.."plane_px4.lua","c")
  loadScript(libBasePath.."rover.lua","c")
  loadScript(libBasePath..drawLibFile..".lua","c")
#endif  
  -- initialize flight timer
  model.setTimer(2,{mode=0})
#ifdef TESTMODE
  telemetry.lat = -35.362864
  telemetry.lon = 149.165491
#else
  model.setTimer(2,{value=0})
#endif
-- load configuration at boot and only refresh if GV(8,8) = 1
  loadConfig()
  -- load draw library
  drawLib = utils.doLibrary(drawLibFile)
    
  currentModel = model.getInfo().name
  -- load custom sensors
  utils.loadCustomSensors()
  -- ok done
  utils.pushMessage(7,VERSION)
#ifdef TESTMODE
#ifdef DEMO
  utils.pushMessage(6,"APM:Copter V3.5.4 (284349c3) QUAD")
  utils.pushMessage(6,"Calibrating barometer")
  utils.pushMessage(6,"Initialising APM")
  utils.pushMessage(6,"Barometer calibration complete")
  utils.pushMessage(6,"EKF2 IMU0 initial yaw alignment complete")
  utils.pushMessage(6,"EKF2 IMU1 initial yaw alignment complete")
  utils.pushMessage(6,"GPS 1: detected as u-blox at 115200 baud")
  utils.pushMessage(6,"EKF2 IMU0 tilt alignment complete")
  utils.pushMessage(6,"EKF2 IMU1 tilt alignment complete")
  utils.pushMessage(6,"u-blox 1 HW: 00080000 SW: 2.01 (75331)")
  utils.pushMessage(4,"Bad AHRS")
#else -- add some more messages to force memory allocation :-)
#ifdef TESTMESSAGES
  utils.pushMessage(6,"APM:Copter V3.5.4 (284349c3) QUAD")
  utils.pushMessage(6,"Calibrating barometer")
  utils.pushMessage(6,"Initialising APM")
  utils.pushMessage(6,"Barometer calibration complete")
  utils.pushMessage(6,"EKF2 IMU0 initial yaw alignment complete")
  utils.pushMessage(6,"EKF2 IMU1 initial yaw alignment complete")
#endif --TESTMESSAGES
#endif --DEMO
#endif --TESTMODE
#ifdef LOGTELEMETRY
  logfilename = getLogFilename(getDateTime())
  logfile = io.open(logfilename,"a")
  io.write(logfile, "counter;f_time;data_id;value\r\n")  
  utils.pushMessage(7,logfilename)
#endif --LOGTELEMETRY
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
local options = {
  { "page", VALUE, 1, 1, 5},
}
-- shared init flag
local initDone = 0
-- This function is runned once at the creation of the widget
local function create(zone, options)
  -- this vars are widget scoped, each instance has its own set
  local vars = {
    #ifdef HUDRATE
    hudcounter = 0,
    hudrate = 0,
    hudstart = 0,
    #endif --HUDRATE
  }
  -- all local vars are shared between widget instances
  -- init() needs to be called only once!
  if initDone == 0 then
    init()
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

local function fullScreenRequired(myWidget)
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0, 0))
  lcd.drawText(myWidget.zone.x,myWidget.zone.y,"Yaapu requires",SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(myWidget.zone.x,myWidget.zone.y+16,"full screen",SMLSIZE+CUSTOM_COLOR)
end


utils.getScreenTogglePage = function(myWidget,conf,status)
#ifdef TESTMODE
  local screenChValue = getValue(conf.screenToggleChannelId)
#else
  local screenChValue = status.hideNoTelemetry == false and -1000 or getValue(conf.screenToggleChannelId)
#endif --TESTMODE
  
  if conf.screenToggleChannelId > -1 then
    if screenChValue > -600 then
      -- message history
      return 2
    end
  end
  return myWidget.options.page
end

-- called when widget instance page changes
local function onChangePage(myWidget)
#ifdef BGTELERATE
  bgtelecounter = 0
#endif --BGTELERATE
  -- reset HUD counters
  myWidget.vars.hudcounter = 0
  collectgarbage()
  collectgarbage()
end

-- Called when script is hidden @20Hz
local function background(myWidget)
  -- when page 1 goes to background run bg tasks
  if myWidget.options.page == 1 then
    -- run bg tasks
    backgroundTasks(myWidget,12)
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

-- Called when script is visible
local function drawFullScreen(myWidget)
#ifdef HUDRATE
  ------------------------
  -- CALC HUD REFRESH RATE
  ------------------------
  -- skip first iteration
  local hudnow = getTime()
  
  if myWidget.vars.hudcounter == 0 then
    myWidget.vars.hudstart = hudnow
  else
    myWidget.vars.hudrate = myWidget.vars.hudrate*0.8 + 100*(myWidget.vars.hudcounter/(hudnow - myWidget.vars.hudstart + 1))*0.2
  end
  --
  myWidget.vars.hudcounter=myWidget.vars.hudcounter+1
  
  if hudnow - myWidget.vars.hudstart + 1 > 1000 then
    myWidget.vars.hudcounter = 0
  end
#endif --HUDRATE  
  if getTime() - slowTimer > 50 then
    -- reset phase 2 if reset pending
    if resetPending == true then
      reset()
    else
      -- frametype and model name
      local info = model.getInfo()
      -- model change event
      if currentModel ~= info.name then
        currentModel = info.name
        -- trigger reset phase 1
        reset()
      end
    end
    
    if myWidget.options.page == 3 then
      -- when page 3 goes to foreground show minmax values
      status.showMinMaxValues = true
    elseif myWidget.options.page == 4 then
      -- when page 4 goes to foreground show dual battery view
      status.showDualBattery = true
    end
    
    -- check if current widget page changed
    if currentPage ~= myWidget.options.page then
      currentPage = myWidget.options.page
      onChangePage(myWidget)
    end
    
    slowTimer = getTime()
  end
  
  -- when page 1 goes to foreground run bg tasks
  if myWidget.options.page == 1 then
    -- run bg tasks only if we are not resetting, this prevent cpu limit kill
    if resetPending == false then
      backgroundTasks(myWidget,12)
    end
  end
  --
#ifdef TESTMODE
  symMode()
#endif --TESTMODE
  
  lcd.setColor(CUSTOM_COLOR, COLOR_BG)
  if myWidget.options.page == 2 or status.screenTogglePage == 2 then
    ------------------------------------
    -- Widget Page 2 is message history
    ------------------------------------
    -- message history has black background
    lcd.setColor(CUSTOM_COLOR, COLOR_BLACK)
    lcd.clear(CUSTOM_COLOR)
    
    drawMessageScreen()
  else
    lcd.clear(CUSTOM_COLOR)
    
    if layout ~= nil then
      layout.draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
    else
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
      
      lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
      lcd.drawFilledRectangle(88,74, 304, 84, CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR,COLOR_BARS_2)
      lcd.drawFilledRectangle(90,76, 300, 80, CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
      lcd.drawText(155, 95, "loading...", DBLSIZE+CUSTOM_COLOR)
    end
  -- Layout END
  end  
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
  
  loadCycle=(loadCycle+1)%8
#ifdef HUDRATE    
  lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
  local hudrateTxt = string.format("%.1ffps",myWidget.vars.hudrate)
  lcd.drawText(212,3,hudrateTxt,SMLSIZE+CUSTOM_COLOR+RIGHT)
#endif --HUDRATE
#ifdef BGTELERATE    
  lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
  local bgtelerateTxt = string.format("%.0fHz",math.floor(bgtelerate+0.5))
  lcd.drawText(260,3,bgtelerateTxt,SMLSIZE+RIGHT+CUSTOM_COLOR)
#endif --BGTELERATE
#ifdef MEMDEBUG
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0,0))
  maxmem = math.max(maxmem,collectgarbage("count")*1024)
  -- test with absolute coordinates
  lcd.drawNumber(480,LCD_H-14,maxmem,SMLSIZE+MENU_TITLE_COLOR+RIGHT)
#endif
  collectgarbage()
  collectgarbage()
end

function refresh(myWidget)
  if myWidget.zone.h < 250 then 
    fullScreenRequired(myWidget)
    return
  end
  drawFullScreen(myWidget)
end

return { name="Yaapu", options=options, create=create, update=update, background=background, refresh=refresh }