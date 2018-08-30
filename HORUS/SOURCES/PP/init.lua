

--
--
--

local function resetTelemetry(status,alarms,function_pushMessage,function_clearTable)
  -- sport queue max pops to prevent looping forever
  local i = 0  
  -- empty sport queue
  local a,b,c,d = sportTelemetryPop()
  while a ~= null and i < 50 do
    a,b,c,d = sportTelemetryPop()
    i = i + 1
  end
  -- FLVSS 1
  status.cell1min = 0
  status.cell1sum = 0
  -- FLVSS 2
  status.cell2min = 0
  status.cell2sum = 0
  -- FC 1
  status.cell1sumFC = 0
  -- used to calculate cellcount
  status.cell1maxFC = 0
  -- FC 2
  status.cell2sumFC = 0
  -- A2
  status.cellsumA2 = 0
  -- used to calculate cellcount
  status.cellmaxA2 = 0
  --------------------------------
  -- AP STATUS
  status.flightMode = 0
  status.simpleMode = 0
  status.landComplete = 0
  status.statusArmed = 0
  status.battFailsafe = 0
  status.ekfFailsafe = 0
  status.imuTemp = 0
  -- GPS
  status.numSats = 0
  status.gpsStatus = 0
  status.gpsHdopC = 100
  status.gpsAlt = 0
  -- BATT
  status.cellcount = 0
  status.battsource = "na"
  -- BATT 1
  status.batt1volt = 0
  status.batt1current = 0
  status.batt1mah = 0
  status.batt1sources = {
    a2 = false,
    vs = false,
    fc = false
  }
  -- BATT 2
  status.batt2volt = 0
  status.batt2current = 0
  status.batt2mah = 0
  status.batt2sources = {
    a2 = false,
    vs = false,
    fc = false
  }
  -- TELEMETRY
  status.noTelemetryData = 1
  -- HOME
  status.homeDist = 0
  status.homeAlt = 0
  status.homeAngle = -1
  -- MESSAGES
  status.msgBuffer = ""
  status.lastMsgValue = 0
  status.lastMsgTime = 0
  -- VELANDYAW
  status.vSpeed = 0
  status.hSpeed = 0
  status.yaw = 0
  -- SYNTH VSPEED SUPPORT
  status.vspd = 0
  status.synthVSpeedTime = 0
  status.prevHomeAlt = 0
  -- ROLLPITCH
  status.roll = 0
  status.pitch = 0
  status.range = 0
  -- PARAMS
  status.frameType = -1
  status.batt1Capacity = 0
  status.batt2Capacity = 0
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
  -- clear message queue
  function_clearTable(status.messages)
  ---
  status.messages = {}
  -- reset alarms
  alarms[1] = { false, 0 , false, 0, 0, false, 0} --MIN_ALT
  alarms[2] = { false, 0 , true, 1 , 0, false, 0 } --MAX_ALT
  alarms[3] = { false, 0 , true, 1 , 0, false, 0 } --MAX_DIST
  alarms[4] = { false, 0 , true, 1 , 0, false, 0 } --FS_EKF
  alarms[5] = { false, 0 , true, 1 , 0, false, 0 } --FS_BAT
  alarms[6] = { false, 0 , true, 2, 0, false, 0 } --FLIGTH_TIME
  alarms[7] = { false, 0 , false, 3, 4, false, 0 } --BATT L1
  alarms[8] = { false, 0 , false, 3, 4, false, 0 } --BATT L2
    -- stop and reset timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
  --
  function_pushMessage(7,"telemetry reset")
end

return {resetTelemetry=resetTelemetry}
