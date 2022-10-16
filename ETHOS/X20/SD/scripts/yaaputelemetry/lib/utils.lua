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

function utils.passthroughTelemetryPop()
  local frame = passthroughSensor:popFrame()
  if frame == nil then
    return nil, nil, nil, nil
  end
  return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

function utils.getRSSI()
  --print("getRSSI", utils.getSourceValue("RSSI"))
  return utils.getSourceValue("RSSI")
end

function utils.resetTimer()
  print("TIMER RESET")
  local timer = model.getTimer("Yaapu")
  timer:activeCondition( system.getSource(nil) )
  timer:value(0)
end

function utils.startTimer()
  print("TIMER START")
  status.lastTimerStart = getTime()/100
  local timer = model.getTimer("Yaapu")
  timer:activeCondition( {category=CATEGORY_ALWAYS_ON, member=1, options=0} )
end

function utils.stopTimer()
  print("TIMER STOP")
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

  print("LiPo", battIdx, cellMin, cellSum, cellCount)

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

return utils
