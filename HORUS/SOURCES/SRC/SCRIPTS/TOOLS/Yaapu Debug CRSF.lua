local CRSF_FRAME_CUSTOM_TELEM = 0x80
local CRSF_FRAME_CUSTOM_TELEM_LEGACY = 0x7F
local CRSF_CUSTOM_TELEM_PASSTHROUGH = 0xF0
local CRSF_CUSTOM_TELEM_STATUS_TEXT = 0xF1
local CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY = 0xF2

local packetStats = {
  [0x5000] = {count = 0, avg = 0 , tot = 0},
  [0x5001] = {count = 0, avg = 0 , tot = 0},
  [0x5002] = {count = 0, avg = 0 , tot = 0},
  [0x5003] = {count = 0, avg = 0 , tot = 0},
  [0x5004] = {count = 0, avg = 0 , tot = 0},
  [0x5005] = {count = 0, avg = 0 , tot = 0},
  [0x5006] = {count = 0, avg = 0 , tot = 0},
  [0x5007] = {count = 0, avg = 0 , tot = 0},
  [0x5008] = {count = 0, avg = 0 , tot = 0},
  [0x5009] = {count = 0, avg = 0 , tot = 0},
  [0x500A] = {count = 0, avg = 0 , tot = 0},
  [0x500B] = {count = 0, avg = 0 , tot = 0},
  [0x500C] = {count = 0, avg = 0 , tot = 0},
  [0x500D] = {count = 0, avg = 0 , tot = 0},
  link_rate = 0
}

local logfilename
local logfile
local flushtime = getTime()

local function processTelemetry(data_id, value)
  if packetStats[data_id] ~= nil then
    packetStats[data_id].tot = packetStats[data_id].tot + 1
    packetStats[data_id].count = packetStats[data_id].count + 1
  end
  io.write(logfile, getTime(), ";0;", data_id, ";", value, "\r\n")
end

local function crossfirePop()
    local command, data = crossfireTelemetryPop()
    -- command is 0x80 CRSF_FRAMETYPE_ARDUPILOT
    if (command == CRSF_FRAME_CUSTOM_TELEM or command == CRSF_FRAME_CUSTOM_TELEM_LEGACY)  and data ~= nil then
      -- actual payload starts at data[2]
      if #data >= 7 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH then
        local app_id = bit32.lshift(data[3],8) + data[2]
        local value =  bit32.lshift(data[7],24) + bit32.lshift(data[6],16) + bit32.lshift(data[5],8) + data[4]
        return 0x00, 0x10, app_id, value
      elseif #data > 4 and data[1] == CRSF_CUSTOM_TELEM_STATUS_TEXT then
        return 0x00, 0x10, 0x5000, 0x00000000
      elseif #data >= 8 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY then
        -- passthrough array
        local app_id, value
        for i=0,math.min(data[2]-1, 9)
        do
          app_id = bit32.lshift(data[4+(6*i)],8) + data[3+(6*i)]
          value =  bit32.lshift(data[8+(6*i)],24) + bit32.lshift(data[7+(6*i)],16) + bit32.lshift(data[6+(6*i)],8) + data[5+(6*i)]
          --pushMessage(7,string.format("CRSF:%d - %04X:%08X",i, app_id, value))
          processTelemetry(app_id, value)
        end
      end
    end
    return nil, nil ,nil ,nil
end

local function getLogFilename()
  local datenow = getDateTime()
  local info = model.getInfo()
  local modelName = string.lower(string.gsub(info.name, "[%c%p%s%z]", ""))
  return modelName..string.format("-crsf-%04d%02d%02d_%02d%02d%02d.plog", datenow.year, datenow.mon, datenow.day, datenow.hour, datenow.min, datenow.sec)
end

local last_refresh = getTime()

local function background()
  for i=1,5
  do
    local success, sensor_id, frame_id, data_id, value = pcall(crossfirePop)
    if success and frame_id == 0x10 then
      processTelemetry(data_id, value)
    end
    local now = getTime()
    if now - last_refresh > 100 then
      local aggregate = 0
      for i=0x00,0x0D
      do
        aggregate = aggregate + packetStats[0x5000+i].count

        if packetStats[0x5000+i].avg == 0 then
          packetStats[0x5000+i].avg = packetStats[0x5000+i].count
        end
        packetStats[0x5000+i].avg = packetStats[0x5000+i].avg * 0.75 + packetStats[0x5000+i].count * 0.25
        packetStats[0x5000+i].count = 0
      end
      packetStats.link_rate = packetStats.link_rate * 0.75 + aggregate * 0.25
      last_refresh = now
    end
  end

  if getTime() - flushtime > 50 then
    -- flush
    pcall(io.close,logfile)
    logfile = io.open("/LOGS/"..logfilename,"a")

    flushtime = getTime()
  end
end

local function run(event)
  background()
  lcd.setColor(CUSTOM_COLOR, 0x0AB1)
  lcd.clear(CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawText(1,1,"YAAPU CRSF DEBUG 1.9.5", CUSTOM_COLOR)

  local link_rate = 0
  for i=0x00,0x0D
  do
    lcd.setColor(CUSTOM_COLOR, WHITE)
    if packetStats[0x5000+i].avg > 0 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(0,255,0))
    end
    lcd.drawText(20,22+(i*16),string.format("0x50%02X: rate: %.01fHz, count: %d, ", i, packetStats[0x5000+i].avg, packetStats[0x5000+i].tot),CUSTOM_COLOR)
  end
  lcd.drawText(LCD_W-10, 1,string.format("link rate: %.01fHz", packetStats.link_rate), CUSTOM_COLOR+RIGHT)

  lcd.drawText(1,LCD_H-20,tostring("/LOGS/"..logfilename),CUSTOM_COLOR)
  collectgarbage()
  collectgarbage()
  return 0
end

local function init()
  logfilename = getLogFilename()
  logfile = io.open("/LOGS/"..logfilename,"a")
  io.write(logfile, "counter;f_time;data_id;value\r\n")
end

return {run=run, init=init}