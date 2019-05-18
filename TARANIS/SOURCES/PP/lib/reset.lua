#include "includes/yaapu_inc.lua"

local function resetTelemetry(status,telemetry,battery,alarms,transitions)
  -----------------------------
  -- TELEMETRY
  -----------------------------
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

  -----------------------------
  -- SCRIPT STATUS
  -----------------------------
  status.battAlertLevel1 = false
  status.battAlertLevel2 = false
  status.flightTime = 0    -- updated from model timer 3
  status.timerRunning = 0  -- triggered by landcomplete from AP
  
  -- reset alarms
  alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, ALARM_TYPE_MIN, 0, false, 0}, --MIN_ALT
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_ALT
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_DIST
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_EKF
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_BAT
    { false, 0 , true, ALARM_TYPE_TIMER, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0 }, --BATT L1
    { false, 0 , false, ALARM_TYPE_BATT_CRT, ALARM_TYPE_BATT_GRACE, false, 0 } --BATT L2
  }

  transitions = {
  --{ last_value, last_changed, transition_done, delay }  
    { 0, 0, false, 30 }, -- flightmode
  }
  
  battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

  -- stop and reset timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
end

return {resetTelemetry=resetTelemetry}