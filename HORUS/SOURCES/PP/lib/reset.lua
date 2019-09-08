#include "includes/yaapu_inc.lua"

local function resetTelemetry(status,telemetry,battery,alarms,utils)
  -- sport queue max pops to prevent looping forever
  local i = 0  
  -- empty sport queue
  local a,b,c,d = sportTelemetryPop()
  while a ~= null and i < 50 do
    a,b,c,d = sportTelemetryPop()
    i = i + 1
  end
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
  -- messages
  status.lastMessage = nil
  status.lastMessageSeverity = 0
  status.lastMessageCount = 1
  status.messageCount = 0
  -------------------------
  -- BATTERY ARRAY
  -------------------------
  battery = {0,0,0,0,0,0,0,0,0,0,0,0}
  -- clear message queue
  utils.clearTable(status.messages)
  ---
  status.messages = {}
  -- reset alarms
  alarms[1] = { false, 0 , false, ALARM_TYPE_MIN, 0, false, 0} --MIN_ALT
  alarms[2] = { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 } --MAX_ALT
  alarms[3] = { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 } --MAX_DIST
  alarms[4] = { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 } --FS_EKF
  alarms[5] = { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 } --FS_BAT
  alarms[6] = { false, 0 , true, ALARM_TYPE_TIMER, 0, false, 0 } --FLIGTH_TIME
  alarms[7] = { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0 } --BATT L1
  alarms[8] = { false, 0 , false, ALARM_TYPE_BATT_CRT, ALARM_TYPE_BATT_GRACE, false, 0 } --BATT L2
  alarms[9] = { false, 0 , false, ALARM_TYPE_MAX, 0, false, 0 } --MAX_HDOP
  -- stop and reset timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
end

return {resetTelemetry=resetTelemetry}