--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Taranis X9D+ and QX7+ radios
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
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
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
---------------------
-- GLOBAL DEFINES
---------------------
--#define X9
--#define
-- always use loadscript() instead of loadfile()
-- force a loadscript() on init() to compile all .lua in .luac
--#define COMPILE
---------------------
-- VERSION
---------------------
---------------------
-- FEATURES
---------------------
--#define BATTMAH3DEC
-- enable altitude/distance monitor and vocal alert (experimental)
--#define MONITOR
-- show incoming DIY packet rates
--#define TELEMETRY_STATS
-- enable synthetic vspeed when ekf is disabled
--#define SYNTHVSPEED
-- enable telemetry reset on timer 3 reset
-- always calculate FNV hash and play sound msg_<hash>.wav
-- enable telemetry logging menu option
--#define LOGTELEMETRY
-- enable max HDOP alert
--#define HDOP_ALARM
-- enable support for custom background functions
--#define CUSTOM_BG_CALL
-- enable alert window for no telemetry
--#define NOTELEM_ALERT
-- enable popups for no telemetry data
--#define NOTELEM_POPUP
-- enable blinking rectangle on no telemetry
---------------------
-- DEBUG
---------------------
--#define DEBUG
--#define DEBUGEVT
--#define DEV
--#define MEMDEBUG
-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
---------------------
-- TESTMODE
---------------------
-- enable script testing via radio sticks
--#define TESTMODE


---------------------
-- SENSORS
---------------------












-- Throttle and RC use RPM sensor IDs





------------------------
-- MIN MAX
------------------------
-- min

------------------------
-- LAYOUT
------------------------











--#define HOMEDIR_X 42




--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- ALARMS
--------------------------------------------------------------------------------
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


-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1 / 1000 or 1 / 1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"



-----------------------
-- HUD AND YAW
-----------------------
-- vertical distance between roll horiz segments

-- vertical distance between roll horiz segments
-----------------------
-- BATTERY
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1



-- X-Lite Support

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------







local frameTypes = {}
-- copter
frameTypes[0]    = "c"
frameTypes[2]    = "c"
frameTypes[3]    = "c"
frameTypes[4]    = "c"
frameTypes[13]   = "c"
frameTypes[14]   = "c"
frameTypes[15]   = "c"
frameTypes[29]   = "c"
-- plane
frameTypes[1]    = "p"
frameTypes[16]   = "p"
frameTypes[19]   = "p"
frameTypes[20]   = "p"
frameTypes[21]   = "p"
frameTypes[22]   = "p"
frameTypes[23]   = "p"
frameTypes[24]   = "p"
frameTypes[25]   = "p"
frameTypes[28]   = "p"
-- rover
frameTypes[10]   = "r"
-- boat
frameTypes[11]   = "b"


local frame = {}
local frameType = nil

local soundFileBasePath = "/SOUNDS/yaapu0"

local gpsStatuses = {
  [0] = "GPS",
  [1] = "Lock",
  [2] = "2D",
  [3] = "3D",
  [4] = "DG",
  [5] = "RT",
  [6] = "RT",
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
local battery = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
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
status.flightTime = 0   -- updated from model timer 3
status.timerRunning = 0 -- triggered by landcomplete from AP
status.showMinMaxValues = false

-- 00 05 10 15 20 25 30 40 50 60 70 80 90
-- MIN MAX
local minmaxValues = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
-- LIBRARY LOADING
local libBasePath = "/SCRIPTS/TELEMETRY/yaapu/"
local menuLibFile = "menu7"
local drawLibFile = "draw7"

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
--]] -------------------------
-- alarms
-------------------------
local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}
  { false, 0, false, 0, 0, false, 0 }, --MIN_ALT
  { false, 0, true,  1, 0, false, 0 }, --MAX_ALT
  { false, 0, true,  1, 0, false, 0 }, --15
  { false, 0, true,  1, 0, false, 0 }, --FS_EKF
  { false, 0, true,  1, 0, false, 0 }, --FS_BAT
  { false, 0, true,  2, 0, false, 0 }, --FLIGTH_TIME
  { false, 0, false, 3, 4, false, 0 }, --BATT L1
  { false, 0, false, 4, 4, false, 0 }, --BATT L2
}

-------------------------
-- value transitions
-------------------------
local transitions = {
  --{ last_value, last_changed, transition_done, delay }
  { 0, 0, false, 30 }, -- flightmode
}


-------------------------
-- message hash support, uses 312 bytes
-------------------------
local shortHashes = {
  -- 16 bytes hashes, requires 88 bytes
  { 554623408 },        -- "554623408.wav", "Takeoff complete"
  { 3025044912 },       -- "3025044912.wav", "SmartRTL deactiv"
  { 3956583920 },       -- "3956583920.wav", "EKF2 IMU0 is usi"
  { 1309405592 },       -- "1309405592.wav", "EKF3 IMU0 is usi"
  { 4091124880, true }, -- "4091124880.wav", "Reached command "
  { 3311875476, true }, -- "3311875476.wav", "Reached waypoint"
  { 1997782032, true }, -- "1997782032.wav", "Passed waypoint "
}

local shortHash = nil
local parseShortHash = false
local hashByteIndex = 0
local hash = 2166136261


local showMessages = false
local showConfigMenu = false
local showAltView = false
local loadCycle = 0

-----------------------------
-- clears the loaded table
-- and recovers memory
-----------------------------
local function clearTable(t)
  if type(t) == "table" then
    for i, v in pairs(t) do
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
end

local function doLibrary(filename)
  local success, f = pcall(loadScript, libBasePath .. filename .. ".lua")
  if success then
    local ret = f()
    collectgarbage()
    collectgarbage()
    return ret
  else
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
  if centerPanel == nil and loadCycle == 4 then
    centerPanel = doLibrary(conf.centerPanel)
  end

  if rightPanel == nil and loadCycle == 6 then
    rightPanel = doLibrary(conf.rightPanel)
  end

  if leftPanel == nil and loadCycle == 2 then
    leftPanel = doLibrary(conf.leftPanel)
  end

  collectgarbage()
  collectgarbage()
end

-- prevent same file from beeing played too fast
local lastSoundTime = 0

local function playSound(soundFile, skipHaptic)
  if conf.enableHaptic and skipHaptic == nil then
    playHaptic(12, 0)
  end
  if conf.disableAllSounds then
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

  playFile(soundFileBasePath .. "/" .. conf.language .. "/" .. soundFile .. ".wav")
end

----------------------------------------------
-- sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
local function playFlightMode(flightMode)
  if conf.enableHaptic then
    playHaptic(12, 0)
  end
  if conf.disableAllSounds then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      playFile(soundFileBasePath ..
        "/" .. conf.language ..
        "/" .. string.lower(frame.flightModes[flightMode]) .. (frameType == "r" and "_r.wav" or ".wav"))
    end
  end
end

local function formatMessage(severity, msg)
  local shortMsg = msg
  if lastMessageCount > 1 then
    if #msg > 16 then
      shortMsg = string.sub(msg, 1, 16)
      collectgarbage()
    end
    local pmsg = string.format("%d:%s %s (x%d)", messageCount, mavSeverity[severity], shortMsg, lastMessageCount)
    if severity == 6 then
      if #msg > (16 + 8) then
        shortMsg = string.sub(msg, 1, 16 + 8)
        collectgarbage()
      end
      pmsg = string.format("(x%d) %s", lastMessageCount, msg)
    end
    msg = nil
    collectgarbage()
    return pmsg
  else
    if #msg > 23 then
      shortMsg = string.sub(msg, 1, 23)
      collectgarbage()
    end
    local pmsg = string.format("%d:%s %s", messageCount, mavSeverity[severity], shortMsg)
    if severity == 6 then
      if #msg > (23 + 8) then
        shortMsg = string.sub(msg, 1, 23 + 8)
        collectgarbage()
      end
      pmsg = string.format("%s", msg)
    end
    msg = nil
    collectgarbage()
    return pmsg
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

local function pushMessage(severity, msg)
  if conf.enableHaptic then
    playHaptic(12, 0)
  end
  if conf.disableAllSounds == false then
    if (severity < 5 and conf.disableMsgBeep < 3) then
      playSound("../err", true)
    else
      if conf.disableMsgBeep < 2 then
        playSound("../inf", true)
      end
    end
  end
  if msg == lastMessage then
    lastMessageCount = lastMessageCount + 1
  else
    lastMessageCount = 1
    messageCount = messageCount + 1
  end
  messages[(messageCount - 1) % 9] = formatMessage(severity, msg)
  --print("count=",messageCount,"pos=%",(messageCount-1) % 9,msg,"#messages",#messages)
  lastMessage = msg
  lastMessageSeverity = severity
  collectgarbage()
  collectgarbage()
end

local function startTimer()
  lastTimerStart = getTime() / 100
  model.setTimer(2, { mode = 1 })
end

local function stopTimer()
  model.setTimer(2, { mode = 0 })
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
  minmaxValues = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
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
  resetLib.resetTelemetry(status, telemetry, battery, alarms, transitions)
  -- release resources
  clearTable(resetLib)
  resetLib = nil
  -- recover memory
  collectgarbage()
  collectgarbage()
  -- done
  pushMessage(6, "Telemetry reset done.")
  playSound("yaapu")
end


local function processTelemetry(telemetry, DATA_ID, VALUE)
  if DATA_ID == 0x5006 then -- ROLLPITCH
    -- roll [0,1800] ==> [-180,180]
    telemetry.roll = (math.min(bit32.extract(VALUE, 0, 11), 1800) - 900) * 0.2
    -- pitch [0,900] ==> [-90,90]
    telemetry.pitch = (math.min(bit32.extract(VALUE, 11, 10), 900) - 450) * 0.2
    -- #define ATTIANDRNG_RNGFND_OFFSET    21
    -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
    telemetry.range = bit32.extract(VALUE, 22, 10) * (10 ^ bit32.extract(VALUE, 21, 1)) -- cm
  elseif DATA_ID == 0x5005 then                                                         -- VELANDYAW
    telemetry.vSpeed = bit32.extract(VALUE, 1, 7) * (10 ^ bit32.extract(VALUE, 0, 1)) *
        (bit32.extract(VALUE, 8, 1) == 1 and -1 or 1)
    telemetry.hSpeed = bit32.extract(VALUE, 10, 7) * (10 ^ bit32.extract(VALUE, 9, 1))
    telemetry.yaw = bit32.extract(VALUE, 17, 11) * 0.2
  elseif DATA_ID == 0x5001 then -- AP STATUS
    telemetry.flightMode = bit32.extract(VALUE, 0, 5)
    telemetry.simpleMode = bit32.extract(VALUE, 5, 2)
    telemetry.landComplete = bit32.extract(VALUE, 7, 1)
    telemetry.statusArmed = bit32.extract(VALUE, 8, 1)
    telemetry.battFailsafe = bit32.extract(VALUE, 9, 1)
    telemetry.ekfFailsafe = bit32.extract(VALUE, 10, 2)
    -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
    telemetry.imuTemp = bit32.extract(VALUE, 26, 6) + 19 -- C°
  elseif DATA_ID == 0x5002 then                          -- GPS STATUS
    telemetry.numSats = bit32.extract(VALUE, 0, 4)
    -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
    -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
    telemetry.gpsStatus = bit32.extract(VALUE, 4, 2) + bit32.extract(VALUE, 14, 2)
    telemetry.gpsHdopC = bit32.extract(VALUE, 7, 7) *
        (10 ^ bit32.extract(VALUE, 6, 1))              -- dm
    telemetry.gpsAlt = bit32.extract(VALUE, 24, 7) * (10 ^ bit32.extract(VALUE, 22, 2)) *
        (bit32.extract(VALUE, 31, 1) == 1 and -1 or 1) -- dm
  elseif DATA_ID == 0x5003 then                        -- BATT
    telemetry.batt1volt = bit32.extract(VALUE, 0, 9)   -- dV
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell1Count == 12 and telemetry.batt1volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt1volt = 512 + telemetry.batt1volt
    end
    telemetry.batt1current = bit32.extract(VALUE, 10, 7) * (10 ^ bit32.extract(VALUE, 9, 1)) --dA
    telemetry.batt1mah = bit32.extract(VALUE, 17, 15)
  elseif DATA_ID == 0x5008 then                                                              -- BATT2
    telemetry.batt2volt = bit32.extract(VALUE, 0, 9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 + telemetry.batt1volt
    if conf.cell2Count == 12 and telemetry.batt2volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      telemetry.batt2volt = 512 + telemetry.batt2volt
    end
    telemetry.batt2current = bit32.extract(VALUE, 10, 7) * (10 ^ bit32.extract(VALUE, 9, 1))
    telemetry.batt2mah = bit32.extract(VALUE, 17, 15)
  elseif DATA_ID == 0x5004 then -- HOME
    telemetry.homeDist = bit32.extract(VALUE, 2, 10) * (10 ^ bit32.extract(VALUE, 0, 2))
    telemetry.homeAlt = bit32.extract(VALUE, 14, 10) * (10 ^ bit32.extract(VALUE, 12, 2)) * 0.1 *
        (bit32.extract(VALUE, 24, 1) == 1 and -1 or 1) --m
    telemetry.homeAngle = bit32.extract(VALUE, 25, 7) * 3
  elseif DATA_ID == 0x5000 then                        -- MESSAGES
    if VALUE ~= lastMsgValue then
      lastMsgValue = VALUE
      local c
      local msgEnd = false
      for i = 3, 0, -1
      do
        c = bit32.extract(VALUE, i * 8, 7)
        if c ~= 0 then
          msgBuffer = msgBuffer .. string.char(c)
          collectgarbage()
          collectgarbage()
          hash = bit32.bxor(hash, c)
          hash = (hash * 16777619) % 2 ^ 32
          hashByteIndex = hashByteIndex + 1
          -- check if this hash matches any 16bytes prefix hash
          if hashByteIndex == 16 then
            for i = 1, #shortHashes
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
        else
          msgEnd = true;
          break;
        end
      end
      if msgEnd then
        -- push and display message
        local severity = (bit32.extract(VALUE, 7, 1) * 1) + (bit32.extract(VALUE, 15, 1) * 2) +
            (bit32.extract(VALUE, 23, 1) * 4)
        pushMessage(severity, msgBuffer)
        -- play shortHash if found otherwise "try" the full hash
        -- if it does not exist OpenTX will gracefully ignore it
        playSound(tostring(shortHash == nil and hash or shortHash), true)
        -- if required parse parameter and play it!
        if parseShortHash then
          local param = string.match(msgBuffer, ".*#(%d+).*")
          collectgarbage()
          collectgarbage()
          if param ~= nil then
            playNumber(tonumber(param), 0)
            collectgarbage()
            collectgarbage()
          end
        end
        -- reset hash for next string
        parseShortHash = false
        shortHash = nil
        hash = 2166136261
        hashByteIndex = 0
        msgBuffer = nil
        -- recover memory
        collectgarbage()
        collectgarbage()
        msgBuffer = ""
      end
    end
  elseif DATA_ID == 0x5007 then -- PARAMS
    local paramId = bit32.extract(VALUE, 24, 4)
    local paramValue = bit32.extract(VALUE, 0, 24)
    if paramId == 1 then
      telemetry.frameType = paramValue
    elseif paramId == 4 then
      telemetry.batt1Capacity = paramValue
    elseif paramId == 5 then
      telemetry.batt2Capacity = paramValue
    end
  elseif DATA_ID == 0x5009 then                        -- WAYPOINTS @1Hz
    telemetry.wpNumber = bit32.extract(VALUE, 0, 10)   -- wp index
    telemetry.wpDistance = bit32.extract(VALUE, 12, 10) *
        (10 ^ bit32.extract(VALUE, 10, 2))             -- meters
    telemetry.wpXTError = bit32.extract(VALUE, 23, 4) * (10 ^ bit32.extract(VALUE, 22, 1)) *
        (bit32.extract(VALUE, 27, 1) == 1 and -1 or 1) -- meters
    telemetry.wpBearing = bit32.extract(VALUE, 29, 3)  -- offset from cog with 45° resolution
    --[[
  elseif DATA_ID == 0x50F1 then -- RC CHANNELS
    -- channels 1 - 32
    local offset = bit32.extract(VALUE,0,4) * 4
    rcchannels[1 + offset] = 100 * (bit32.extract(VALUE,4,6)/63) * (bit32.extract(VALUE,10,1) == 1 and -1 or 1)
    rcchannels[2 + offset] = 100 * (bit32.extract(VALUE,11,6)/63) * (bit32.extract(VALUE,17,1) == 1 and -1 or 1)
    rcchannels[3 + offset] = 100 * (bit32.extract(VALUE,18,6)/63) * (bit32.extract(VALUE,24,1) == 1 and -1 or 1)
    rcchannels[4 + offset] = 100 * (bit32.extract(VALUE,25,6)/63) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1)
--]]
  elseif DATA_ID == 0x50F2 then                                                         -- VFR
    telemetry.airspeed = bit32.extract(VALUE, 1, 7) * (10 ^ bit32.extract(VALUE, 0, 1)) -- dm/s
    telemetry.throttle = bit32.extract(VALUE, 8, 7)
    telemetry.baroAlt = bit32.extract(VALUE, 17, 10) * (10 ^ bit32.extract(VALUE, 15, 2)) * 0.1 *
        (bit32.extract(VALUE, 27, 1) == 1 and -1 or 1)
  end
end

local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end

local function getMaxValue(value, idx)
  minmaxValues[idx] = math.max(value, minmaxValues[idx])
  return status.showMinMaxValues and minmaxValues[idx] or value
end

local function calcMinValue(value, min)
  return min == 0 and value or math.min(value, min)
end

-- returns the actual minimun only if both are > 0
local function getNonZeroMin(v1, v2)
  return v1 == 0 and v2 or (v2 == 0 and v1 or math.min(v1, v2))
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
    c1 = math.floor(((cell1maxFC * 0.1) / 4.36) + 1)
  end

  if conf.cell2Count ~= nil and conf.cell2Count > 0 then
    c2 = conf.cell2Count
  elseif batt2sources.vs == true and cell2count > 1 then
    c2 = cell2count
  else
    c2 = math.floor(((cell2maxFC * 0.1) / 4.36) + 1)
  end

  return c1, c2
end

-- gets the voltage based on source and min value, battId = [1|2]
local function getMinVoltageBySource(source, cell, cellFC, battId)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > 4.36 * 2 or cellFC > 4.36 * 2 then
    offset = 2
  end
  --
  if source == "vs" then
    return status.showMinMaxValues == true and minmaxValues[2 + offset + battId] or cell
  elseif source == "fc" then
    -- FC only tracks batt1 and batt2 no cell voltage tracking
    local minmax = (offset == 2 and minmaxValues[battId] or minmaxValues[battId] / calcCellCount())
    return status.showMinMaxValues == true and minmax or cellFC
  end
  --
  return 0
end

local function getBatt1Capacity()
  return conf.battCapOverride1 > 0 and conf.battCapOverride1 * 10 or telemetry.batt1Capacity
end

local function getBatt2Capacity()
  return conf.battCapOverride2 > 0 and conf.battCapOverride2 * 10 or telemetry.batt2Capacity
end

local function calcFLVSSBatt(battIdx)
  local cellMin, cellSum, cellCount
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
  return cellMin, cellSum, cellCount, battSources
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
    cell1maxFC = math.max(telemetry.batt1volt, cell1maxFC)
    cell1sumFC = telemetry.batt1volt * 0.1
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
    cell2maxFC = math.max(telemetry.batt2volt, cell2maxFC)
    cell2sumFC = telemetry.batt2volt * 0.1
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    batt2sources.fc = true
  else
    batt2sources.fc = false
    cell2sumFC = 0
  end
  -- batt fc
  minmaxValues[1] = calcMinValue(cell1sumFC, minmaxValues[1])
  minmaxValues[2] = calcMinValue(cell2sumFC, minmaxValues[2])
  -- cell flvss
  minmaxValues[3] = calcMinValue(cell1min, minmaxValues[3])
  minmaxValues[4] = calcMinValue(cell2min, minmaxValues[4])
  -- batt flvss
  minmaxValues[5] = calcMinValue(cell1sum, minmaxValues[5])
  minmaxValues[6] = calcMinValue(cell2sum, minmaxValues[6])
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

  local count1, count2 = calcCellCount()
  -- 3 cases here
  -- 1) parallel => all values depend on both batteries
  -- 2) other => all values depend on battery 1
  -- 3) serial => celm(vs) and vbatt(vs) depend on both batteries, all other values on PM battery 1 (this is not supported: 1 PM + 2xFLVSS)

  battery[1 + 1] = getMinVoltageBySource(status.battsource, cell1min, cell1sumFC / count1, 1) * 100 --cel1m
  battery[1 + 2] = getMinVoltageBySource(status.battsource, cell2min, cell2sumFC / count2, 2) * 100 --cel2m
  battery[1] = (conf.battConf == 3 and battery[2] or getNonZeroMin(battery[2], battery[3]))

  battery[4 + 1] = getMinVoltageBySource(status.battsource, cell1sum, cell1sumFC, 1) * 10 --batt1
  battery[4 + 2] = getMinVoltageBySource(status.battsource, cell2sum, cell2sumFC, 2) * 10 --batt2
  battery[4] = (conf.battConf == 3 and battery[5] or (conf.battConf == 2 and battery[5] + battery[6] or getNonZeroMin(battery[5], battery[6])))

  battery[7] = getMaxValue(
    (conf.battConf == 3 and telemetry.batt1current or telemetry.batt1current + telemetry.batt2current), 7)
  battery[7 + 1] = getMaxValue(telemetry.batt1current, 8) --curr1
  battery[7 + 2] = getMaxValue(telemetry.batt2current, 9) --curr2

  battery[10] = (conf.battConf == 3 and telemetry.batt1mah or telemetry.batt1mah + telemetry.batt2mah)
  battery[10 + 1] = telemetry.batt1mah --mah1
  battery[10 + 2] = telemetry.batt2mah --mah2

  battery[13] = (conf.battConf == 3 and getBatt1Capacity() or getBatt1Capacity() + getBatt2Capacity())
  battery[13 + 1] = getBatt1Capacity() --cap1
  battery[13 + 2] = getBatt2Capacity() --cap2

  if status.showDualBattery == true and conf.battConf == 1 then
    -- dual parallel battery: do I have also dual current monitor?
    if battery[7 + 1] > 0 and battery[7 + 2] == 0 then
      -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
      battery[7 + 1] = battery[7 + 1] / 2   --curr1
      battery[7 + 2] = battery[7 + 1]       --curr2
      --
      battery[10 + 1] = battery[10 + 1] / 2 --mah1
      battery[10 + 2] = battery[10 + 1]     --mah2
      --
      battery[13 + 1] = battery[13 + 1] / 2 --cap1
      battery[13 + 2] = battery[13 + 1]     --cap2
    end
  end
end

local function checkLandingStatus()
  if (status.timerRunning == 0 and telemetry.landComplete == 1 and lastTimerStart == 0) then
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
      model.setTimer(2, { value = status.flightTime })
      pushMessage(4, "Reset ignored while armed")
    end
  end
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
    battcapacity = getBatt1Capacity() + getBatt2Capacity()
    battmah = telemetry.batt1mah + telemetry.batt2mah
  end
  local perc = 0
  if (battcapacity > 0) then
    perc = math.min(math.max((1 - (battmah / battcapacity)) * 100, 0), 99)
  end

  setTelemetryValue(0x060F, 0, 0, perc, 13, 0, "Fuel")
  setTelemetryValue(0x021F, 0, 0, getNonZeroMin(telemetry.batt1volt, telemetry.batt2volt) * 10, 1, 2, "VFAS")
  setTelemetryValue(0x020F, 0, 0, telemetry.batt1current + telemetry.batt2current, 2, 1, "CURR")
  setTelemetryValue(0x011F, 0, 0, telemetry.vSpeed, 5, 1, "VSpd")
  setTelemetryValue(0x083F, 0, 0, telemetry.hSpeed * 0.1, 4, 0, "GSpd")
  setTelemetryValue(0x010F, 0, 0, telemetry.homeAlt * 10, 9, 1, "Alt")
  setTelemetryValue(0x082F, 0, 0, math.floor(telemetry.gpsAlt * 0.1), 9, 0, "GAlt")
  setTelemetryValue(0x084F, 0, 0, math.floor(telemetry.yaw), 20, 0, "Hdg")
  setTelemetryValue(0x041F, 0, 0, telemetry.imuTemp, 11, 0, "IMUt")
  setTelemetryValue(0x060F, 0, 1, telemetry.statusArmed * 100, 0, 0, "ARM")
end

local function drawAllMessages()
  for i = 0, #messages do
    lcd.drawText(1, 1 + 7 * i, messages[(messageCount + i) % (#messages + 1)], SMLSIZE)
  end
end
---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level, value, idx, sign, sound, delay)
  -- once landed reset all alarms except battery alerts
  if status.timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0, 0, false, 0 }
    elseif alarms[idx][4] == 1 then
      alarms[idx] = { false, 0, true, 1, 0, false, 0 }
    elseif alarms[idx][4] == 2 then
      alarms[idx] = { false, 0, true, 2, 0, false, 0 }
    elseif alarms[idx][4] == 3 then
      alarms[idx] = { false, 0, false, 3, 4, false, 0 }
    elseif alarms[idx][4] == 4 then
      alarms[idx] = { false, 0, false, 4, 4, false, 0 }
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level
  if alarms[idx][3] == false and level > 0 and -1 * sign * value > -1 * sign * level then
    alarms[idx][3] = true
  end
  --
  if alarms[idx][4] == 2 then
    if status.flightTime > 0 and math.floor(status.flightTime) % delay == 0 then
      if alarms[idx][1] == false then
        alarms[idx][1] = true
        playSound(sound)
        playDuration(status.flightTime, (status.flightTime > 3600 and 1 or 0)) -- minutes,seconds
      end
    else
      alarms[idx][1] = false
    end
  else
    if alarms[idx][3] == true then
      if level > 0 and sign * value > sign * level then
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
        -- status:
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
        if alarms[idx][6] == true and status.flightTime ~= alarms[idx][7] and (status.flightTime - alarms[idx][7]) % delay == 0 then
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
      frame = dofile(libBasePath .. (conf.enablePX4Modes and "copter_px4.luac" or "copter.luac"))
    elseif frameTypes[telemetry.frameType] == "p" then
      frame = dofile(libBasePath .. (conf.enablePX4Modes and "plane_px4.luac" or "plane.luac"))
    elseif frameTypes[telemetry.frameType] == "r" then
      frame = dofile(libBasePath .. "rover.luac")
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
local function checkTransition(idx, value)
  if value ~= transitions[idx][1] then
    -- value has changed
    transitions[idx][1] = value
    transitions[idx][2] = getTime()
    transitions[idx][3] = false
    -- status:
    return false
  end
  if transitions[idx][3] == false and (getTime() - transitions[idx][2]) >= transitions[idx][4] then
    -- enough time has passed after
    transitions[idx][3] = true
    -- status: FIRE
    return true;
  end
end


local function checkEvents()
  loadFlightModes()

  checkAlarm(conf.minAltitudeAlert, telemetry.homeAlt, 1, -1, "minalt", conf.repeatAlertsPeriod)
  checkAlarm(conf.maxAltitudeAlert, telemetry.homeAlt, 2, 1, "maxalt", conf.repeatAlertsPeriod)
  checkAlarm(conf.maxDistanceAlert, telemetry.homeDist, 3, 1, "maxdist", conf.repeatAlertsPeriod)
  checkAlarm(1, 2 * telemetry.ekfFailsafe, 4, 1, "ekf", conf.repeatAlertsPeriod)
  checkAlarm(1, 2 * telemetry.battFailsafe, 5, 1, "lowbat", conf.repeatAlertsPeriod)
  checkAlarm(math.floor(conf.timerAlert), status.flightTime, 6, 1, "timealert", math.floor(conf.timerAlert))

  local capacity = getBatt1Capacity()
  local mah = telemetry.batt1mah

  -- only if dual battery has been detected
  if (batt2sources.fc or batt2sources.vs) and conf.battConf == 1 then
    capacity = capacity + getBatt2Capacity()
    mah = mah + telemetry.batt2mah
  end

  if (capacity > 0) then
    batLevel = (1 - (mah / capacity)) * 100
  else
    batLevel = 99
  end

  for l = 0, 12 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    local level = tonumber(string.sub("00051015202530405060708090", l * 2 + 1, l * 2 + 2))
    if batLevel <= level + 1 and l < lastBattLevel then
      lastBattLevel = l
      playSound("bat" .. level)
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
  if frame.flightModes ~= nil and checkTransition(1, telemetry.flightMode) then
    playFlightMode(telemetry.flightMode)
  end

  if telemetry.simpleMode ~= lastSimpleMode then
    if telemetry.simpleMode == 0 then
      playSound(lastSimpleMode == 1 and "simpleoff" or "ssimpleoff")
    else
      playSound(telemetry.simpleMode == 1 and "simpleon" or "ssimpleon")
    end
    lastSimpleMode = telemetry.simpleMode
  end
end

local function checkCellVoltage(celm)
  -- check alarms
  checkAlarm(conf.battAlertLevel1, celm, 7, -1, "batalert1", conf.repeatAlertsPeriod)
  checkAlarm(conf.battAlertLevel2, celm, 8, -1, "batalert2", conf.repeatAlertsPeriod)
  if status.battAlertLevel1 == false then status.battAlertLevel1 = alarms[7][1] end
  if status.battAlertLevel2 == false then status.battAlertLevel2 = alarms[8][1] end
end

local function cycleBatteryInfo()
  if status.showDualBattery == false and (batt2sources.fc or batt2sources.vs) and conf.battConf ~= 2 then
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
  local avgSpeed = (telemetry.hSpeed + lastSpeed) / 2
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
-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
  -- FAST: this runs at 60Hz (every 16ms)
  for i = 1, 3
  do
    local sensor_id, frame_id, data_id, value = sportTelemetryPop()
    if frame_id == 0x10 then
      processTelemetry(telemetry, data_id, value)
      -- update telemetry status
      noTelemetryData = 0
      hideNoTelemetry = true
    end
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
    local count1, count2 = calcCellCount()
    local cellVoltage = 0

    if conf.battConf == 3 then
      -- alarms are based on battery 1
      cellVoltage = 100 * (status.battsource == "vs" and cell1min or cell1sumFC / count1)
    else
      -- alarms are based on battery 1 and battery 2
      cellVoltage = 100 *
          (status.battsource == "vs" and getNonZeroMin(cell1min, cell2min) or getNonZeroMin(cell1sumFC / count1, cell2sumFC / count2))
    end
    --
    checkEvents()
    checkLandingStatus()
    -- no need for alarms if reported voltage is 0
    if cellVoltage > 0 then
      checkCellVoltage(cellVoltage)
    end
    -- aggregate value
    minmaxValues[7] = math.max(
      (conf.battConf == 3 and telemetry.batt1current or telemetry.batt1current + telemetry.batt2current), minmaxValues
      [7])

    -- indipendent values
    minmaxValues[8] = math.max(telemetry.batt1current, minmaxValues[8])
    minmaxValues[9] = math.max(telemetry.batt2current, minmaxValues[9])

    -- update GPS coordinates
    local gpsData = getValue("GPS")

    if type(gpsData) == "table" and gpsData.lat ~= nil and gpsData.lon ~= nil then
      telemetry.gpsLat = math.floor(gpsData.lat * 100000) / 100000
      telemetry.gpsLon = math.floor(gpsData.lon * 100000) / 100000
      collectgarbage()
      collectgarbage()
    end

    bgclock = 0
  end
  -- blinking support
  if (getTime() - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = getTime()
  end
  bgclock = bgclock + 1
  collectgarbage()
  collectgarbage()
end

local function run(event)
  lcd.clear()



  if showMessages then
    ---------------------
    -- MESSAGES
    ---------------------
    drawAllMessages()

    if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == 35 or event == EVT_EXIT_BREAK or event == 33 then
      showMessages = false
    elseif event == EVT_ENTER_BREAK or event == 34 then
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
    elseif event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == 36 then
      showMessages = false
    end
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    -- top bars
    lcd.drawFilledRectangle(0, 0, 128, 7, SOLID + FORCE)
    -- bottom bar
    lcd.drawFilledRectangle(0, 57, 128, 8, SOLID + FORCE)
    if menuLib == nil and loadCycle == 4 then
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
      collectgarbage()
      collectgarbage()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if event == EVT_ENTER_BREAK or event == 34 then
      cycleBatteryInfo()
    end
    if event == EVT_MENU_BREAK or event == 32 then
      status.showMinMaxValues = not status.showMinMaxValues
    end

    if status.showDualBattery == true and (event == EVT_EXIT_BREAK or event == 33) then
      status.showDualBattery = false
    end

    if drawLib == nil and loadCycle == 0 then
      -- load draw library
      drawLib = doLibrary(drawLibFile)
      collectgarbage()
      collectgarbage()
    end
    -- top bars
    lcd.drawFilledRectangle(0, 0, 128, 7, FORCE)
    if showAltView then
      if altView == nil and loadCycle == 2 then
        -- load ALTVIEW
        altView = doLibrary(conf.altView)
        collectgarbage()
        collectgarbage()
      end

      if drawLib ~= nil and altView ~= nil then
        altView.drawView(drawLib, conf, telemetry, status, battery, (batt2sources.fc or batt2sources.vs) and 0 or 1,
          getMaxValue, gpsStatuses)
      end

      if event == EVT_EXIT_BREAK or event == 33 then
        showMessages = false
        showAltView = false

        clearTable(altView)
        altView = nil
        collectgarbage()
        collectgarbage()
      elseif event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == 36 then
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
            rightPanel.drawPane(97, drawLib, conf, telemetry, status, battery, 0, getMaxValue, gpsStatuses) -- 0=aggregate view
            lcd.drawText(32 + 5, LCD_H - 16, "2B", SMLSIZE)
          else
            -- dual battery:battery 1 right pane
            rightPanel.drawPane(97, drawLib, conf, telemetry, status, battery, 1, getMaxValue, gpsStatuses) -- 1=battery 1
            -- dual battery:battery 2 left pane
            rightPanel.drawPane(0, drawLib, conf, telemetry, status, battery, 2, getMaxValue, gpsStatuses)  -- 2=battery 2
          end
        else
          -- battery 1 right pane in single battery mode
          rightPanel.drawPane(97, drawLib, conf, telemetry, status, battery, 1, getMaxValue, gpsStatuses) -- 1=battery 1
        end
        -- left pane info when not in dual battery mode
        if status.showDualBattery == false then
          leftPanel.drawPane(0, drawLib, conf, telemetry, status, battery, 0, getMaxValue, gpsStatuses) -- 0=aggregate view
        end

        centerPanel.drawHud(drawLib, conf, telemetry, status, battery, getMaxValue)
        drawLib.drawGrid()
        drawLib.drawRArrow(82, 48, 7, telemetry.homeAngle - telemetry.yaw, 1)
        drawLib.drawFailSafe(status.showDualBattery, telemetry.ekfFailsafe, telemetry.battFailsafe)
      end
    end
    -- bottom bar
    lcd.drawFilledRectangle(0, 57, 128, 8, FORCE)
    if drawLib ~= nil then
      drawLib.drawTopBar(getFlightMode(), telemetry.simpleMode, status.flightTime, telemetryEnabled)
      drawLib.drawBottomBar(messages[(messageCount + #messages) % (#messages + 1)], lastMsgTime)
      drawLib.drawNoTelemetry(telemetryEnabled, hideNoTelemetry)
    end
    -- event handler
    if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == 36 then
      ---------------------
      -- SHOW MESSAGES
      ---------------------
      showMessages = true
    elseif event == EVT_MENU_LONG or event == 128 then
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
  if not telemetryEnabled() and blinkon then
    lcd.drawRectangle(0, 0, 128, LCD_H, showMessages and SOLID or ERASE)
  end
  loadCycle = (loadCycle + 1) % 8
  collectgarbage()
  collectgarbage()
end

local function init()
  -- initialize flight timer
  model.setTimer(2, { mode = 0 })
  model.setTimer(2, { value = 0 })
  -- load menu library
  menuLib = doLibrary(menuLibFile)
  menuLib.loadConfig(conf)
  collectgarbage()
  collectgarbage()
  -- ok configuration loaded
  status.battsource = conf.defaultBattSource
  -- configuration loaded, releasing menu library memory
  clearTable(menuLib)
  menuLib = nil
  pushMessage(7, "Yaapu X7 1.8.0")
  collectgarbage()
  collectgarbage()
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return { run = run, background = background, init = init }
