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


local frameTypes = {}
-- copter
frameTypes[0]   = "c"
frameTypes[2]   = "c"
frameTypes[3]   = "c"
frameTypes[4]   = "c"
frameTypes[7]   = "a"
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


local frame = {}
local frameType = nil

local soundFileBasePath = "/SOUNDS/yaapu0"

local gpsStatuses = {
  [0]="NoGPS",
  [1]="NoLock",
  [2]="2D",
  [3]="3D",
  [4]="DGP",
  [5]="RTK",
  [6]="RTK",
}

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
local battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
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
telemetry.failsafe = 0
telemetry.fencePresent = 0
telemetry.fenceBreached = 0
telemetry.throttle = 0
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
-- 
telemetry.rpm1 = 0
telemetry.rpm2 = 0
-- 
telemetry.heightAboveTerrain = 0
telemetry.terrainUnhealthy = 0

-- FLIGHT TIME
local lastTimerStart = 0
-- MESSAGES
local msgBuffer = ""
local lastMsgValue = 0
local lastMsgTime = 0
local lastMessage
local statusBarMsg
local lastMessageSeverity = 0
local lastMessageCount = 1
local messageCount = 0
local messageRow = 0
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
-- CRSF rssi support
local rssiCRSF = 0

status.showDualBattery = false
status.battAlertLevel1 = false
status.battAlertLevel2 = false
status.battsource = "na"
status.flightTime = 0    -- updated from model timer 3
status.timerRunning = 0  -- triggered by landcomplete from AP
status.showMinMaxValues = false
status.terrainLastData = getTime()
status.terrainEnabled = 0
status.airspeedEnabled = 0

-- 00 05 10 15 20 25 30 40 50 60 70 80 90
-- MIN MAX
local minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
-- LIBRARY LOADING
local libBasePath = "/SCRIPTS/TELEMETRY/yaapu/"
local menuLibFile = "menu9"
local drawLibFile = "draw9"

local drawLib = nil
local menuLib = nil
local resetLib = nil

local centerPanel = nil
local rightPanel = nil
local leftPanel = nil
local altView = nil

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
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , true, 1, 0, false, 0 }, --MAX_ALT
    { false, 0 , true, 1, 0, false, 0 }, --15
    { false, 0 , true, 1, 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1, 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 4, 4, false, 0 }, --BATT L2
    { false, 0 , true, 1, 0, false, 0 }, --FS
    { false, 0 , true, 1, 0, false, 0 }, --
    { false, 0 , true, 1, 0, false, 0 }, --
}

-------------------------
-- value transitions
-------------------------
local transitions = {
  --{ last_value, last_changed, transition_done, delay }
    { 0, 0, false, 30 }, -- flightmode
}

-------------------------
-- message hash support
-------------------------
local shortHashes = {}
-- 16 bytes hashes
shortHashes[554623408]  = false  -- "554623408.wav", "Takeoff complete"
shortHashes[3025044912] = false -- "3025044912.wav", "SmartRTL deactiv"
shortHashes[3956583920] = false -- "3956583920.wav", "EKF2 IMU0 is usi"
shortHashes[1309405592] = false -- "1309405592.wav", "EKF3 IMU0 is usi"
shortHashes[4091124880] = true  -- "4091124880.wav", "Reached command "
shortHashes[3311875476] = true  -- "3311875476.wav", "Reached waypoint"
shortHashes[1997782032] = true  -- "1997782032.wav", "Passed waypoint "

local shortHash = nil
local parseShortHash = false
local hashByteIndex = 0
local hash = 2166136261

local showMessages = false
local showConfigMenu = false
local showAltView = false
local loadCycle = 0

-- telemetry pop function, either SPort or CRSF
local telemetryPop = nil

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
  doGarbageCollect()
end


local function doLibrary(filename)
    local success,f = pcall(loadScript,libBasePath..filename..".lua")
  if success then
    local ret = f()
    doGarbageCollect()
    return ret
  else
    doGarbageCollect()
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

  doGarbageCollect()
end

local function loadPanels()
  if centerPanel == nil  and loadCycle == 4 then
    centerPanel = doLibrary(conf.centerPanel)
  end

  if rightPanel == nil  and loadCycle == 6 then
    rightPanel = doLibrary(conf.rightPanel)
  end

  if leftPanel == nil  and loadCycle == 2 then
    leftPanel = doLibrary(conf.leftPanel)
  end

  doGarbageCollect()
end

-- prevent same file from beeing played too fast
local lastSoundTime = 0

local function playSound(soundFile,skipHaptic)
  if conf.enableHaptic and skipHaptic == nil then
    playHaptic(12,0)
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
    playHaptic(12,0)
  end
  if conf.disableAllSounds  then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      playFile(soundFileBasePath.."/"..conf.language.."/".. frame.flightModes[flightMode] .. ((frameType=="r" or frameType=="b") and "_r.wav" or ".wav"))
    end
  end
end

local function haversine(lat1, lon1, lat2, lon2)
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

local function formatMessage(severity, msg)
  if lastMessageCount > 1 then
    return string.format("%d:%s (x%d) %s", messageCount, mavSeverity[severity], lastMessageCount, msg)
  else
    return string.format("%d:%s %s", messageCount, mavSeverity[severity], msg)
  end
end

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


local lastMsgTime = getTime()

local function pushMessage(severity, msg)
  if conf.enableHaptic then
    playHaptic(12,0)
  end
  local now = getTime()
  if now - lastMsgTime > 50 then
    local silence = conf.disableMsgBeep == 3 or (severity >=5 and conf.disableMsgBeep == 2)
    if silence == false then
      playSound("../" .. mavSeverity[severity],true)
    end
    lastMsgTime = now
  end

  if msg == lastMessage then
    lastMessageCount = lastMessageCount + 1
  else
    messageCount = messageCount + lastMessageCount
    lastMessageCount = 1
    messageRow = messageRow + 1
  end
  local longMsg = formatMessage(severity,msg)
  doGarbageCollect()

  if #longMsg > 45 then
    if msg == lastMessage then
      messageRow = messageRow - 1
    end
    messages[(messageRow-1) % 9] = string.sub(longMsg, 1, 45)
    statusBarMsg = messages[(messageRow-1) % 9]
    messageRow = messageRow + 1
    messages[(messageRow-1) % 9] = "    "..string.sub(longMsg, 45+1, 60)
  else
    messages[(messageRow-1) % 9] = longMsg
    statusBarMsg = longMsg
  end
  lastMessage = msg
  lastMessageSeverity = severity
  msg = nil
  doGarbageCollect()
end

local function startTimer()
  lastTimerStart = getTime()/100
  model.setTimer(2,{mode=1})
end

local function stopTimer()
  model.setTimer(2,{mode=0})
  lastTimerStart = 0
end

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
  messageRow = 0
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
  doGarbageCollect()
  -- done
  pushMessage(6,"Telemetry reset done.")
  playSound("yaapu")
end


local function updateHash(c)
  hash = bit32.bxor(hash, c)
  hash = (hash * 16777619) % 2^32
  hashByteIndex = hashByteIndex+1
  -- check if this hash matches any 16bytes prefix hash
  if hashByteIndex == 16 then
  parseShortHash = shortHashes[hash]
    if parseShortHash ~= nil then
      shortHash = hash
    end
  end
end

local function playHash()
  -- try to play the hash sound file without checking for existence
  -- OpenTX will gracefully ignore it :-)
  playSound(tostring(shortHash == nil and hash or shortHash),true)
  -- if required parse parameter and play it!
  if parseShortHash == true then
    local param = string.match(msgBuffer, ".*#(%d+).*")
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

local function processTelemetry(appId, value, now)
  if appId == 0x5006 then -- ROLLPITCH
    -- roll [0,1800] ==> [-180,180]
    telemetry.roll = (math.min(bit32.extract(value,0,11),1800) - 900) * 0.2
    -- pitch [0,900] ==> [-90,90]
    telemetry.pitch = (math.min(bit32.extract(value,11,10),900) - 450) * 0.2
    -- #define ATTIANDRNG_RNGFND_OFFSET    21
    -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
    telemetry.range = bit32.extract(value,22,10) * (10^bit32.extract(value,21,1)) -- cm
  elseif appId == 0x5005 then -- VELANDYAW
    telemetry.vSpeed = bit32.extract(value,1,7) * (10^bit32.extract(value,0,1)) * (bit32.extract(value,8,1) == 1 and -1 or 1)
    telemetry.yaw = bit32.extract(value,17,11) * 0.2
    -- once detected it's sticky
    if bit32.extract(value,28,1) == 1 then
      telemetry.airspeed = bit32.extract(value,10,7) * (10^bit32.extract(value,9,1)) -- dm/s
    else
      telemetry.hSpeed = bit32.extract(value,10,7) * (10^bit32.extract(value,9,1)) -- dm/s
    end
    if status.airspeedEnabled == 0 then
      status.airspeedEnabled = bit32.extract(value,28,1)
    end
  elseif appId == 0x5001 then -- AP STATUS
    telemetry.flightMode = bit32.extract(value,0,5)
    telemetry.simpleMode = bit32.extract(value,5,2)
    telemetry.landComplete = bit32.extract(value,7,1)
    telemetry.statusArmed = bit32.extract(value,8,1)
    telemetry.battFailsafe = bit32.extract(value,9,1)
    telemetry.ekfFailsafe = bit32.extract(value,10,2)
    telemetry.failsafe = bit32.extract(value,12,1)
    telemetry.fencePresent = bit32.extract(value,13,1)
    telemetry.fenceBreached = telemetry.fencePresent == 1 and bit32.extract(value,14,1) or 0 -- we ignore fence breach if fence is disabled
    telemetry.throttle = math.floor(0.5 + (bit32.extract(value,19,6) * (bit32.extract(value,25,1) == 1 and -1 or 1) * 1.58)) -- signed throttle [-63,63] -> [-100,100]
    -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
    telemetry.imuTemp = bit32.extract(value,26,6) + 19 -- C°
  elseif appId == 0x5002 then -- GPS STATUS
    telemetry.numSats = bit32.extract(value,0,4)
    -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
    -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
    telemetry.gpsStatus = bit32.extract(value,4,2) + bit32.extract(value,14,2)
    telemetry.gpsHdopC = bit32.extract(value,7,7) * (10^bit32.extract(value,6,1)) -- dm
    telemetry.gpsAlt = bit32.extract(value,24,7) * (10^bit32.extract(value,22,2)) * (bit32.extract(value,31,1) == 1 and -1 or 1) -- dm
  elseif appId == 0x5003 then -- BATT
    telemetry.batt1volt = bit32.extract(value,0,9) -- dV
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if >= 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell1Count >= 12 and telemetry.batt1volt < conf.cell1Count*20 then
      -- assume a 2V as minimum acceptable "real" voltage
      telemetry.batt1volt = 512 + telemetry.batt1volt
    end
    telemetry.batt1current = bit32.extract(value,10,7) * (10^bit32.extract(value,9,1)) --dA
    telemetry.batt1mah = bit32.extract(value,17,15)
  elseif appId == 0x5008 then -- BATT2
    telemetry.batt2volt = bit32.extract(value,0,9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if >= 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell2Count >= 12 and telemetry.batt2volt < conf.cell2Count*20 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt2volt = 512 + telemetry.batt2volt
    end
    telemetry.batt2current = bit32.extract(value,10,7) * (10^bit32.extract(value,9,1))
    telemetry.batt2mah = bit32.extract(value,17,15)
  elseif appId == 0x5004 then -- HOME
    telemetry.homeDist = bit32.extract(value,2,10) * (10^bit32.extract(value,0,2))
    telemetry.homeAlt = bit32.extract(value,14,10) * (10^bit32.extract(value,12,2)) * 0.1 * (bit32.extract(value,24,1) == 1 and -1 or 1) --m
    telemetry.homeAngle = bit32.extract(value, 25,  7) * 3
  elseif appId == 0x5000 then -- MESSAGES
    if value ~= lastMsgValue then
      lastMsgValue = value
      local c
      local msgEnd = false
      for i=3,0,-1
      do
        c = bit32.extract(value,i*8,7)
        if c ~= 0 then
          msgBuffer = msgBuffer .. string.char(c)
          updateHash(c)
        else
          msgEnd = true;
          break;
        end
      end
      doGarbageCollect()
      if msgEnd then
        -- push and display message
        local severity = (bit32.extract(value,7,1) * 1) + (bit32.extract(value,15,1) * 2) + (bit32.extract(value,23,1) * 4)
        pushMessage( severity, msgBuffer)
        playHash()
        resetHash()
        msgBuffer = nil
        -- recover memory
        doGarbageCollect()
        msgBuffer = ""
      end
    end
  elseif appId == 0x5007 then -- PARAMS
    local paramId = bit32.extract(value,24,4)
    local paramValue = bit32.extract(value,0,24)
    if paramId == 1 then
      telemetry.frameType = paramValue
    elseif paramId == 4 then
      telemetry.batt1Capacity = paramValue
    elseif paramId == 5 then
      telemetry.batt2Capacity = paramValue
    end
  elseif appId == 0x5009 then -- WAYPOINTS @1Hz
    telemetry.wpNumber = bit32.extract(value,0,10) -- wp index
    telemetry.wpDistance = bit32.extract(value,12,10) * (10^bit32.extract(value,10,2)) -- meters
    telemetry.wpXTError = bit32.extract(value,23,4) * (10^bit32.extract(value,22,1)) * (bit32.extract(value,27,1) == 1 and -1 or 1)-- meters
    telemetry.wpBearing = bit32.extract(value,29,3) -- offset from cog with 45° resolution
  elseif appId == 0x500A then --  1 and 2
    -- rpm1 and rpm2 are int16_t
    local rpm1 = bit32.extract(value,0,16)
    local rpm2 = bit32.extract(value,16,16)
    telemetry.rpm1 = 10*(bit32.extract(value,15,1) == 0 and rpm1 or -1*(1+bit32.band(0x0000FFFF,bit32.bnot(rpm1)))) -- 2 complement if negative
    telemetry.rpm2 = 10*(bit32.extract(value,31,1) == 0 and rpm2 or -1*(1+bit32.band(0x0000FFFF,bit32.bnot(rpm2)))) -- 2 complement if negative
  elseif appId == 0x500B then -- 
    telemetry.heightAboveTerrain = bit32.extract(value,2,10) * (10^bit32.extract(value,0,2)) * 0.1 * (bit32.extract(value,12,1) == 1 and -1 or 1) -- dm to meters
    telemetry.terrainUnhealthy = bit32.extract(value,13,1)
    status.terrainLastData = now
    status.terrainEnabled = 1
--[[
  elseif DATA_ID == 0x50F1 then -- RC CHANNELS
    -- channels 1 - 32
    local offset = bit32.extract(VALUE,0,4) * 4
    rcchannels[1 + offset] = 100 * (bit32.extract(VALUE,4,6)/63) * (bit32.extract(VALUE,10,1) == 1 and -1 or 1)
    rcchannels[2 + offset] = 100 * (bit32.extract(VALUE,11,6)/63) * (bit32.extract(VALUE,17,1) == 1 and -1 or 1)
    rcchannels[3 + offset] = 100 * (bit32.extract(VALUE,18,6)/63) * (bit32.extract(VALUE,24,1) == 1 and -1 or 1)
    rcchannels[4 + offset] = 100 * (bit32.extract(VALUE,25,6)/63) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1)
--]]
  elseif appId == 0x50F2 then -- VFR
    telemetry.airspeed = bit32.extract(value,1,7) * (10^bit32.extract(value,0,1)) -- dm/s
    telemetry.throttle = bit32.extract(value,8,7)
    telemetry.baroAlt = bit32.extract(value,17,10) * (10^bit32.extract(value,15,2)) * 0.1 * (bit32.extract(value,27,1) == 1 and -1 or 1)
    status.airspeedEnabled = 1
  end
end


local function crossfirePop()
    local now = getTime()
    local command, data = crossfireTelemetryPop()
    -- command is 0x80 CRSF_FRAMETYPE_ARDUPILOT
    if (command == 0x80 or command == 0x7F)  and data ~= nil then
      -- actual payload starts at data[2]
      if #data >= 7 and data[1] == 0xF0 then
        local app_id = bit32.lshift(data[3],8) + data[2]
        local value =  bit32.lshift(data[7],24) + bit32.lshift(data[6],16) + bit32.lshift(data[5],8) + data[4]
        return 0x00, 0x10, app_id, value
      elseif #data > 4 and data[1] == 0xF1 then
        -- minimum text messages of 1 char
        local severity = data[2]
        -- copy the terminator as well
        for i=3,#data
        do
          msgBuffer = msgBuffer .. string.char(data[i])
          -- hash support
          updateHash(data[i])
        end
        pushMessage(severity, msgBuffer)
        -- hash audio support
        playHash()
        -- hash reset
        resetHash()
        msgBuffer = nil
        doGarbageCollect()
        msgBuffer = ""
      elseif #data >= 8 and data[1] == 0xF2 then
        -- passthrough array
        local app_id, value
        for i=0,math.min(data[2]-1, 9)
        do
          app_id = bit32.lshift(data[4+(6*i)],8) + data[3+(6*i)]
          value =  bit32.lshift(data[8+(6*i)],24) + bit32.lshift(data[7+(6*i)],16) + bit32.lshift(data[6+(6*i)],8) + data[5+(6*i)]
          --pushMessage(7,string.format("CRSF:%d - %04X:%08X",i, app_id, value))
          processTelemetry(app_id, value, now)
        end
        noTelemetryData = 0
        hideNoTelemetry = true
      end
    end
    return nil, nil ,nil ,nil
end


local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end

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
    c1 = math.floor( ((cell1maxFC*0.1) / 4.36) + 1)
  end

  if conf.cell2Count ~= nil and conf.cell2Count > 0 then
    c2 = conf.cell2Count
  elseif batt2sources.vs == true and cell2count > 1 then
    c2 = cell2count
  else
    c2 = math.floor(((cell2maxFC*0.1)/4.36) + 1)
  end

  return c1,c2
end

-- gets the voltage based on source and min value, battId = [1|2]
local function getMinVoltageBySource(source, cell, cellFC, battId)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > 4.36*2 or cellFC > 4.36*2 then
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
  local cellResult = battIdx == 1 and getValue("Cels") or getValue("Cel2")
  if type(cellResult) == "table" then
    cellMin = 4.36
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
  minmaxValues[1] = calcMinValue(cell1sumFC,minmaxValues[1])
  minmaxValues[2] = calcMinValue(cell2sumFC,minmaxValues[2])
  -- cell flvss
  minmaxValues[3] = calcMinValue(cell1min,minmaxValues[3])
  minmaxValues[4] = calcMinValue(cell2min,minmaxValues[4])
  -- batt flvss
  minmaxValues[5] = calcMinValue(cell1sum,minmaxValues[5])
  minmaxValues[6] = calcMinValue(cell2sum,minmaxValues[6])
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

  battery[1+1] = getMinVoltageBySource(status.battsource, cell1min, cell1sumFC/count1, 1)*100 --cel1m
  battery[1+2] = getMinVoltageBySource(status.battsource, cell2min, cell2sumFC/count2, 2)*100 --cel2m

  battery[4+1] = getMinVoltageBySource(status.battsource, cell1sum, cell1sumFC, 1)*10 --batt1
  battery[4+2] = getMinVoltageBySource(status.battsource, cell2sum, cell2sumFC, 2)*10 --batt2

  battery[7+1] = telemetry.batt1current --curr1
  battery[7+2] = telemetry.batt2current --curr2

  battery[10+1] = telemetry.batt1mah --mah1
  battery[10+2] = telemetry.batt2mah --mah2

  battery[13+1] = getBatt1Capacity() --cap1
  battery[13+2] = getBatt2Capacity() --cap2

  --[[
   4 cases here
   1) parallel => all values depend on both batteries
   2) other1 => all values depend on battery 1
   3) other2 => all values depend on battery 2
   4) series => celm(vs) and vbatt(vs) depend on both batteries, all other values on PM battery 1 (this is not supported: 1 PM + 2xFLVSS)
  --]]
  if (conf.battConf == 1) then
    battery[1] = getNonZeroMin(battery[2], battery[3])
    battery[4] = getNonZeroMin(battery[5],battery[6])
    battery[7] = telemetry.batt1current + telemetry.batt2current
    battery[10] = telemetry.batt1mah + telemetry.batt2mah
    battery[13] = getBatt2Capacity() + getBatt1Capacity()
  elseif (conf.battConf == 2) then
    battery[1] = getNonZeroMin(battery[2], battery[3])
    battery[4] = battery[5] + battery[6]
    battery[7] = telemetry.batt1current
    battery[10] = telemetry.batt1mah
    battery[13] = getBatt1Capacity()
  elseif (conf.battConf == 3) then
    battery[1] = battery[2]
    battery[4] = battery[5]
    battery[7] = telemetry.batt1current
    battery[10] = telemetry.batt1mah
    battery[13] = getBatt1Capacity()
  else
    battery[1] = battery[3]
    battery[4] = battery[6]
    battery[7] = telemetry.batt2current
    battery[10] = telemetry.batt2mah
    battery[13] = getBatt2Capacity()
  end

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
    end
  end

  -- aggregate value
  minmaxValues[7] = math.max(battery[7], minmaxValues[7])
  -- indipendent values
  minmaxValues[8] = math.max(telemetry.batt1current, minmaxValues[8])
  minmaxValues[9] = math.max(telemetry.batt2current, minmaxValues[9])
  --print("luaDebug: CURR",battery[7],minmaxValues[7])
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
  if model.getTimer(2).value < status.flightTime then
    if telemetry.statusArmed == 0 then
      reset()
    else
      model.setTimer(2,{value=status.flightTime})
      pushMessage(4,"Reset ignored while armed")
    end
  end
  -- update local variable with timer 3 value
  status.flightTime = model.getTimer(2).value
end

local function setSensorValues()
  if not telemetryEnabled() then
    return
  end
  -- CRSF
  if not conf.enableCRSF then
    setTelemetryValue(0x060F, 0, 0, battery[16], 13 , 0 , "Fuel")
    setTelemetryValue(0x020F, 0, 0, battery[7], 2 , 1 , "CURR")
    setTelemetryValue(0x084F, 0, 0, math.floor(telemetry.yaw), 20 , 0 , "Hdg")
    setTelemetryValue(0x010F, 0, 0, telemetry.homeAlt*10, 9 , 1 , "Alt")
    setTelemetryValue(0x083F, 0, 0, telemetry.hSpeed*0.1, 4 , 0 , "GSpd")
  end
  setTelemetryValue(0x021F, 0, 0, battery[4]*10, 1 , 2 , "VFAS")
  setTelemetryValue(0x011F, 0, 0, telemetry.vSpeed, 5 , 1 , "VSpd")
  setTelemetryValue(0x082F, 0, 0, math.floor(telemetry.gpsAlt*0.1), 9 , 0 , "GAlt")
  setTelemetryValue(0x041F, 0, 0, telemetry.imuTemp, 11 , 0 , "IMUt")
  setTelemetryValue(0x060F, 0, 1, telemetry.statusArmed*100, 0 , 0 , "ARM")

  setTelemetryValue(0x050E, 0, 0, telemetry.rpm1, 18 , 0 , "RPM0")
  setTelemetryValue(0x050F, 0, 0, telemetry.rpm2, 18 , 0 , "RPM1")
  --setTelemetryValue(0x070F, 0, 0, telemetry.roll, 20 , 0 , "ROLL")
  --setTelemetryValue(0x071F, 0, 0, telemetry.pitch, 20 , 0 , "PTCH")
  --setTelemetryValue(0x0400, 0, 0, telemetry.flightMode, 0 , 0 , "FM")
end

local function drawAllMessages()
  for i=0,#messages do
    lcd.drawText(1,1+7*i, messages[(messageRow + i) % (#messages+1)],SMLSIZE)
  end
end
---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms except battery alerts
  if status.timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0, 0, false, 0}
    elseif alarms[idx][4] == 1 then
      alarms[idx] = { false, 0, true, 1, 0, false, 0}
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
  --
  if alarms[idx][4] == 2 then
    if status.flightTime > 0 and math.floor(status.flightTime) %  delay == 0 then
      if alarms[idx][1] == false then
        alarms[idx][1] = true
        playSound(sound)
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
      --
      if alarms[idx][6] == true and alarms[idx][1] == false then
        playSound(sound)
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
      frame = doLibrary(conf.enablePX4Modes and "copter_px4" or "copter")
    elseif frameTypes[telemetry.frameType] == "p" then
      frame = doLibrary(conf.enablePX4Modes and "plane_px4" or "plane")
    elseif frameTypes[telemetry.frameType] == "r" or frameTypes[telemetry.frameType] == "b" then
      frame = doLibrary("rover")
    elseif frameTypes[telemetry.frameType] == "a" then
      frame = doLibrary("blimp")
    end
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
  if value ~= transitions[idx][1] then
    -- value has changed
    transitions[idx][1] = value
    transitions[idx][2] = getTime()
    transitions[idx][3] = false
    -- status: RESET
    return false
  end
  if transitions[idx][3] == false and (getTime() - transitions[idx][2]) >= transitions[idx][4] then
    -- enough time has passed after RESET
    transitions[idx][3] = true
    -- status: FIRE
    return true;
  end
end

local function checkEvents()
  loadFlightModes()
  local alt = status.terrainEnabled == 1 and telemetry.heightAboveTerrain or telemetry.homeAlt
  checkAlarm(conf.minAltitudeAlert,alt,1,-1,"minalt",conf.repeatAlertsPeriod)
  checkAlarm(conf.maxAltitudeAlert,alt,2,1,"maxalt",conf.repeatAlertsPeriod)
  checkAlarm(conf.maxDistanceAlert,telemetry.homeDist,3,1,"maxdist",conf.repeatAlertsPeriod)
  checkAlarm(1,2*telemetry.ekfFailsafe,4,1,"ekf",conf.repeatAlertsPeriod)
  checkAlarm(1,2*telemetry.battFailsafe,5,1,"lowbat",conf.repeatAlertsPeriod)
  checkAlarm(math.floor(conf.timerAlert),status.flightTime,6,1,"timealert",math.floor(conf.timerAlert))
  checkAlarm(1,2*telemetry.failsafe,9,1,"failsafe",conf.repeatAlertsPeriod)
  checkAlarm(1,2*telemetry.fenceBreached,10,1,"fencebreach",conf.repeatAlertsPeriod)
  checkAlarm(1,2*telemetry.terrainUnhealthy,11,1,"terrainko",conf.repeatAlertsPeriod)
  if battery[13] > 0 then
    batLevel = (1 - battery[10]/battery[13])*100
  else
    batLevel = 99
  end

  for l=0,12 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    local level = tonumber(string.sub("00051015202530405060708090",l*2+1,l*2+2))
    if batLevel <= level + 1 and l < lastBattLevel then
      lastBattLevel = l
      playSound("bat"..level)
      break
    end
  end

  if telemetry.statusArmed ~= lastStatusArmed then
    if telemetry.statusArmed == 1 then
      playSound("armed")
    else
      playSound("disarmed")
    end
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
  if frame.flightModes ~= nil and checkTransition(1,telemetry.flightMode) then
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
end

local function checkCellVoltage()
  if battery[1] <= 0 then
    return
  end
  -- check alarms
  checkAlarm(conf.battAlertLevel1,battery[1],7,-1,"batalert1",conf.repeatAlertsPeriod)
  checkAlarm(conf.battAlertLevel2,battery[1],8,-1,"batalert2",conf.repeatAlertsPeriod)

  if status.battAlertLevel1 == false then status.battAlertLevel1 = alarms[7][1] end
  if status.battAlertLevel2 == false then status.battAlertLevel2 = alarms[8][1] end
end
--[[
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
--]]

local travelLat = nil
local travelLon = nil

local function updateTotalDist(now)
  if telemetry.armingStatus == 0 then
    lastUpdateTotDist = getTime()
    return
  end
  if telemetry.lat ~= nil and telemetry.lon ~= nil then
    if travelLat == nil or travelLon == nil then
      travelLat = telemetry.lat
      travelLon = telemetry.lon
      lastUpdateTotDist = now
    end

    if now - lastUpdateTotDist > 50 then
      local travelDist = haversine(telemetry.lat, telemetry.lon, travelLat, travelLon)
      -- discard sampling errors
      if travelDist < 10000 then
        telemetry.totalDist = telemetry.totalDist + travelDist
      end
      travelLat = telemetry.lat
      travelLon = telemetry.lon
      lastUpdateTotDist = now
    end
  end
end

--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
local bgclock = 0
-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
  local now = getTime()

  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,7
  do
    local success,sensor_id,frame_id,data_id,value = pcall(telemetryPop)

    if success and frame_id == 0x10 then
      processTelemetry(data_id,value,now)
      noTelemetryData = 0
      hideNoTelemetry = true
    end
  end
  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
    setSensorValues()
    updateTotalDist(now)
  end

  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    calcBattery()
    calcFlightTime()
    checkEvents()
    checkLandingStatus()
    checkCellVoltage()


    if conf.enableCRSF then
      -- apply same algo used by ardupilot to estimate a 0-100 rssi value
      -- rssi = roundf((1.0f - (rssi_dbm - 50.0f) / 70.0f) * 255.0f);
      local rssi_dbm = math.abs(getValue("1RSS"))
      if getValue("ANT") ~= 0 then
        math.abs(getValue("2RSS"))
      end
      rssiCRSF = string.format("%d/%d", math.min(100, math.floor(0.5 + ((1-(rssi_dbm - 50)/70)*100))), getValue("RFMD"))
   end

    -- if we do not see terrain data for more than 5 sec we assume TERRAIN_ENABLE = 0
    if status.terrainEnabled == 1 and (now - status.terrainLastData) > 500 then
      status.terrainEnabled = 0
      telemetry.terrainUnhealthy = 0
    end

    bgclock=0
  end
  -- blinking support
  if (now - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = now
  end
  bgclock = bgclock+1
  doGarbageCollect()
end

local function checkKeyEvent(event, keys)
  for i=1,#keys do
    if event == keys[i] then
      return true
    end
  end
  return false
end

local function run(event)
  lcd.clear()



  if showMessages then
    ---------------------
    -- MESSAGES
    ---------------------
    drawAllMessages()

    if checkKeyEvent(event, {EVT_MINUS_BREAK, EVT_ROT_LEFT, 35, EVT_EXIT_BREAK, 33}) then
      showMessages = false
    elseif checkKeyEvent(event, {EVT_ENTER_BREAK, 34, EVT_VIRTUAL_ENTER}) then
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
      doGarbageCollect()
    elseif checkKeyEvent(event, {EVT_PLUS_BREAK, EVT_ROT_RIGHT, 36}) then
      showMessages = false
    end
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    -- top bars
    lcd.drawFilledRectangle(0,0, 212, 7, SOLID+FORCE)
    -- bottom bar
    lcd.drawFilledRectangle(0,56, 212, 8, SOLID+FORCE)

    if menuLib == nil and loadCycle == 4 then
      menuLib = doLibrary(menuLibFile)
      if menuLib ~= nil then
        menuLib.loadConfig(conf)
        doGarbageCollect()
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
      doGarbageCollect()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if checkKeyEvent(event, {EVT_MENU_BREAK, EVT_VIRTUAL_MENU}) then
      status.showMinMaxValues = not status.showMinMaxValues
    end

    if status.showDualBattery == true and (checkKeyEvent(event, {EVT_EXIT_BREAK,33})) then
      status.showDualBattery = false
    end

    if drawLib == nil and loadCycle == 0 then
      -- load draw library
      drawLib = doLibrary(drawLibFile)
      doGarbageCollect()
    end

      -- top bars
    lcd.drawFilledRectangle(0,0, 212, 7, FORCE)

    if showAltView then
      if altView == nil and loadCycle == 2 then
        -- load ALTVIEW
        altView = doLibrary(conf.altView)
        doGarbageCollect()
      end

      if drawLib ~= nil and altView ~= nil then
        altView.drawView(drawLib,conf,telemetry,status,battery,(batt2sources.fc or batt2sources.vs) and 0 or 1,getMaxValue,gpsStatuses)
      end

      if checkKeyEvent(event, {EVT_EXIT_BREAK, 33}) then
        showMessages = false
        showAltView = false

        clearTable(altView)
        altView = nil
        doGarbageCollect()
      elseif checkKeyEvent(event, {EVT_PLUS_BREAK, EVT_ROT_RIGHT, 36}) then
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
            rightPanel.drawPane(152,drawLib,conf,telemetry,status,battery,0,getMaxValue,gpsStatuses) -- 0=aggregate view
            lcd.drawText(152-5, 0, "2B", SMLSIZE+INVERS)
          else
            -- dual battery:battery 1 right pane
            rightPanel.drawPane(152,drawLib,conf,telemetry,status,battery,1,getMaxValue,gpsStatuses) -- 1=battery 1
            -- dual battery:battery 2 left pane
            rightPanel.drawPane(1,drawLib,conf,telemetry,status,battery,2,getMaxValue,gpsStatuses) -- 2=battery 2
          end
        else
          -- battery 1 right pane in single battery mode
          rightPanel.drawPane(152,drawLib,conf,telemetry,status,battery,1,getMaxValue,gpsStatuses) -- 1=battery 1
        end
        -- left pane info when not in dual battery mode
        if status.showDualBattery == false then
          leftPanel.drawPane(1,drawLib,conf,telemetry,status,battery,0,getMaxValue,gpsStatuses) -- 0=aggregate view
        end

        centerPanel.drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)

        drawLib.drawGrid()
        drawLib.drawRArrow(133,47,7,telemetry.homeAngle - telemetry.yaw,1)
        drawLib.drawFailSafe(status.showDualBattery,telemetry.ekfFailsafe,telemetry.battFailsafe,telemetry.failsafe)
      end
    end
    -- bottom bar
    lcd.drawFilledRectangle(0,56, 212, 8, FORCE)

    if drawLib ~= nil then
      drawLib.drawTopBar(getFlightMode(), telemetry.simpleMode, status.flightTime, telemetryEnabled, conf.enableCRSF and rssiCRSF or getRSSI())
      drawLib.drawBottomBar(statusBarMsg, lastMsgTime)
      drawLib.drawNoTelemetry(telemetryEnabled, hideNoTelemetry)
    end

    -- event handler
    if checkKeyEvent(event, {EVT_PLUS_BREAK, EVT_ROT_RIGHT, 36, EVT_VIRTUAL_NEXT}) then
      ---------------------
      -- SHOW MESSAGES
      ---------------------
      showMessages = true
    elseif checkKeyEvent(event, {EVT_MENU_LONG, 128, EVT_VIRTUAL_MENU_LONG}) then
      ---------------------
      -- SHOW CONFIG MENU
      ---------------------
      clearTable(drawLib)
      clearTable(altView)
      unloadPanels()
      altView = nil
      drawLib = nil
      doGarbageCollect()
      showConfigMenu = true
    end
  end

  if not telemetryEnabled() and blinkon then
    lcd.drawRectangle(0,0,212,LCD_H,showMessages and SOLID or ERASE)
  end
  loadCycle=(loadCycle+1)%8
  doGarbageCollect()
end

local function init()
-- initialize flight timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
  -- load menu library
  menuLib = doLibrary(menuLibFile)
  menuLib.loadConfig(conf)
  doGarbageCollect()
  -- ok configuration loaded
  status.battsource = conf.defaultBattSource
  -- CRSF or SPORT?
  telemetryPop = sportTelemetryPop
  if conf.enableCRSF == true then
    telemetryPop = crossfirePop
  end
  -- configuration loaded, releasing menu library memory
  clearTable(menuLib)
  menuLib = nil

  pushMessage(7,"Yaapu 2.1.0-dev".." ("..'6cf4cbc'..")")
  doGarbageCollect()
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}

