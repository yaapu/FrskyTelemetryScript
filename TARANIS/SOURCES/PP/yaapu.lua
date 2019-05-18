#include "includes/yaapu_inc.lua"

local frameTypes = {}
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

local frame = {}
local frameType = nil

local soundFileBasePath = "/SOUNDS/yaapu0"

#ifdef X9
local gpsStatuses = {
  [0]="NoGPS",
  [1]="NoLock",
  [2]="2D",
  [3]="3D",
  [4]="DGP",
  [5]="RTK",
  [6]="RTK",
}
#else --X9
local gpsStatuses = {
  [0]="GPS",
  [1]="Lock",
  [2]="2D",
  [3]="3D",
  [4]="DG",
  [5]="RT",
  [6]="RT",
}
#endif --X9

-- EMR,ALR,CRT,ERR,WRN,NOT,INF,DBG
local mavSeverity = {
  [0] = "EMR",
  [1] = "ALR",
  [2] = "CRT",
  [3] = "ERR",
  [4] = "WRN",
  [5] = "NOT",
  [6] = "INF",
  [7] = "DBG",
}

#define CELLFULL 4.36
--------------------------------
-- FLVSS 1
local cell1min = 0
local cell1sum = 0
-- FLVSS 2
local cell2min = 0
local cell2sum = 0
-- FC 1
local cell1sumFC = 0
-- used to calculate cellcount
local cell1maxFC = 0
local cell2maxFC = 0
-- FC 2
local cell2sumFC = 0
--------------------------------
-- BATT
local battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local cell1count = 0
local cell2count = 0

local batt1sources = {
  vs = false,
  fc = false
}
local batt2sources = {
  vs = false,
  fc = false
}
-- TELEMETRY
local noTelemetryData = 1
local hideNoTelemetry = false
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
telemetry.gpsLat = nil
telemetry.gpsLon = nil
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
-- WP
telemetry.wpNumber = 0
telemetry.wpDistance = 0
telemetry.wpXTError = 0
telemetry.wpBearing = 0
telemetry.wpCommands = 0
-- VFR
telemetry.airspeed = 0
telemetry.throttle = 0
telemetry.baroAlt = 0
-- TOTAL DISTANCE
telemetry.totalDist = 0

-- FLIGHT TIME
local lastTimerStart = 0
-- MESSAGES
local msgBuffer = ""
local lastMsgValue = 0
local lastMsgTime = 0
local lastMessage
local lastMessageSeverity = 0
local lastMessageCount = 1
local messageCount = 0
local messages = {}
-- EVENTS
local lastStatusArmed = 0
local lastGpsStatus = 0
local lastFlightMode = 0
local lastSimpleMode = 0
-- BATTERY LEVELS
local batLevel = 99
local lastBattLevel = 13
-- TOTAL DISTANCE
local lastUpdateTotDist = 0
local lastSpeed = 0
-- STATUS
local status = {}
-- BLINK SUPPORT
local blinktime = getTime()
local blinkon = false


status.showDualBattery = false
status.battAlertLevel1 = false
status.battAlertLevel2 = false
status.battsource = "na"
status.flightTime = 0    -- updated from model timer 3
status.timerRunning = 0  -- triggered by landcomplete from AP
status.showMinMaxValues = false

-- 00 05 10 15 20 25 30 40 50 60 70 80 90
#define batLevels(idx) tonumber(string.sub("00051015202530405060708090",idx*2+1,idx*2+2))
-- MIN MAX
local minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
-- LIBRARY LOADING
local libBasePath = LIB_BASE_PATH
#ifdef X9
local menuLibFile = "menu9"
local drawLibFile = "draw9"
#else --X9
local menuLibFile = "menu7"
local drawLibFile = "draw7"
#endif --X9

local drawLib = nil
local menuLib = nil
#ifdef RESET
local resetLib = nil
#endif

local centerPanel = nil
local rightPanel = nil
local leftPanel = nil
local altView = nil

#ifdef MEMDEBUG
local maxmem = 0
#endif
#ifdef TESTMODE
local thrOut = 0
#endif --TESTMODE
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
  battConf = BATTCONF_PARALLEL, -- 1=parallel,2=other
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
#ifdef SYNTHVSPEED  
  enableSynthVSpeed = false,
#endif --SYNTHVSPEED
#ifdef LOGTELEMETRY  
  logLevel = false,
  logFilename = nil,
#endif --LOGTELEMETRY
#ifdef MONITOR  
  altMonitorInterval = 0,
  distMonitorInterval = 0,
#endif
  enableHaptic = false,
#ifdef HDOP_ALARM  
  maxHdopAlert = 0,
#endif
}
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
-------------------------
-- alarms
-------------------------
local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, ALARM_TYPE_MIN, 0, false, 0}, --MIN_ALT
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_ALT
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_DIST
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_EKF
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_BAT
    { false, 0 , true, ALARM_TYPE_TIMER, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0 }, --BATT L1
    { false, 0 , false, ALARM_TYPE_BATT_CRT, ALARM_TYPE_BATT_GRACE, false, 0 }, --BATT L2
#ifdef HDOP_ALARM    
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 } --MAX_HDOP
#endif
}

-------------------------
-- value transitions
-------------------------
local transitions = {
  --{ last_value, last_changed, transition_done, delay }  
    { 0, 0, false, 30 }, -- flightmode
}

#ifdef MONITOR  
-------------------------
-- sensor monitoring
-------------------------
local monitors = { -1, -1}
#endif

#ifdef FNV_HASH
-------------------------
-- message hash support, uses 312 bytes
-------------------------
local shortHashes = { 
  -- 16 bytes hashes, requires 88 bytes
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

#ifdef TELEMETRY_STATS
----------------
-- TELEMETRY STATS
----------------
local packetCount = {
  [0x5000] = 0,
  [0x5001] = 0,
  [0x5002] = 0,
  [0x5003] = 0,
  [0x5004] = 0,
  [0x5005] = 0,
  [0x5006] = 0,
  [0x5007] = 0,
  [0x5008] = 0,
  [0x5009] = 0
}

local packetStats = {
  [0x5000] = 0,
  [0x5001] = 0,
  [0x5002] = 0,
  [0x5003] = 0,
  [0x5004] = 0,
  [0x5005] = 0,
  [0x5006] = 0,
  [0x5007] = 0,
  [0x5008] = 0,
  [0x5009] = 0
}
local lastPacketCountReset = getTime()
#endif --TELEMETRY_STATS

local showMessages = false
local showConfigMenu = false
local showAltView = false
local loadCycle = 0
#ifdef MEMDEBUG
local errorCounter = 0
#endif

-----------------------------
-- clears the loaded table 
-- and recovers memory
-----------------------------
local function clearTable(t)
  if type(t)=="table" then
    for i,v in pairs(t) do
      if type(v) == "table" then
        clearTable(v)
      end
      t[i] = nil
    end
  end
  t = nil
  -- call collectgarbage twice
  collectgarbage()
  collectgarbage()
#ifdef MEMDEBUG
  maxmem = 0
#endif
end

local function doLibrary(filename)
#ifdef LOADSCRIPT
    local success,f = pcall(loadScript,libBasePath..filename..".lua")
#else --LOADSCRIPT
#ifdef LOAD_LUA
    local success,f = pcall(loadfile,libBasePath..filename..".lua")
#else --LOAD_LUA
    local success,f = pcall(loadfile,libBasePath..filename..".luac")
#endif --LOAD_LUA
#endif --LOADSCRIPT
  if success then
    local ret = f()
    collectgarbage()
    collectgarbage()
    return ret
  else
#ifdef MEMDEBUG    
    errorCounter = errorCounter+1
#endif
    collectgarbage()
    collectgarbage()
    return nil
  end
end

local function unloadPanels()
  clearTable(centerPanel)
  clearTable(rightPanel)
  clearTable(leftPanel)
  
  centerPanel = nil
  rightPanel = nil
  leftPanel = nil
  
  collectgarbage()
  collectgarbage()
end

local function loadPanels()
  if centerPanel == nil  and loadCycle == CENTER_LOAD_CYCLE then
    centerPanel = doLibrary(conf.centerPanel)
  end
  
  if rightPanel == nil  and loadCycle == RIGHT_LOAD_CYCLE then
    rightPanel = doLibrary(conf.rightPanel)
  end
  
  if leftPanel == nil  and loadCycle == LEFT_LOAD_CYCLE then
    leftPanel = doLibrary(conf.leftPanel)
  end
  
  collectgarbage()
  collectgarbage()
end

-- prevent same file from beeing played too fast
local lastSoundTime = 0

local function playSound(soundFile,skipHaptic)
  if conf.enableHaptic and skipHaptic == nil then
    playHaptic(HAPTIC_DURATION,0)
  end
  if conf.disableAllSounds  then
    return
  end
  -- prevent OpenTX play queue from getting too big
  if soundFile == "../inf" then 
    if getTime() - lastSoundTime > 65 then
      lastSoundTime = getTime()
    else
      return
    end
  end

  playFile(soundFileBasePath .."/"..conf.language.."/".. soundFile..".wav")
end

----------------------------------------------
-- sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
local function playFlightMode(flightMode)
  if conf.enableHaptic then
    playHaptic(HAPTIC_DURATION,0)
  end
  if conf.disableAllSounds  then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      playFile(soundFileBasePath.."/"..conf.language.."/".. string.lower(frame.flightModes[flightMode]) .. (frameType=="r" and "_r.wav" or ".wav"))
    end
  end
end

#ifdef X9
local function formatMessage(severity,msg)
  local shortMsg = msg
  if lastMessageCount > 1 then
    if #msg > 36 then
      shortMsg = string.sub(msg,1,36)
      collectgarbage()
    end
    local pmsg = string.format("%02d:%s %s (x%d)", messageCount, mavSeverity[severity], shortMsg, lastMessageCount)
    msg=nil
    shortMsg = nil
    collectgarbage()
    return pmsg
  else
    if #msg > 40 then
      shortMsg = string.sub(msg,1,40)
      collectgarbage()
    end
    local pmsg = string.format("%02d:%s %s", messageCount, mavSeverity[severity], shortMsg)
    msg=nil
    shortMsg = nil
    collectgarbage()
    return pmsg
  end
end
#else --X9
local function formatMessage(severity,msg)
  local shortMsg = msg
  if lastMessageCount > 1 then
    if #msg > 16 then
      shortMsg = string.sub(msg,1,16)
      collectgarbage()
    end
    local pmsg = string.format("%d:%s %s (x%d)", messageCount, mavSeverity[severity], shortMsg, lastMessageCount)
    msg=nil
    collectgarbage()
    return pmsg
  else
    if #msg > 23 then
      shortMsg = string.sub(msg,1,23)
      collectgarbage()
    end
    local pmsg = string.format("%d:%s %s", messageCount, mavSeverity[severity], shortMsg)
    msg=nil
    collectgarbage()
    return pmsg
  end
end
#endif --X9

--[[
--------------------
-- FNV HASH
--------------------
function fnv(str)
	local hash = 2166136261
	for char in string.gmatch(str, ".") do
		hash = bit32.bxor(hash, string.byte(char))
		hash = (hash * 16777619) % 2^32
	end
	return hash
end
--]]

#define MAX_MESSAGES 9

local function pushMessage(severity, msg)
  if conf.enableHaptic then
    playHaptic(HAPTIC_DURATION,0)
  end
  if conf.disableAllSounds  == false then
    if ( severity < 5 and conf.disableMsgBeep < 3 ) then
      playSound("../err",true)
    else
      if conf.disableMsgBeep < 2 then 
          playSound("../inf",true)
      end
    end
  end
  if msg == lastMessage then
    lastMessageCount = lastMessageCount + 1
  else  
    lastMessageCount = 1
    messageCount = messageCount + 1
  end
  messages[(messageCount-1) % MAX_MESSAGES] = formatMessage(severity,msg)
  --print("count=",messageCount,"pos=%",(messageCount-1) % MAX_MESSAGES,msg,"#messages",#messages)
  lastMessage = msg
  lastMessageSeverity = severity
  collectgarbage()
  collectgarbage()
end

local function startTimer()
  lastTimerStart = getTime()/100
  model.setTimer(2,{mode=1})
end

local function stopTimer()
  model.setTimer(2,{mode=0})
  lastTimerStart = 0
end

#ifdef RESET
local function reset()
  ---------------
  -- BATT
  ---------------
  cell1min = 0
  cell1sum = 0
  cell2min = 0
  cell2sum = 0
  cell1sumFC = 0
  cell1maxFC = 0
  cell2sumFC = 0
  cell1count = 0
  cell2count = 0
  clearTable(minmaxValues)
  minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  ---------------
  -- TELEMETRY
  ---------------
  noTelemetryData = 1
  hideNoTelemetry = false
  ---------------
  -- FLIGHT TIME
  ---------------
  lastTimerStart = 0
  ---------------
  -- MESSAGES
  ---------------
  msgBuffer = ""
  lastMsgValue = 0
  lastMsgTime = 0
  lastMessage = nil
  lastMessageSeverity = 0
  lastMessageCount = 1
  messageCount = 0
  clearTable(messages)
  messages = {}
  ---------------
  -- EVENTS
  ---------------
  lastStatusArmed = 0
  lastGpsStatus = 0
  lastFlightMode = 0
  lastSimpleMode = 0
  ---------------
  -- BATTERY LEVELS
  ---------------
  batLevel = 99
  lastBattLevel = 13
  ---------------
  -- TOTAL DISTANCE
  ---------------
  lastUpdateTotDist = 0
  lastSpeed = 0
  
  -- unload DRAW
  clearTable(drawLib)
  drawLib = nil
  
  if resetLib == nil then
    resetLib = doLibrary("reset")
  end
  -- reset all
  resetLib.resetTelemetry(status,telemetry,battery,alarms,transitions)
  -- release resources
  clearTable(resetLib)
  resetLib = nil
  -- recover memory
  collectgarbage()
  collectgarbage()
  -- done
  pushMessage(6,"Telemetry reset done.")
  playSound("yaapu")
end
#endif --RESET

#ifdef TESTMODE
-----------------------------------------------------
-- TEST MODE
-----------------------------------------------------
local function symTimer()
#ifdef DEMO
  seconds = 60 * 9 + 30
#endif --DEMO
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
    telemetry.landComplete = 1
  else
    telemetry.landComplete = 0
  end
end

local function symGPS()
  thrOut = getValue("thr")
  if thrOut > 500 then
    telemetry.numSats = 17
    telemetry.gpsStatus = 4
    telemetry.gpsHdopC = 6
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 0
    telemetry.statusArmed = 1
    noTelemetryData = 0
  elseif thrOut < 500 and thrOut > 0  then
    telemetry.numSats = 13
    telemetry.gpsStatus = 5
    telemetry.gpsHdopC = 6
    telemetry.ekfFailsafe = 1
    telemetry.battFailsafe = 0
    telemetry.statusArmed = 1
    noTelemetryData = 0
  elseif thrOut > -500  then
    telemetry.numSats = 6
    telemetry.gpsStatus = 3
    telemetry.gpsHdopC = 120
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 1
    telemetry.statusArmed = 0
    noTelemetryData = 0
  else
    telemetry.numSats = 0
    telemetry.gpsStatus = 0
    telemetry.gpsHdopC = 100
    telemetry.ekfFailsafe = 0
    telemetry.battFailsafe = 0
    telemetry.statusArmed = 0
    noTelemetryData = 1
  end
end

local function symFrameType()
  local ch11 = getValue("ch11")
  if ch11 < -300 then
    telemetry.frameType = 2
    telemetry.simpleMode = 0
  elseif ch11 < 300 then
    telemetry.frameType = 1
    telemetry.simpleMode = 1
  else
    telemetry.frameType = 10
    telemetry.simpleMode = 2
  end
end

local function symBatt()
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
#ifdef DEMO
    if battFailsafe == 1 then
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
    telemetry.batt1current = 2*(100 +  ((thrOut)*0.01 * 30))
    telemetry.batt1volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    telemetry.batt1Capacity = 5200
    telemetry.batt1mah = math.abs(1000*(thrOut/200))
#ifdef BATT2TEST
    telemetry.batt2current = 2*(100 +  ((thrOut)*0.01 * 30))
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
    telemetry.homeDist = math.floor(15 * math.abs(thrOut)*0.1)
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
  rollCh = getValue("ch1") * 0.5
  -- pitch [1024,-1024] ==> [-90,90]
  pitchCh = getValue("ch2") * 0.0878
  -- yaw [-1024,1024] ==> [0,360]
  yawCh = getValue("ch10")
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  telemetry.roll = rollCh/3
  telemetry.pitch = pitchCh/2
  telemetry.yaw = yawCh
  telemetry.throttle = math.abs(getValue("ch3"))/10
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
  telemetry.vSpeed = 55
  telemetry.hSpeed = 88
  telemetry.airspeed = 83
#else --DEMO
  telemetry.homeAlt = yawCh * 0.01
  telemetry.range = 10 * yawCh * 0.1
  telemetry.vSpeed = yawCh * 0.1 * -1
  telemetry.hSpeed = telemetry.vSpeed
  telemetry.airspeed = telemetry.vSpeed
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

local function processTelemetry(telemetry,DATA_ID,VALUE)
  if DATA_ID == 0x5006 then -- ROLLPITCH
    -- roll [0,1800] ==> [-180,180]
    telemetry.roll = (math.min(bit32.extract(VALUE,0,11),1800) - 900) * 0.2
    -- pitch [0,900] ==> [-90,90]
    telemetry.pitch = (math.min(bit32.extract(VALUE,11,10),900) - 450) * 0.2
    -- #define ATTIANDRNG_RNGFND_OFFSET    21
    -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
    telemetry.range = bit32.extract(VALUE,22,10) * (10^bit32.extract(VALUE,21,1)) -- cm
  elseif DATA_ID == 0x5005 then -- VELANDYAW
    telemetry.vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1)) * (bit32.extract(VALUE,8,1) == 1 and -1 or 1)
    telemetry.hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
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
    telemetry.gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1) -- dm
  elseif DATA_ID == 0x5003 then -- BATT
    telemetry.batt1volt = bit32.extract(VALUE,0,9) -- dV
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell1Count == 12 and telemetry.batt1volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt1volt = 512 + telemetry.batt1volt
    end
    telemetry.batt1current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1)) --dA
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
    telemetry.homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1 * (bit32.extract(VALUE,24,1) == 1 and -1 or 1) --m
    telemetry.homeAngle = bit32.extract(VALUE, 25,  7) * 3
  elseif DATA_ID == 0x5000 then -- MESSAGES
    if VALUE ~= lastMsgValue then
      lastMsgValue = VALUE
      local c
      local msgEnd = false
      for i=3,0,-1
      do
        c = bit32.extract(VALUE,i*8,7)
        if c ~= 0 then
          msgBuffer = msgBuffer .. string.char(c)
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
                -- ok found
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
        -- push and display message
        local severity = (bit32.extract(VALUE,7,1) * 1) + (bit32.extract(VALUE,15,1) * 2) + (bit32.extract(VALUE,23,1) * 4)
        pushMessage( severity, msgBuffer)
#ifdef LOGTELEMETRY
        -- log message to file
        if conf.logLevel > 1 then
          -- calling this in protected mode
          -- io error should not block the script
          local success,logfile = pcall(io.open,conf.logFilename,"a")
          if success and logfile ~= nil then
            io.write(logfile,getTime(),";",status.flightTime,";",mavSeverity[severity],";",msgBuffer,"\r\n")
            io.close(logfile)
          end
        end
#endif
#ifdef FNV_HASH
        -- play shortHash if found otherwise "try" the full hash
        -- if it does not exist OpenTX will gracefully ignore it
        playSound(tostring(shortHash == nil and hash or shortHash),true)
        -- if required parse parameter and play it!
        if parseShortHash then
          local param = string.match(msgBuffer, ".*#(%d+).*")
          collectgarbage()
          collectgarbage()
          if param ~= nil then
            playNumber(tonumber(param),0)
            collectgarbage()
            collectgarbage()
          end
        end
        -- reset hash for next string
        parseShortHash = false
        shortHash = nil
        hash = 2166136261
        hashByteIndex = 0
#endif --FNV_HASH
        msgBuffer = nil
        -- recover memory
        collectgarbage()
        collectgarbage()
        msgBuffer = ""
      end
    end
  elseif DATA_ID == 0x5007 then -- PARAMS
    local paramId = bit32.extract(VALUE,24,4)
    local paramValue = bit32.extract(VALUE,0,24)
    if paramId == 1 then
      telemetry.frameType = paramValue
    elseif paramId == 4 then
      telemetry.batt1Capacity = paramValue
#ifdef BATT2TEST
      telemetry.batt2Capacity = paramValue
#endif --BATT2TEST
    elseif paramId == 5 then
      telemetry.batt2Capacity = paramValue
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
local function telemetryEnabled()
  return true
end
#else --TESTMODE
local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end
#endif --TESTMODE

local function getMaxValue(value,idx)
  minmaxValues[idx] = math.max(value,minmaxValues[idx])
  return status.showMinMaxValues and minmaxValues[idx] or value
end

local function calcMinValue(value,min)
  return min == 0 and value or math.min( value, min )
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
  elseif batt1sources.vs == true and cell1count > 1 then
    c1 = cell1count
  else
    c1 = math.floor( ((cell1maxFC*0.1) / CELLFULL) + 1)
  end
  
  if conf.cell2Count ~= nil and conf.cell2Count > 0 then
    c2 = conf.cell2Count
  elseif batt2sources.vs == true and cell2count > 1 then
    c2 = cell2count
  else
    c2 = math.floor(((cell2maxFC*0.1)/CELLFULL) + 1)
  end
  
  return c1,c2
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

local function getBatt1Capacity()
  return conf.battCapOverride1 > 0 and conf.battCapOverride1*10 or telemetry.batt1Capacity  
end

local function getBatt2Capacity()
  return conf.battCapOverride2 > 0 and conf.battCapOverride2*10 or telemetry.batt2Capacity
end

local function calcFLVSSBatt(battIdx)
  local cellMin,cellSum,cellCount
  local battSources = battIdx == 1 and batt1sources or batt2sources
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
    -- if connected after script started
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
  return cellMin,cellSum,cellCount,battSources
end

local function calcBattery()
  ------------
  -- FLVSS 1
  ------------
  cell1min, cell1sum, cell1count = calcFLVSSBatt(1) --1 = Cels
  
  ------------
  -- FLVSS 2
  ------------
  cell2min, cell2sum, cell2count = calcFLVSSBatt(2) --2 = Cel2
  
  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if telemetry.batt1volt > 0 then
    -- needed to calculate cell count
    cell1maxFC = math.max(telemetry.batt1volt,cell1maxFC)
    cell1sumFC = telemetry.batt1volt*0.1
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    batt1sources.fc = true
  else
    batt1sources.fc = false
    cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if telemetry.batt2volt > 0 then
    cell2maxFC = math.max(telemetry.batt2volt,cell2maxFC)
    cell2sumFC = telemetry.batt2volt*0.1
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    batt2sources.fc = true
  else
    batt2sources.fc = false
    cell2sumFC = 0
  end
  -- batt fc
  minmaxValues[MIN_BATT1_FC] = calcMinValue(cell1sumFC,minmaxValues[MIN_BATT1_FC])
  minmaxValues[MIN_BATT2_FC] = calcMinValue(cell2sumFC,minmaxValues[MIN_BATT2_FC])
  -- cell flvss
  minmaxValues[MIN_CELL1_VS] = calcMinValue(cell1min,minmaxValues[MIN_CELL1_VS])
  minmaxValues[MIN_CELL2_VS] = calcMinValue(cell2min,minmaxValues[MIN_CELL2_VS])
  -- batt flvss
  minmaxValues[MIN_BATT1_VS] = calcMinValue(cell1sum,minmaxValues[MIN_BATT1_VS])
  minmaxValues[MIN_BATT2_VS] = calcMinValue(cell2sum,minmaxValues[MIN_BATT2_VS])
  ------------------------------------------
  -- table to pass battery info to panels
  -- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
  -- value = offset + [0 aggregate|1 for batt 1| 2 for batt2]
  -- batt2 = 4 + 2 = 6
  ------------------------------------------
  -- Note: these can be calculated. not necessary to track them as min/max 
  -- cell1minFC = cell1sumFC/calcCellCount()
  -- cell2minFC = cell2sumFC/calcCellCount()
  -- cell1minA2 = cell1sumA2/calcCellCount()
  
  local count1,count2 = calcCellCount()
  -- 3 cases here
  -- 1) parallel => all values depend on both batteries
  -- 2) other => all values depend on battery 1
  -- 3) serial => celm(vs) and vbatt(vs) depend on both batteries, all other values on PM battery 1 (this is not supported: 1 PM + 2xFLVSS)
  
  battery[BATT_CELL+1] = getMinVoltageBySource(status.battsource, cell1min, cell1sumFC/count1, 1)*100 --cel1m
  battery[BATT_CELL+2] = getMinVoltageBySource(status.battsource, cell2min, cell2sumFC/count2, 2)*100 --cel2m
  battery[BATT_CELL] = (conf.battConf ==  BATTCONF_OTHER and battery[2] or getNonZeroMin(battery[2],battery[3]) )
  
  battery[BATT_VOLT+1] = getMinVoltageBySource(status.battsource, cell1sum, cell1sumFC, 1)*10 --batt1
  battery[BATT_VOLT+2] = getMinVoltageBySource(status.battsource, cell2sum, cell2sumFC, 2)*10 --batt2
  battery[BATT_VOLT] = (conf.battConf ==  BATTCONF_OTHER and battery[5] or (conf.battConf == BATTCONF_SERIAL and battery[5]+battery[6] or getNonZeroMin(battery[5],battery[6]))) 
  
  battery[BATT_CURR] = getMaxValue((conf.battConf ==  BATTCONF_OTHER and telemetry.batt1current or telemetry.batt1current + telemetry.batt2current),MAX_CURR)
  battery[BATT_CURR+1] = getMaxValue(telemetry.batt1current,MAX_CURR1) --curr1
  battery[BATT_CURR+2] = getMaxValue(telemetry.batt2current,MAX_CURR2) --curr2
  
  battery[BATT_MAH] = (conf.battConf ==  BATTCONF_OTHER and telemetry.batt1mah or telemetry.batt1mah + telemetry.batt2mah)
  battery[BATT_MAH+1] = telemetry.batt1mah --mah1
  battery[BATT_MAH+2] = telemetry.batt2mah --mah2
  
  battery[BATT_CAP] = (conf.battConf ==  BATTCONF_OTHER and getBatt1Capacity() or getBatt1Capacity() + getBatt2Capacity())
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
  if ( status.timerRunning == 0 and telemetry.landComplete == 1 and lastTimerStart == 0) then
    startTimer()
  end
  if (status.timerRunning == 1 and telemetry.landComplete == 0 and lastTimerStart ~= 0) then
    stopTimer()
    -- play landing complete only if motorts are armed
    if telemetry.statusArmed == 1 then
      playSound("landing")
    end
  end
  status.timerRunning = telemetry.landComplete
end

local function calcFlightTime()
#ifdef RESET  
  if model.getTimer(2).value < status.flightTime then
    if telemetry.statusArmed == 0 then
      reset()
    else
      model.setTimer(2,{value=status.flightTime})
      pushMessage(4,"Reset ignored while armed")
    end
  end
#endif --RESET  
  -- update local variable with timer 3 value
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
  setTelemetryValue(GSpd_ID, GSpd_SUBID, GSpd_INSTANCE, telemetry.hSpeed*0.1, 4 , GSpd_PRECISION , GSpd_NAME)
  setTelemetryValue(Alt_ID, Alt_SUBID, Alt_INSTANCE, telemetry.homeAlt*10, 9 , Alt_PRECISION , Alt_NAME)
  setTelemetryValue(GAlt_ID, GAlt_SUBID, GAlt_INSTANCE, math.floor(telemetry.gpsAlt*0.1), 9 , GAlt_PRECISION , GAlt_NAME)
  setTelemetryValue(Hdg_ID, Hdg_SUBID, Hdg_INSTANCE, math.floor(telemetry.yaw), 20 , Hdg_PRECISION , Hdg_NAME)
  setTelemetryValue(IMUTmp_ID, IMUTmp_SUBID, IMUTmp_INSTANCE, telemetry.imuTemp, 11 , IMUTmp_PRECISION , IMUTmp_NAME)
  setTelemetryValue(ARM_ID, ARM_SUBID, ARM_INSTANCE, telemetry.statusArmed*100, 0 , ARM_PRECISION , ARM_NAME)
end

local function drawAllMessages()
  for i=0,#messages do
    lcd.drawText(1,1+7*i, messages[(messageCount + i) % (#messages+1)],SMLSIZE)
  end
end
---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
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
  --
  if alarms[idx][ALARM_TYPE] == ALARM_TYPE_TIMER then
    if status.flightTime > 0 and math.floor(status.flightTime) %  delay == 0 then
      if alarms[idx][ALARM_NOTIFIED] == false then 
        alarms[idx][ALARM_NOTIFIED] = true
        playSound(sound)
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
      --
      if alarms[idx][ALARM_READY] == true and alarms[idx][ALARM_NOTIFIED] == false then 
        playSound(sound)
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
#ifdef COMPILE
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
    if frame.flightModes then
      frameType = frameTypes[telemetry.frameType]
      -- recover some memory
      clearTable(frameTypes)
    end
  end
end

local function getFlightMode()
  if frame.flightModes then
    return frame.flightModes[telemetry.flightMode]
  else
    return nil
  end
end

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
  if transitions[idx][TRANSITION_DONE] == false and (getTime() - transitions[idx][TRANSITION_LASTCHANGED]) >= transitions[idx][TRANSITION_DELAY] then
    -- enough time has passed after RESET
    transitions[idx][TRANSITION_DONE] = true
    -- status: FIRE
    return true;
  end
end

#ifdef MONITOR  
local function monitorValue(idx,value,unit,multiple,sound)
  if multiple == 0 then
    return
  end
  
  --{ last_value, last_changed, transition_done, delay }
  if math.floor(value) > 0 and math.floor(value) % multiple == 0 then
    if monitors[idx] ~= math.floor(value) then
      monitors[idx] = math.floor(value)
      playSound(sound)
      playNumber(math.floor(value), unit, 0)
    end
  end
end
#endif --MONITOR

local function checkEvents()
  loadFlightModes()
  
  checkAlarm(conf.minAltitudeAlert,telemetry.homeAlt,ALARMS_MIN_ALT,-1,"minalt",conf.repeatAlertsPeriod)
  checkAlarm(conf.maxAltitudeAlert,telemetry.homeAlt,ALARMS_MAX_ALT,1,"maxalt",conf.repeatAlertsPeriod)  
  checkAlarm(conf.maxDistanceAlert,telemetry.homeDist,ALARMS_MAX_DIST,1,"maxdist",conf.repeatAlertsPeriod)
  checkAlarm(1,2*telemetry.ekfFailsafe,ALARMS_FS_EKF,1,"ekf",conf.repeatAlertsPeriod)  
  checkAlarm(1,2*telemetry.battFailsafe,ALARMS_FS_BATT,1,"lowbat",conf.repeatAlertsPeriod)  
  checkAlarm(math.floor(conf.timerAlert),status.flightTime,ALARMS_TIMER,1,"timealert",math.floor(conf.timerAlert))
#ifdef HDOP_ALARM
  if telemetry.gpsStatus > 2 and conf.maxHdopAlert > 0 then
    checkAlarm(conf.maxHdopAlert,telemetry.gpsHdopC,ALARMS_MAX_HDOP,1,"badgps",conf.repeatAlertsPeriod)  
  end
#endif

  local capacity = getBatt1Capacity()
  local mah = telemetry.batt1mah
  
  -- only if dual battery has been detected
  if (batt2sources.fc or batt2sources.vs) and conf.battConf == BATTCONF_PARALLEL then
      capacity = capacity + getBatt2Capacity()
      mah = mah  + telemetry.batt2mah
  end
  
  if (capacity > 0) then
    batLevel = (1 - (mah/capacity))*100
  else
    batLevel = 99
  end

  for l=0,12 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    local level = batLevels(l)
    if batLevel <= level + 1 and l < lastBattLevel then
      lastBattLevel = l
      playSound("bat"..level)
      break
    end
  end

  if telemetry.statusArmed ~= lastStatusArmed then
    if telemetry.statusArmed == 1 then playSound("armed") else playSound("disarmed") end
    lastStatusArmed = telemetry.statusArmed
  end

  if telemetry.gpsStatus > 2 and lastGpsStatus <= 2 then
    lastGpsStatus = telemetry.gpsStatus
    playSound("gpsfix")
  elseif telemetry.gpsStatus <= 2 and lastGpsStatus > 2 then
    lastGpsStatus = telemetry.gpsStatus
    playSound("gpsnofix")
  end

  -- flightmode transitions have a grace period to prevent unwanted flightmode call out
  -- on quick radio mode switches
  if frame.flightModes ~= nil and checkTransition(TRANSITIONS_FLIGHTMODE,telemetry.flightMode) then
    playFlightMode(telemetry.flightMode)
  end
  
  if telemetry.simpleMode ~= lastSimpleMode then
    if telemetry.simpleMode == 0 then
      playSound( lastSimpleMode == 1 and "simpleoff" or "ssimpleoff" )
    else
      playSound( telemetry.simpleMode == 1 and "simpleon" or "ssimpleon" )
    end
    lastSimpleMode = telemetry.simpleMode
  end
#ifdef MONITOR  
  -- monitor altitude and distance for changes, play vocal alert if required
  local feetOrMeters = getGeneralSettings().imperial == 0 and OPENTX_UNIT_METERS or OPENTX_UNIT_FEET
  monitorValue(MONITOR_ALTITUDE, telemetry.homeAlt*UNIT_ALT_SCALE, feetOrMeters, conf.altMonitorInterval, "alt")
  monitorValue(MONITOR_DISTANCE, telemetry.homeDist*UNIT_DIST_SCALE, feetOrMeters, conf.distMonitorInterval, "dist")
#endif --MONITOR
end

local function checkCellVoltage(celm)
  -- check alarms
  checkAlarm(conf.battAlertLevel1,celm,ALARMS_BATT_L1,-1,"batalert1",conf.repeatAlertsPeriod)
  checkAlarm(conf.battAlertLevel2,celm,ALARMS_BATT_L2,-1,"batalert2",conf.repeatAlertsPeriod)
  
  if status.battAlertLevel1 == false then status.battAlertLevel1 = alarms[ALARMS_BATT_L1][ALARM_NOTIFIED] end
  if status.battAlertLevel2 == false then status.battAlertLevel2 = alarms[ALARMS_BATT_L2][ALARM_NOTIFIED] end
end

local function cycleBatteryInfo()
  if status.showDualBattery == false and (batt2sources.fc or batt2sources.vs) and conf.battConf ~= BATTCONF_SERIAL then
    status.showDualBattery = true
    return
  end
  status.battsource = status.battsource == "vs" and "fc" or "vs" 
end

local function updateTotalDist()
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

--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
local bgclock = 0
#ifdef BGRATE
local counter = 0
local bgrate = 0
local bgstart = 0
#endif --BGRATE
#ifdef FGRATE
local fgcounter = 0
local fgrate = 0
local fgstart = 0
#endif --FGRATE
#ifdef HUDRATE
local hudcounter = 0
local hudrate = 0
local hudstart = 0
#endif --HUDRATE
#ifdef BGTELERATE
local bgtelecounter = 0
local bgtelerate = 0
local bgtelestart = 0
#endif --BGTELERATE
-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
#ifdef BGRATE
  ------------------------
  -- CALC BG LOOP RATE
  ------------------------
  -- skip first iteration
  local now = getTime()/100
  if counter == 0 then
    bgstart = now
  else
    bgrate = counter / (now - bgstart)
  end
  --
  counter=counter+1
#endif --BGRATE
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,3
  do
    local sensor_id,frame_id,data_id,value = sportTelemetryPop()
    
    if frame_id == 0x10 then
      processTelemetry(telemetry,data_id,value)
#ifdef TELEMETRY_STATS
      -- update packet stats
      if getTime() - lastPacketCountReset > 200 then
        lastPacketCountReset = getTime()
        for i=0,9 do
          packetStats[0x5000+i] = packetCount[0x5000+i]/2
          packetCount[0x5000+i] = 0
        end
      end
      if packetCount[data_id] ~= nil then
        packetCount[data_id] = packetCount[data_id] + 1
      end
#endif --TELEMETRY_STATS
      -- update telemetry status
      noTelemetryData = 0
      hideNoTelemetry = true
    end
#ifdef BGTELERATE
    ------------------------
    -- CALC BG TELE PROCESSING RATE
    ------------------------
    -- skip first iteration
    local now = getTime()/100
    if bgtelecounter == 0 then
      bgtelestart = now
    else
      bgtelerate = bgtelecounter / (now - bgtelestart)
    end
    --
    bgtelecounter=bgtelecounter+1
#endif --BGTELERATE
  end
  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
    setSensorValues()
    updateTotalDist()
  end
  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    calcBattery()
    calcFlightTime()
    -- prepare celm based on status.battsource
    local count1,count2 = calcCellCount()
    local cellVoltage = 0
    
    if conf.battConf ==  BATTCONF_OTHER then
      -- alarms are based on battery 1
      cellVoltage = 100*(status.battsource == "vs" and cell1min or cell1sumFC/count1)
    else
      -- alarms are based on battery 1 and battery 2
      cellVoltage = 100*(status.battsource == "vs" and getNonZeroMin(cell1min,cell2min) or getNonZeroMin(cell1sumFC/count1,cell2sumFC/count2))
    end
    --
    checkEvents()
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
    
#ifdef CUSTOM_BG_CALL
    -- call custom panel background functions
    if leftPanel ~= nil then
      leftPanel.background(conf,telemetry,status,getMaxValue,checkAlarm)
    end
    if centerPanel ~= nil then
      centerPanel.background(conf,telemetry,status,getMaxValue,checkAlarm)
    end
    if rightPanel ~= nil then
      rightPanel.background(conf,telemetry,status,getMaxValue,checkAlarm)
    end
    if altView ~= nil then
      altView.background(conf,telemetry,status,getMaxValue,checkAlarm)
    end
#endif --CUSTOM_BG_CALL

    -- update GPS coordinates
    local gpsData = getValue("GPS")
    
    if type(gpsData) == "table" and gpsData.lat ~= nil and gpsData.lon ~= nil then
      telemetry.gpsLat = math.floor(gpsData.lat * 100000) / 100000
      telemetry.gpsLon = math.floor(gpsData.lon * 100000) / 100000
      collectgarbage()
      collectgarbage()
    end 
    
    bgclock=0
  end
  -- blinking support
  if (getTime() - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = getTime()
  end
  bgclock = bgclock+1
  collectgarbage()
  collectgarbage()
end

local function run(event)
  lcd.clear()
#ifdef DEBUGEVT
  if event > 0 then
    pushMessage(7,tostring(event))
  end
#endif
#ifdef FGRATE
  ------------------------
  -- CALC FG LOOP RATE
  ------------------------
  -- skip first iteration
  local now = getTime()/100
  if fgcounter == 0 then
    fgstart = now
  else
    fgrate = fgcounter / (now - fgstart)
  end
  --
  fgcounter=fgcounter+1
#endif --FGRATE

#ifdef HUDRATE
    ------------------------
    -- CALC HUD REFRESH RATE
    ------------------------
    -- skip first iteration
    local hudnow = getTime()/100
    if hudcounter == 0 then
      hudstart = hudnow
    else
      hudrate = hudcounter / (hudnow - hudstart)
    end
    hudcounter=hudcounter+1
#endif --HUDRATE
  
#ifdef TESTMODE
  symMode()
#endif --TESTMODE
  
  if showMessages then
    ---------------------
    -- MESSAGES
    ---------------------
    drawAllMessages()

    if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == XLITE_DOWN or event == EVT_EXIT_BREAK or event == XLITE_RTN then
      showMessages = false
    elseif event == EVT_ENTER_BREAK or event == XLITE_ENTER then
      if showAltView == false then
        -- main --> altview
        unloadPanels()
        showAltView = true
      else
        -- altview --> main
        clearTable(altView)
        altView = nil
        showAltView = false
      end
      showMessages = false
      collectgarbage()
      collectgarbage()
    elseif event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == XLITE_UP then
      showMessages = false
    end
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    -- top bars
    lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID+FORCE)
    -- bottom bar
    lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID+FORCE)
    
    if menuLib == nil and loadCycle == MENU_LOAD_CYCLE then
      menuLib = doLibrary(menuLibFile)
      if menuLib ~= nil then
        menuLib.loadConfig(conf)
        collectgarbage()
        collectgarbage()
      end
    end
    
    if menuLib ~= nil then
      menuLib.drawConfigMenu(event)
    end
    

    if event == EVT_EXIT_BREAK then
      showConfigMenu = false
      -- unload MENU
      menuLib.saveConfig(conf)
      clearTable(menuLib)
      menuLib = nil
#ifdef LOGTELEMETRY
      pushMessage(7,conf.logLevel > 1 and "msg logging enabled" or "msg logging disabled")
#endif --LOGTELEMETRY
      collectgarbage()
      collectgarbage()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if event == EVT_ENTER_BREAK or event == XLITE_ENTER then
      cycleBatteryInfo()
    end
    if event == EVT_MENU_BREAK or event == XLITE_MENU then
      status.showMinMaxValues = not status.showMinMaxValues
    end
    
    if status.showDualBattery == true and (event == EVT_EXIT_BREAK or event == XLITE_RTN) then
      status.showDualBattery = false
    end
    
    if drawLib == nil and loadCycle == DRAWLIB_LOAD_CYCLE then
      -- load draw library
      drawLib = doLibrary(drawLibFile)
      collectgarbage()
      collectgarbage()
    end
    
      -- top bars
    lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, FORCE)
    
    if showAltView then
      if altView == nil and loadCycle == ALTVIEW_LOAD_CYCLE then
        -- load ALTVIEW
        altView = doLibrary(conf.altView)
        collectgarbage()
        collectgarbage()
      end
      
      if drawLib ~= nil and altView ~= nil then
        altView.drawView(drawLib,conf,telemetry,status,battery,(batt2sources.fc or batt2sources.vs) and BATT_IDALL or BATT_ID1,getMaxValue,gpsStatuses)
      end
      
      if event == EVT_EXIT_BREAK or event == XLITE_RTN then
        showMessages = false
        showAltView = false
        
        clearTable(altView)
        altView = nil
        collectgarbage()
        collectgarbage()
      elseif event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == XLITE_UP then
        showMessages = true
      end
    else
      -- draw PANELS
      loadPanels()
      
      if centerPanel ~= nil and rightPanel ~= nil and leftPanel ~= nil and drawLib ~= nil then
        -- with dual battery default is to show aggregate view
        if batt2sources.fc or batt2sources.vs then
          if status.showDualBattery == false then
            -- dual battery: aggregate view
            rightPanel.drawPane(RIGHTPANE_X,drawLib,conf,telemetry,status,battery,BATT_IDALL,getMaxValue,gpsStatuses) -- 0=aggregate view
  #ifdef X9        
            lcd.drawText(RIGHTPANE_X-5, 0, "2B", SMLSIZE+INVERS)
  #else --X9
            lcd.drawText(HUD_X+5, LCD_H-16, "2B", SMLSIZE)
  #endif --X9
          else
            -- dual battery:battery 1 right pane
            rightPanel.drawPane(RIGHTPANE_X,drawLib,conf,telemetry,status,battery,BATT_ID1,getMaxValue,gpsStatuses) -- 1=battery 1
            -- dual battery:battery 2 left pane
            rightPanel.drawPane(LEFTPANE_X,drawLib,conf,telemetry,status,battery,BATT_ID2,getMaxValue,gpsStatuses) -- 2=battery 2
          end
        else
          -- battery 1 right pane in single battery mode
          rightPanel.drawPane(RIGHTPANE_X,drawLib,conf,telemetry,status,battery,BATT_ID1,getMaxValue,gpsStatuses) -- 1=battery 1
        end
        -- left pane info when not in dual battery mode
        if status.showDualBattery == false then
          leftPanel.drawPane(LEFTPANE_X,drawLib,conf,telemetry,status,battery,BATT_IDALL,getMaxValue,gpsStatuses) -- 0=aggregate view
        end
        
        centerPanel.drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)
        
        drawLib.drawGrid()
        drawLib.drawRArrow(HOMEDIR_X,HOMEDIR_Y,HOMEDIR_R,telemetry.homeAngle - telemetry.yaw,1)
        drawLib.drawFailSafe(status.showDualBattery,telemetry.ekfFailsafe,telemetry.battFailsafe)
      end
    end
    -- bottom bar
    lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, FORCE)
    
    if drawLib ~= nil then
      drawLib.drawTopBar(getFlightMode(),telemetry.simpleMode,status.flightTime,telemetryEnabled)
      drawLib.drawBottomBar(messages[(messageCount + #messages) % (#messages+1)],lastMsgTime)
      drawLib.drawNoTelemetry(telemetryEnabled,hideNoTelemetry)
    end
  -- event handler
    if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == XLITE_UP then
      ---------------------
      -- SHOW MESSAGES
      ---------------------
      showMessages = true
    elseif event == EVT_MENU_LONG or event == XLITE_MENU_LONG then
      ---------------------
      -- SHOW CONFIG MENU
      ---------------------
      clearTable(drawLib)
      clearTable(altView)
      unloadPanels()
      altView = nil
      drawLib = nil
      collectgarbage()
      collectgarbage()
      showConfigMenu = true
    end
  end
#ifdef BGRATE    
  lcd.drawNumber(0,39,bgrate*10,PREC1+SMLSIZE+INVERS)
  lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --BGRATE
#ifdef FGRATE    
  lcd.drawNumber(0,39,fgrate*10,PREC1+SMLSIZE+INVERS)
  lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --FGRATE
#ifdef HUDRATE    
  lcd.drawNumber(0,39,hudrate*10,PREC1+SMLSIZE+INVERS)
  lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --HUDRATE
#ifdef BGTELERATE    
  lcd.drawNumber(20,39,bgtelerate,SMLSIZE+INVERS)
#endif --BGTELERATE
#ifdef MEMDEBUG
  -- debug info, allocated memory
  maxmem = math.max(maxmem,collectgarbage("count")*1024)
  lcd.drawNumber(LCD_W,LCD_H-6,maxmem,SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(LCD_W,LCD_H-14,errorCounter,SMLSIZE+RIGHT+INVERS)
#endif
#ifdef TELEMETRY_STATS
  for i=0,8 do
    lcd.drawText(1,1+7*(i),string.format("%s%d: %.01f","500",i,packetStats[0x5000+i]),INVERS+SMLSIZE)
  end
#endif
#ifdef NOTELEM_BLINK
  if not telemetryEnabled() and blinkon then
    lcd.drawRectangle(0,0,LCD_W,LCD_H,showMessages and SOLID or ERASE)
  end
#endif
  loadCycle=(loadCycle+1)%LOAD_CYCLE_MAX
  collectgarbage()
  collectgarbage()
end

local function init()
-- initialize flight timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
#ifdef COMPILE
  loadScript(libBasePath.."copter.lua","c")
  loadScript(libBasePath.."plane.lua","c")
  loadScript(libBasePath.."copter_px4.lua","c")
  loadScript(libBasePath.."plane_px4.lua","c")
  loadScript(libBasePath.."rover.lua","c")
  loadScript(libBasePath.."reset.lua","c")
  loadScript(libBasePath..menuLibFile..".lua","c")
  loadScript(libBasePath..drawLibFile..".lua","c")
#endif
  -- load menu library
  menuLib = doLibrary(menuLibFile)
  menuLib.loadConfig(conf)
  collectgarbage()
  collectgarbage()
#ifdef COMPILE
  menuLib.compilePanels()
#endif
  -- ok configuration loaded
  status.battsource = conf.defaultBattSource
  -- configuration loaded, releasing menu library memory
  clearTable(menuLib)
  menuLib = nil
#ifdef X9
  pushMessage(7,VERSION)
#endif --X9
#ifdef X7
  pushMessage(7,VERSION)
#endif --X7
#ifdef TESTMODE
#ifdef DEMO
  pushMessage(6,"APM:Copter V3.5.4 (284349c3) QUAD")
  pushMessage(6,"Calibrating barometer")
  pushMessage(6,"Initialising APM")
  pushMessage(6,"Barometer calibration complete")
  pushMessage(6,"EKF2 IMU0 initial yaw alignment complete")
  pushMessage(6,"EKF2 IMU1 initial yaw alignment complete")
  pushMessage(4,"Bad AHRS")
  pushMessage(6,"GPS 1: detected as u-blox at 115200 baud")
  pushMessage(6,"EKF2 IMU0 tilt alignment complete")
  pushMessage(6,"EKF2 IMU1 tilt alignment complete")
  pushMessage(6,"u-blox 1 HW: 00080000 SW: 2.01 (75331)")
  pushMessage(4,"Bad AHRS")
  pushMessage(4,"Bad AHRS")
  pushMessage(4,"Bad AHRS")
  --]]
#endif --DEMO
#endif --TESTMODE
#ifdef LOGTELEMETRY  
  if conf.logLevel > 1 then
    pushMessage(7,"msg logging enabled")
  end
#endif
  collectgarbage()
  collectgarbage()
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}
