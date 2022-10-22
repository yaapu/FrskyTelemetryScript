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
local HUD_H = 130
local HUD_X = (480 - HUD_W)/2
local HUD_Y = 18

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local CRSF_FRAME_CUSTOM_TELEM = 0x80
local CRSF_FRAME_CUSTOM_TELEM_LEGACY = 0x7F
local CRSF_CUSTOM_TELEM_PASSTHROUGH = 0xF0
local CRSF_CUSTOM_TELEM_STATUS_TEXT = 0xF1
local CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY = 0xF2

local utils = {}

local status = nil
local libs = nil

local bitmaskCache = {}
local sources = {}
local passthroughSensor = sport.getSensor({appIdStart=0x800, appIdEnd=0x51FF})

local function loadLib(name)
  local lib = dofile("/scripts/yaaputelemetry/lib/"..name..".lua")
  if lib.init ~= nil then
    lib.init(status, libs)
  end
  return lib
end

function utils.getSourceValue(name)
  local src = sources[name]
  if src == nil then
    src = system.getSource(name)
    sources[name] = src
  end
  return src == nil and 0 or src:value()
end

local function updateHash(c)
  status.hash_a = ( status.hash_a + c ) % 4095
  status.hash_b = ( status.hash_a + status.hash_b ) % 4095

  status.hash = status.hash_b * 4096 + status.hash_a

  status.hashByteIndex = status.hashByteIndex+1
  -- check if this hash matches any 16bytes prefix hash
  if status.hashByteIndex == 16 then
    status.parseShortHash = status.shortHashes[status.hash]
    if status.parseShortHash ~= nil then
      status.shortHash = status.hash
    end
  end
end

local function playHash()
  -- try to play the hash sound file without checking for existence
  local soundfile = tostring(status.shortHash == nil and status.hash or status.shortHash)
  -- print("playHash()", status.msgBuffer, status.hash, soundfile..".wav")
  libs.utils.playSound(soundfile,true)
  -- if required parse parameter and play it!
  if status.parseShortHash == true then
    local param = string.match(status.msgBuffer, ".*#(%d+).*")
    if param ~= nil then
      system.playNumber(tonumber(param))
    end
  end
end

local function resetHash()
  -- reset hash for next string
  status.parseShortHash = false
  status.shortHash = nil
  status.hash = 0
  status.hash_a = 0
  status.hash_b = 0
  status.hashByteIndex = 0
end

function utils.processTelemetry(appId, data, now)
  if appId == 0x5006 then -- ROLLPITCH
    -- roll [0,1800] ==> [-180,180]
    status.telemetry.roll = (math.min(libs.utils.bitExtract(data,0,11),1800) - 900) * 0.2
    -- pitch [0,900] ==> [-90,90]
    status.telemetry.pitch = (math.min(libs.utils.bitExtract(data,11,10),900) - 450) * 0.2
    -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
    status.telemetry.range = libs.utils.bitExtract(data,22,10) * (10^libs.utils.bitExtract(data,21,1)) -- cm
  elseif appId == 0x5005 then -- VELANDYAW
    status.telemetry.vSpeed = libs.utils.bitExtract(data,1,7) * (10^libs.utils.bitExtract(data,0,1)) * (libs.utils.bitExtract(data,8,1) == 1 and -1 or 1)-- dm/s
    status.telemetry.yaw = libs.utils.bitExtract(data,17,11) * 0.2
    -- once detected it's sticky
    if libs.utils.bitExtract(data,28,1) == 1 then
      status.telemetry.airspeed = libs.utils.bitExtract(data,10,7) * (10^libs.utils.bitExtract(data,9,1)) -- dm/s
    else
      status.telemetry.hSpeed = libs.utils.bitExtract(data,10,7) * (10^libs.utils.bitExtract(data,9,1)) -- dm/s
    end
    if status.airspeedEnabled == 0 then
      status.airspeedEnabled = libs.utils.bitExtract(data,28,1)
    end
  elseif appId == 0x5001 then -- AP STATUS
    status.telemetry.flightMode = libs.utils.bitExtract(data,0,5)
    status.telemetry.simpleMode = libs.utils.bitExtract(data,5,2)
    status.telemetry.landComplete = libs.utils.bitExtract(data,7,1)
    status.telemetry.statusArmed = libs.utils.bitExtract(data,8,1)
    status.telemetry.battFailsafe = libs.utils.bitExtract(data,9,1)
    status.telemetry.ekfFailsafe = libs.utils.bitExtract(data,10,2)
    status.telemetry.failsafe = libs.utils.bitExtract(data,12,1)
    status.telemetry.fencePresent = libs.utils.bitExtract(data,13,1)
    status.telemetry.fenceBreached = status.telemetry.fencePresent == 1 and libs.utils.bitExtract(data,14,1) or 0 -- ignore if fence is disabled
    status.telemetry.throttle = math.floor(0.5 + (libs.utils.bitExtract(data,19,6) * (libs.utils.bitExtract(data,25,1) == 1 and -1 or 1) * 1.58)) -- signed throttle [-63,63] -> [-100,100]
    -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
    status.telemetry.imuTemp = libs.utils.bitExtract(data,26,6) + 19 -- C°
  elseif appId == 0x5002 then -- GPS STATUS
    status.telemetry.numSats = libs.utils.bitExtract(data,0,4)
    -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
    -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
    status.telemetry.gpsStatus = libs.utils.bitExtract(data,4,2) + libs.utils.bitExtract(data,14,2)
    status.telemetry.gpsHdopC = libs.utils.bitExtract(data,7,7) * (10^libs.utils.bitExtract(data,6,1)) -- dm
    status.telemetry.gpsAlt = libs.utils.bitExtract(data,24,7) * (10^libs.utils.bitExtract(data,22,2)) * (libs.utils.bitExtract(data,31,1) == 1 and -1 or 1)-- dm
  elseif appId == 0x5003 then -- BATT
    status.telemetry.batt1volt = libs.utils.bitExtract(data,0,9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if >= 12s ==> Vreal = 51.2 + status.telemetry.batt1volt
    if status.conf.cell1Count >= 12 and status.telemetry.batt1volt < status.conf.cell1Count*20 then
      -- assume a 2V as minimum acceptable "real" voltage
      status.telemetry.batt1volt = 512 +status.telemetry.batt1volt
    end
    status.telemetry.batt1current = libs.utils.bitExtract(data,10,7) * (10^libs.utils.bitExtract(data,9,1))
    status.telemetry.batt1mah = libs.utils.bitExtract(data,17,15)
  elseif appId == 0x5008 then -- BATT2
    status.telemetry.batt2volt = libs.utils.bitExtract(data,0,9)
    -- telemetry max is 51.1V, 51.2 is reported as 0.0, 52.3 is 0.1...60 is 88
    -- if 12S and V > 51.1 ==> Vreal = 51.2 +status.telemetry.batt1volt
    if status.conf.cell2Count == 12 and status.telemetry.batt2volt < 240 then
      -- assume a 2Vx12 as minimum acceptable "real" voltage
      status.telemetry.batt2volt = 512 +status.telemetry.batt2volt
    end
    status.telemetry.batt2current = libs.utils.bitExtract(data,10,7) * (10^libs.utils.bitExtract(data,9,1))
    status.telemetry.batt2mah = libs.utils.bitExtract(data,17,15)
  elseif appId == 0x5004 then -- HOME
    status.telemetry.homeDist = libs.utils.bitExtract(data,2,10) * (10^libs.utils.bitExtract(data,0,2))
    status.telemetry.homeAlt = libs.utils.bitExtract(data,14,10) * (10^libs.utils.bitExtract(data,12,2)) * 0.1 * (libs.utils.bitExtract(data,24,1) == 1 and -1 or 1)
    status.telemetry.homeAngle = libs.utils.bitExtract(data, 25,  7) * 3
  elseif appId == 0x5000 then -- MESSAGES
    if data ~= status.lastMsgValue then
      status.lastMsgValue = data
      local c
      local msgEnd = false
      local chunk = {}
      for i=3,0,-1
      do
        c = libs.utils.bitExtract(data,i*8,7)
        if c ~= 0 then
          --status.msgBuffer = status.msgBuffer .. string.char(c)
          chunk[4-i] = string.char(c)
          updateHash(c)
        else
          msgEnd = true;
          break;
        end
      end
      status.msgBuffer = status.msgBuffer..table.concat(chunk)
      if msgEnd then
        local severity = (libs.utils.bitExtract(data,7,1) * 1) + (libs.utils.bitExtract(data,15,1) * 2) + (libs.utils.bitExtract(data,23,1) * 4)
        libs.utils.pushMessage( severity, status.msgBuffer)
        playHash()
        resetHash()
        status.msgBuffer = nil
        status.msgBuffer = ""
      end
    end
  elseif appId == 0x5007 then -- PARAMS
    paramId = libs.utils.bitExtract(data,24,4)
    paramValue = libs.utils.bitExtract(data,0,24)
    if paramId == 1 then
      status.telemetry.frameType = paramValue
    elseif paramId == 4 then
      status.telemetry.batt1Capacity = paramValue
    elseif paramId == 5 then
      status.telemetry.batt2Capacity = paramValue
    elseif paramId == 6 then
      status.telemetry.wpCommands = paramValue
    end
  elseif appId == 0x5009 then -- WAYPOINTS @1Hz
    status.telemetry.wpNumber = libs.utils.bitExtract(data,0,10) -- wp index
    status.telemetry.wpDistance = libs.utils.bitExtract(data,12,10) * (10^libs.utils.bitExtract(data,10,2)) -- meters
    status.telemetry.wpXTError = libs.utils.bitExtract(data,23,4) * (10^libs.utils.bitExtract(data,22,1)) * (libs.utils.bitExtract(data,27,1) == 1 and -1 or 1)-- meters
    status.telemetry.wpOffsetFromCog = libs.utils.bitExtract(data,29,3) -- offset from cog with 45° resolution
  elseif appId == 0x500A then -- RPM 1 and 2
    -- rpm1 and rpm2 are int16_t
    local rpm1 = libs.utils.bitExtract(data,0,16)
    local rpm2 = libs.utils.bitExtract(data,16,16)
    status.telemetry.rpm1 = 10*(libs.utils.bitExtract(data,15,1) == 0 and rpm1 or -1*(1 + 0x0000FFFF & ~rpm1)) -- 2 complement if negative
    status.telemetry.rpm2 = 10*(libs.utils.bitExtract(data,31,1) == 0 and rpm2 or -1*(1 + 0x0000FFFF & ~rpm2)) -- 2 complement if negative
  elseif appId == 0x500B then -- TERRAIN
    status.telemetry.heightAboveTerrain = libs.utils.bitExtract(data,2,10) * (10^libs.utils.bitExtract(data,0,2)) * 0.1 * (libs.utils.bitExtract(data,12,1) == 1 and -1 or 1) -- dm to meters
    status.telemetry.terrainUnhealthy = libs.utils.bitExtract(data,13,1)
    status.terrainLastData = now
    status.terrainEnabled = 1
  elseif appId == 0x500C then -- WIND
    status.telemetry.trueWindSpeed = libs.utils.bitExtract(data,8,7) * (10^libs.utils.bitExtract(data,7,1)) -- dm/s
    status.telemetry.trueWindAngle = libs.utils.bitExtract(data, 0, 7) * 3 -- degrees
    status.telemetry.apparentWindSpeed = libs.utils.bitExtract(data,23,7) * (10^libs.utils.bitExtract(data,22,1)) -- dm/s
    status.telemetry.apparentWindAngle = libs.utils.bitExtract(data, 16, 6) * (libs.utils.bitExtract(data,15,1) == 1 and -1 or 1) * 3 -- degrees
  elseif appId == 0x500D then -- WAYPOINTS @1Hz
    status.telemetry.wpNumber = libs.utils.bitExtract(data,0,11) -- wp index
    status.telemetry.wpDistance = libs.utils.bitExtract(data,13,10) * (10^libs.utils.bitExtract(data,11,2)) -- meters
    status.telemetry.wpBearing = libs.utils.bitExtract(data, 23,  7) * 3
    if status.cog ~= nil then
      status.telemetry.wpOffsetFromCog = libs.utils.wrap360(status.telemetry.wpBearing - status.cog)
    end
    status.wpEnabled = 1
  --[[
  elseif appId == 0x50F1 then -- RC CHANNELS
    -- channels 1 - 32
    local offset = libs.utils.bitExtract(data,0,4) * 4
    rcchannels[1 + offset] = 100 * (libs.utils.bitExtract(data,4,6)/63) * (libs.utils.bitExtract(data,10,1) == 1 and -1 or 1)
    rcchannels[2 + offset] = 100 * (libs.utils.bitExtract(data,11,6)/63) * (libs.utils.bitExtract(data,17,1) == 1 and -1 or 1)
    rcchannels[3 + offset] = 100 * (libs.utils.bitExtract(data,18,6)/63) * (libs.utils.bitExtract(data,24,1) == 1 and -1 or 1)
    rcchannels[4 + offset] = 100 * (libs.utils.bitExtract(data,25,6)/63) * (libs.utils.bitExtract(data,31,1) == 1 and -1 or 1)
  --]]
  elseif appId == 0x50F2 then -- VFR
    status.telemetry.airspeed = libs.utils.bitExtract(data,1,7) * (10^libs.utils.bitExtract(data,0,1)) -- dm/s
    status.telemetry.throttle = libs.utils.bitExtract(data,8,7) -- unsigned throttle
    status.telemetry.baroAlt = libs.utils.bitExtract(data,17,10) * (10^libs.utils.bitExtract(data,15,2)) * 0.1 * (libs.utils.bitExtract(data,27,1) == 1 and -1 or 1)
    status.airspeedEnabled = 1
  elseif appId == 0x800 then
    local value = data & 0x3fffffff
    if data & (1 << 30) == (1 << 30) then
      value = -value
    end
    value = (value * 5) / 3;
    if data & (1 << 31) == (1 << 31) then
      status.telemetry.lon = value*0.000001
    else
      status.telemetry.lat = value*0.000001
    end
  end
end

function utils.crossfireTelemetryPop()
    local now = getTime()
    local command, data = crsf.popFrame()
    if command == nil or data == nil then
      return
    end
    if command == CRSF_FRAME_CUSTOM_TELEM or command == CRSF_FRAME_CUSTOM_TELEM_LEGACY then
      --utils.pushMessage(7, string.format("CRSF: command=%02X, #data = %d, type=%02X", command, #data, data[1]), false)
      -- actual payload starts at data[2]
      if #data >= 7 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH then
        local app_id = (data[3] << 8) + data[2]
        local value =  (data[7] << 24) + (data[6] << 16) + (data[5] << 8) + data[4]
        --utils.pushMessage(7, string.format("CRSF: %04X:%08X", app_id, value), true)
        return 0x00, 0x10, app_id, value
      elseif #data > 4 and data[1] == CRSF_CUSTOM_TELEM_STATUS_TEXT then
        local msg = {}
        local severity = data[2]
        -- copy the terminator as well
        for i=3,#data
        do
          -- avoid string concatenation which is slow!
          msg[i-2] = string.char(data[i])
          -- hash support
          updateHash(data[i])
        end
        status.msgBuffer = table.concat(msg)
        utils.pushMessage(severity, status.msgBuffer)
        -- hash audio support
        playHash()
        -- hash reset
        resetHash()
        status.msgBuffer = nil
        status.msgBuffer = ""
      elseif #data >= 8 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY then
        -- passthrough array
        local app_id, value
        for i=0, math.min(data[2]-1, 9)
        do
          app_id = (data[4+(6*i)] << 8) + data[3+(6*i)]
          value =  (data[8+(6*i)] << 24) + (data[7+(6*i)] << 16) + (data[6+(6*i)] << 8) + data[5+(6*i)]
          --utils.pushMessage(7, string.format("CRSF:%d - %04X:%08X",i, app_id, value), true)
          utils.processTelemetry(app_id, value, now)
        end
        status.noTelemetryData = 0
        status.hideNoTelemetry = true
      end
    end
    return nil, nil ,nil ,nil
end

function utils.passthroughTelemetryPop()
  local frame = passthroughSensor:popFrame()
  if frame == nil then
    return nil, nil, nil, nil
  end
  return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

function utils.getRSSI()
  --print("getRSSI", status.conf.linkQualitySource:value())
  if status.conf.linkQualitySource == nil then
    return nil
  end
  return status.conf.linkQualitySource:value()
end

function utils.resetTimer()
  local timer = model.getTimer("Yaapu")
  timer:activeCondition( system.getSource(nil) )
  timer:value(0)
end

function utils.startTimer()
  status.lastTimerStart = getTime()/100
  local timer = model.getTimer("Yaapu")
  timer:activeCondition( {category=CATEGORY_ALWAYS_ON, member=1, options=0} )
end

function utils.stopTimer()
  status.lastTimerStart = 0
  local timer = model.getTimer("Yaapu")
  timer:activeCondition(  system.getSource(nil))
end

function utils.telemetryEnabled(widget)
  if utils.getRSSI() == 0 then
    status.noTelemetryData = 1
  end
  return status.noTelemetryData == 0
end

function utils.failsafeActive(widget)
  if status.telemetry.ekfFailsafe == 1 or status.telemetry.battFailsafe == 1 or status.telemetry.failsafe == 1 then
    return true
  end
  return false
end

function utils.loadFlightModes()
  if status.frame.flightModes then
    return
  end
  if status.telemetry.frameType ~= -1 then
    if status.frameTypes[status.telemetry.frameType] == "c" then
      status.frame = loadLib(status.conf.enablePX4Modes and "copter_px4" or "copter")
    elseif status.frameTypes[status.telemetry.frameType] == "p" then
      status.frame = loadLib(status.conf.enablePX4Modes and "plane_px4" or "plane")
    elseif frameTypes[status.telemetry.frameType] == "r" or status.frameTypes[status.telemetry.frameType] == "b" then
      status.frame = loadLib("rover")
    elseif frameTypes[telemetry.frameType] == "a" then
      status.frame = loadLib("blimp")
    end
  end
end

function utils.playSound(soundFile, skipHaptic)
  if status.conf.enableHaptic and skipHaptic == nil then
    system.playHaptic(15,0)
  end
  if status.conf.disableAllSounds then
    return
  end
  libs.drawLib.resetBacklightTimeout()
  system.playFile("/scripts/yaaputelemetry/audio/"..status.conf.language.."/".. soundFile..".wav")
end

function utils.playTime(seconds)
  if seconds > 3600 then
    system.playNumber(seconds / 3600, UNIT_HOUR)
    system.playNumber((seconds % 3600) / 60, UNIT_MINUTE)
    system.playNumber((seconds % 3600) % 60, UNIT_SECOND)
  else
    system.playNumber(seconds / 60, UNIT_MINUTE)
    system.playNumber(seconds % 60, UNIT_SECOND)
  end
end

function utils.playSoundByFlightMode(flightMode)
  if status.conf.enableHaptic then
    system.playHaptic(15,0)
  end
  if status.conf.disableAllSounds then
    return
  end
  if status.frame.flightModes then
    if status.frame.flightModes[flightMode] ~= nil then
      libs.drawLib.resetBacklightTimeout()
      -- rover sound files differ because they lack "flight" word
      system.playFile("/scripts/yaaputelemetry/audio/"..status.conf.language.."/".. string.lower(status.frame.flightModes[flightMode]) .. ((status.frameTypes[status.telemetry.frameType]=="r" or status.frameTypes[status.telemetry.frameType]=="b") and "_r.wav" or ".wav"))
    end
  end
end

function utils.calcCellCount()
  -- cellcount override from menu
  local c1 = 0
  local c2 = 0

  if status.conf.cell1Count ~= nil and status.conf.cell1Count > 0 then
    c1 = status.conf.cell1Count
  elseif status.batt1sources.vs == true and status.cell1count > 1 then
    c1 = status.cell1count
  else
    c1 = math.floor( ((status.cell1maxFC*0.1) / 4.35) + 1)
  end

  if status.conf.cell2Count ~= nil and status.conf.cell2Count > 0 then
    c2 = status.conf.cell2Count
  elseif status.batt2sources.vs == true and status.cell2count > 1 then
    c2 = status.cell2count
  else
    c2 = math.floor(((status.cell2maxFC*0.1)/4.35) + 1)
  end

  return c1,c2
end

function utils.getAngleFromLatLon(lat1, lon1, lat2, lon2)
  local la1 = math.rad(lat1)
  local lo1 = math.rad(lon1)
  local la2 = math.rad(lat2)
  local lo2 = math.rad(lon2)

  local y = math.sin(lo2-lo1) * math.cos(la2);
  local x = math.cos(la1)*math.sin(la2) - math.sin(la1)*math.cos(la2)*math.cos(lo2-lo1);
  local a = math.atan(y, x);

  return (a*180/math.pi + 360) % 360 -- in degrees
end

function utils.getMaxValue(value,idx)
  status.minmaxValues[idx] = math.max(value,status.minmaxValues[idx])
  return status.showMinMaxValues == true and status.minmaxValues[idx] or value
end

function utils.calcMinValue(value,min)
  return min == 0 and value or math.min(value,min)
end

-- returns the actual minimun only if both are > 0
function utils.getNonZeroMin(v1,v2)
  return v1 == 0 and v2 or ( v2 == 0 and v1 or math.min(v1,v2))
end

---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
function utils.checkAlarm(level, value, idx, sign, sound, delay)
  if delay == 0 then
    return
  end
  -- once landed reset all alarms except battery alerts
  if status.timerRunning == 0 then
    if status.alarms[idx][4] == 0 then
      status.alarms[idx] = { false, 0, false, 0, 0, false, 0}
    elseif status.alarms[idx][4] == 1 then
      status.alarms[idx] = { false, 0, true, 1, 0, false, 0}
    elseif status.alarms[idx][4] == 2 then
      status.alarms[idx] = { false, 0, true, 2, 0, false, 0}
    elseif status.alarms[idx][4] == 3 then
      status.alarms[idx] = { false, 0 , false, 3, 4, false, 0}
    elseif status.alarms[idx][4] == 4 then
      status.alarms[idx] = { false, 0 , false, 4, 4, false, 0}
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level
  if status.alarms[idx][3] == false and level > 0 and -1 * sign*value > -1 * sign*level then
    status.alarms[idx][3] = true
  end

  if status.alarms[idx][4] == 2 then
    if status.flightTime > 0 and math.floor(status.flightTime) %  delay == 0 then
      if status.alarms[idx][1] == false then
        status.alarms[idx][1] = true
        utils.playSound(sound)
        utils.playTime(status.flightTime)
      end
    else
        status.alarms[idx][1] = false
    end
  else
    if status.alarms[idx][3] == true then
      if level > 0 and sign*value > sign*level then
        -- value is outside level
        if status.alarms[idx][2] == 0 then
          -- first time outside level after last reset
          status.alarms[idx][2] = status.flightTime
          -- status: START
        end
      else
        -- value back to normal ==> reset
        status.alarms[idx][2] = 0
        status.alarms[idx][1] = false
        status.alarms[idx][6] = false
        -- status: RESET
      end
      if status.alarms[idx][2] > 0 and (status.flightTime ~= status.alarms[idx][2]) and (status.flightTime - status.alarms[idx][2]) >= status.alarms[idx][5] then
        -- enough time has passed after START
        status.alarms[idx][6] = true
        -- status: READY
      end

      if status.alarms[idx][6] == true and status.alarms[idx][1] == false then
        utils.playSound(sound)
        status.alarms[idx][1] = true
        status.alarms[idx][7] = status.flightTime
        -- status: BEEP
      end
      -- all but battery alarms
      if status.alarms[idx][4] ~= 3 then
        if status.alarms[idx][6] == true and status.flightTime ~= status.alarms[idx][7] and (status.flightTime - status.alarms[idx][7]) %  delay == 0 then
          status.alarms[idx][1] = false
          -- status: REPEAT
        end
      end
    end
  end
end

function utils.getBatt1Capacity()
  return (status.conf.battCapOverride1 ~= nil and status.conf.battCapOverride1 > 0) and status.conf.battCapOverride1*100 or status.telemetry.batt1Capacity
end

function utils.getBatt2Capacity()
  -- this is a fix for passthrough telemetry reporting batt2 capacity > 0 even if BATT2_MONITOR = 0
  return (status.conf.battCapOverride2 ~= nil and status.conf.battCapOverride2 > 0) and status.conf.battCapOverride2*100 or ( status.batt2sources.fc and status.telemetry.batt2Capacity or 0 )
end

-- gets the voltage based on source and min value, battId = [1|2]
function utils.getMinVoltageBySource(source, cell, cellFC, battId)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > 4.35*2 or cellFC > 4.35*2 then
    offset = 2
  end
  --
  if source == "vs" then
    return status.showMinMaxValues == true and status.minmaxValues[2+offset+battId] or cell
  elseif source == "fc" then
      -- FC only tracks batt1 and batt2 no cell voltage tracking
      local minmax = (offset == 2 and status.minmaxValues[battId] or status.minmaxValues[battId]/utils.calcCellCount())
      return status.showMinMaxValues == true and minmax or cellFC
  end
  --
  return 0
end

function utils.getBattPercByCell(voltage)
  if status.battPercByVoltage.dischargeCurve == nil then
    return 99
  end
  -- when disarmed apply voltage drop to use an "under load" curve
  if status.telemetry.statusArmed == 0 then
    voltage = voltage - status.battPercByVoltage.voltageDrop
  end

  if status.battPercByVoltage.useCellVoltage == false then
    voltage = voltage*utils.calcCellCount()
  end
  if voltage == 0 then
    return 99
  end
  if voltage >= status.battPercByVoltage.dischargeCurve[#status.battPercByVoltage.dischargeCurve][1] then
    return 99
  end
  if voltage <= status.battPercByVoltage.dischargeCurve[1][1] then
    return 0
  end
  for i=2,#status.battPercByVoltage.dischargeCurve do
    if voltage <= status.battPercByVoltage.dischargeCurve[i][1] then
      --
      local v0 = status.battPercByVoltage.dischargeCurve[i-1][1]
      local fv0 = status.battPercByVoltage.dischargeCurve[i-1][2]
      --
      local v1 = status.battPercByVoltage.dischargeCurve[i][1]
      local fv1 = status.battPercByVoltage.dischargeCurve[i][2]
      -- interpolation polinomial
      return fv0 + ((fv1 - fv0)/(v1-v0))*(voltage - v0)
    end
  end --for
end

function utils.calcFLVSSBatt(battIdx)
  local statusBattSources = battIdx == 1 and status.batt1sources or status.batt2sources
  statusBattSources.vs = false

  if status.conf.defaultBattSourceId ~= 2 then
    return 0,0,0
  end


  local batterySource = battIdx == 1 and status.conf.battery1Source or status.conf.battery2Source

  if batterySource == nil then
    return 0,0,0
  end

  if system.getSource(batterySource:name()) == nil then
    return 0,0,0
  end

  local cellMin = system.getSource({name=batterySource:name(),options=OPTION_CELL_LOWEST}):value()
  local cellCount = system.getSource({name=batterySource:name(),options=OPTION_CELL_COUNT}):value()
  local cellSum = batterySource:value()
  statusBattSources.vs = true

  return cellMin, cellSum, cellCount
end

function utils.calcBattery()
  ------------
  -- FLVSS 1
  ------------
  status.cell1min, status.cell1sum, status.cell1count = utils.calcFLVSSBatt(1) --1 = Cels

  ------------
  -- FLVSS 2
  ------------
  status.cell2min, status.cell2sum, status.cell2count = utils.calcFLVSSBatt(2) --2 = Cel2

  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if status.telemetry.batt1volt > 0 then
    status.cell1sumFC = status.telemetry.batt1volt*0.1
    status.cell1maxFC = math.max(status.telemetry.batt1volt,status.cell1maxFC)
    status.batt1sources.fc = true
  else
    status.batt1sources.fc = false
    status.cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if status.telemetry.batt2volt > 0 then
    status.cell2sumFC = status.telemetry.batt2volt*0.1
    status.cell2maxFC = math.max(status.telemetry.batt2volt,status.cell2maxFC)
    status.batt2sources.fc = true
  else
    status.batt2sources.fc = false
    status.cell2sumFC = 0
  end
  -- batt fc
  status.minmaxValues[1] = utils.calcMinValue(status.cell1sumFC,status.minmaxValues[1])
  status.minmaxValues[2] = utils.calcMinValue(status.cell2sumFC,status.minmaxValues[2])
  -- cell flvss
  status.minmaxValues[3] = utils.calcMinValue(status.cell1min,status.minmaxValues[3])
  status.minmaxValues[4] = utils.calcMinValue(status.cell2min,status.minmaxValues[4])
  -- batt flvss
  status.minmaxValues[5] = utils.calcMinValue(status.cell1sum,status.minmaxValues[5])
  status.minmaxValues[6] = utils.calcMinValue(status.cell2sum,status.minmaxValues[6])
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
  local count1,count2 = utils.calcCellCount()

  status.battery[1+1] = utils.getMinVoltageBySource(status.battsource, status.cell1min, status.cell1sumFC/count1, 1)*100 --cel1m
  status.battery[1+2] = utils.getMinVoltageBySource(status.battsource, status.cell2min, status.cell2sumFC/count2, 2)*100 --cel2m

  status.battery[4+1] = utils.getMinVoltageBySource(status.battsource, status.cell1sum, status.cell1sumFC, 1)*10 --batt1
  status.battery[4+2] = utils.getMinVoltageBySource(status.battsource, status.cell2sum, status.cell2sumFC, 2)*10 --batt2

  status.battery[7+1] = status.telemetry.batt1current -- curr1
  status.battery[7+2] = status.telemetry.batt2current -- curr2

  status.battery[10+1] = status.telemetry.batt1mah --mah1
  status.battery[10+2] = status.telemetry.batt2mah --mah2

  status.battery[13+1] = utils.getBatt1Capacity() --cap1
  status.battery[13+2] = utils.getBatt2Capacity() --cap2

  if (status.conf.battConf == 1) then
    status.battery[1] = utils.getNonZeroMin(status.battery[2], status.battery[3])
    status.battery[4] = utils.getNonZeroMin(status.battery[5],status.battery[6])
    status.battery[7] = status.telemetry.batt1current + status.telemetry.batt2current
    status.battery[10] = status.telemetry.batt1mah + status.telemetry.batt2mah
    status.battery[13] = utils.getBatt2Capacity() + utils.getBatt1Capacity()
  elseif (status.conf.battConf == 2) then
    status.battery[1] = utils.getNonZeroMin(status.battery[2], status.battery[3])
    status.battery[4] = status.battery[5] + status.battery[6]
    status.battery[7] = status.telemetry.batt1current
    status.battery[10] = status.telemetry.batt1mah
    status.battery[13] = utils.getBatt1Capacity()
  elseif (status.conf.battConf == 3) then
    -- independent batteries, alerts and capacity % on battery 1
    status.battery[1] = status.battery[2]
    status.battery[4] = status.battery[5]
    status.battery[7] = status.telemetry.batt1current
    status.battery[10] = status.telemetry.batt1mah
    status.battery[13] = utils.getBatt1Capacity()
  elseif (status.conf.battConf == 4) then
    -- independent batteries, alerts and capacity % on battery 2
    status.battery[1] = status.battery[3]
    status.battery[4] = status.battery[6]
    status.battery[7] = status.telemetry.batt2current
    status.battery[10] = status.telemetry.batt2mah
    status.battery[13] = utils.getBatt2Capacity()
  elseif (status.conf.battConf == 5) then
    -- independent batteries, voltage alerts on battery 1, capacity % on battery 2
    status.battery[1] = status.battery[2]
    status.battery[4] = status.battery[5]
    status.battery[7] = status.telemetry.batt2current
    status.battery[10] = status.telemetry.batt2mah
    status.battery[13] = utils.getBatt2Capacity()
  elseif (status.conf.battConf == 6) then
    -- independent batteries, voltage alerts on battery 2, capacity % on battery 1
    status.battery[1] = status.battery[3]
    status.battery[4] = status.battery[6]
    status.battery[7] = status.telemetry.batt1current
    status.battery[10] = status.telemetry.batt1mah
    status.battery[13] = utils.getBatt1Capacity()
  end

  -- aggregate value
  status.minmaxValues[7] = math.max(status.battery[7], status.minmaxValues[7])
  -- indipendent values
  status.minmaxValues[8] = math.max(status.telemetry.batt1current, status.minmaxValues[8])
  status.minmaxValues[9] = math.max(status.telemetry.batt2current, status.minmaxValues[9])

  --[[
    discharge curve is based on battery under load, when motors are disarmed
    cellvoltage needs to be corrected by subtracting the "under load" voltage drop
  --]]
  if status.conf.enableBattPercByVoltage == true then
    for battId=0,2
    do
      status.battery[16+battId] = utils.getBattPercByCell(0.01*status.battery[1+battId])
    end
  else
    for battId=0,2
    do
      if (status.battery[13+battId] > 0) then
        status.battery[16+battId] = (1 - (status.battery[10+battId]/status.battery[13+battId]))*100
        if status.battery[16+battId] > 99 then
          status.battery[16+battId] = 99
        elseif status.battery[16+battId] < 0 then
          status.battery[16+battId] = 0
        end
      else
        status.battery[16+battId] = 99
      end
    end
  end

  if status.showDualBattery == true and status.conf.battConf ==  1 then
    -- dual parallel battery: do I have also dual current monitor?
    if status.battery[7+1] > 0 and status.battery[7+2] == 0  then
      -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
      status.battery[7+1] = status.battery[7+1]/2 --curr1
      status.battery[7+2] = status.battery[7+1]   --curr2
      --
      status.battery[10+1]  = status.battery[10+1]/2  --mah1
      status.battery[10+2]  = status.battery[10+1]    --mah2
      --
      status.battery[13+1] = status.battery[13+1]/2   --cap1
      status.battery[13+2] = status.battery[13+1]     --cap2
      --
      status.battery[16+1] = status.battery[16+1]/2   --perc1
      status.battery[16+2] = status.battery[16+1]     --perc2
    end
  end
end

function utils.getLatLonFromAngleAndDistance(angle, distance)
--[[
  la1,lo1 coordinates of first point
  d be distance (m),
  R as radius of Earth (m),
  Ad be the angular distance i.e d/R and
  θ be the bearing in deg

  la2 =  asin(sin la1 * cos Ad  + cos la1 * sin Ad * cos θ), and
  lo2 = lo1 + atan(sin θ * sin Ad * cos la1 , cos Ad – sin la1 * sin la2)
--]]
  if status.telemetry.lat == nil or status.telemetry.lon == nil then
    return nil,nil
  end
  local lat1 = math.rad(status.telemetry.lat)
  local lon1 = math.rad(status.telemetry.lon)
  local Ad = distance/(6371000) --meters
  local lat2 = math.asin( math.sin(lat1) * math.cos(Ad) + math.cos(lat1) * math.sin(Ad) * math.cos( math.rad(angle)) )
  local lon2 = lon1 + math.atan( math.sin( math.rad(angle) ) * math.sin(Ad) * math.cos(lat1) , math.cos(Ad) - math.sin(lat1) * math.sin(lat2))
  return math.deg(lat2), math.deg(lon2)
end

function utils.decToDMS(dec,lat)
  local D = math.floor(math.abs(dec))
  local M = (math.abs(dec) - D)*60
  local S = (math.abs((math.abs(dec) - D)*60) - M)*60
	return D .. string.format("°%04.2f", M) .. (lat and (dec >= 0 and "E" or "W") or (dec >= 0 and "N" or "S"))
end

function utils.decToDMSFull(dec,lat)
  local D = math.floor(math.abs(dec))
  local M = math.floor((math.abs(dec) - D)*60)
  local S = (math.abs((math.abs(dec) - D)*60) - M)*60
	return D .. string.format("°%d'%04.1f", M, S) .. (lat and (dec >= 0 and "E" or "W") or (dec >= 0 and "N" or "S"))
end

function utils.updateTotalDist()
  if status.telemetry.armingStatus == 0 then
    status.lastUpdateTotDist = getTime()
    return
  end
  if status.avgSpeed == 0 then
    status.avgSpeed = status.telemetry.hSpeed * 0.1 -- m/s
  end
  status.avgSpeed = status.avgSpeed*0.5 + status.telemetry.hSpeed*0.5*0.1 -- m/s
  local delta = getTime() - status.lastUpdateTotDist
  status.lastUpdateTotDist = getTime()
  -- check if avgSpeed > 1m/s
  if status.avgSpeed > 1 then
    status.telemetry.totalDist = status.telemetry.totalDist + (status.avgSpeed * delta * 0.01) --hSpeed dm/s, getTime()/100 secs
  end
end

function utils.formatMessage(severity,msg)
  local clippedMsg = msg

  if #msg > 50 then
    clippedMsg = string.sub(msg,1,50)
    msg = nil
  end

  if status.lastMessageCount > 1 then
    return string.format("%02d:%02d %s (x%d) %s", math.floor(status.flightTime/60 + 0.5), math.floor(status.flightTime%60 + 0.5), status.mavSeverity[severity][1], status.lastMessageCount, clippedMsg)
  else
    return string.format("%02d:%02d %s %s", math.floor(status.flightTime/60 + 0.5), math.floor(status.flightTime%60 + 0.5), status.mavSeverity[severity][1], clippedMsg)
  end
end

function utils.pushMessage(severity, msg)
  if status.conf.enableHaptic then
    system.playHaptic(15,0)
  end
  if status.conf.disableAllSounds == false then
    if ( severity < 5 and status.conf.disableMsgBeep < 3) then
      utils.playSound("../err", true)
    else
      if status.conf.disableMsgBeep < 2 then
        utils.playSound("../inf", true)
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
  status.messages[msgIndex][1] = utils.formatMessage(severity,msg)
  status.messages[msgIndex][2] = severity

  status.lastMessage = msg
  status.lastMessageSeverity = severity
end

function utils.updateFlightTime()
  status.flightTime = tonumber(model.getTimer("Yaapu"):value())
end

---------------------------------
-- This function checks state transitions and only returns true if a specific delay has passed
-- new transitions reset the delay timer
---------------------------------
function utils.checkTransition(idx,value)
  if value ~= status.transitions[idx][1] then
    -- value has changed
    status.transitions[idx][1] = value
    status.transitions[idx][2] = getTime()
    status.transitions[idx][3] = false
    -- status: RESET
    return false
  end
  if status.transitions[idx][3] == false and (getTime() - status.transitions[idx][2]) > status.transitions[idx][4] then
    -- enough time has passed after RESET
    status.transitions[idx][3] = true
    -- status: FIRE
    return true;
  end
end

function utils.getBitmask(low, high)
  local key = tostring(low)..tostring(high)
  local res = bitmaskCache[key]
  if res == nil then
    res = 2^(1 + high-low)-1 << low
    bitmaskCache[key] = res
  end
  return res
end

function utils.bitExtract(value, start, len)
  return (value & utils.getBitmask(start,start+len-1)) >> start
end

function utils.wrap360(angle)
    local res = angle % 360
    if res < 0 then
        res = res + 360
    end
    return res
end

function utils.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return utils
end

-- default is to use frsky telemetry
utils.telemetryPop = utils.passthroughTelemetryPop

return utils
