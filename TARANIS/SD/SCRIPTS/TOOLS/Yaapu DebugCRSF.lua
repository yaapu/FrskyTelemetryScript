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
      elseif #data > 48 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY then
        -- passthrough array
        local app_id, value
        for i=0,data[2]-1
        do
          app_id = bit32.lshift(data[4+(6*i)],8) + data[3+(6*i)]
          value =  bit32.lshift(data[8+(6*i)],24) + bit32.lshift(data[7+(6*i)],16) + bit32.lshift(data[6+(6*i)],8) + data[5+(6*i)]
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
  lcd.clear()

if LCD_W > 200 then
  lcd.drawText(1,1,string.format("Yaapu CRSF Debug 1.9.5 - %.01fHz",packetStats.link_rate),SMLSIZE)
  lcd.drawText(1,11,string.format("5000: %d %.01f", packetStats[0x5000].tot, packetStats[0x5000].avg),SMLSIZE)
  lcd.drawText(1,20,string.format("5001: %d %.01f", packetStats[0x5001].tot, packetStats[0x5001].avg),SMLSIZE)
  lcd.drawText(1,29,string.format("5002: %d %.01f", packetStats[0x5002].tot, packetStats[0x5002].avg),SMLSIZE)
  lcd.drawText(1,38,string.format("5003: %d %.01f", packetStats[0x5003].tot, packetStats[0x5003].avg),SMLSIZE)
  lcd.drawText(1,47,string.format("5004: %d %.01f", packetStats[0x5004].tot, packetStats[0x5004].avg),SMLSIZE)

  lcd.drawText(73,11,string.format("5005: %d %.01f", packetStats[0x5005].tot, packetStats[0x5005].avg),SMLSIZE)
  lcd.drawText(73,20,string.format("5006: %d %.01f", packetStats[0x5006].tot, packetStats[0x5006].avg),SMLSIZE)
  lcd.drawText(73,29,string.format("5007: %d %.01f", packetStats[0x5007].tot, packetStats[0x5007].avg),SMLSIZE)
  lcd.drawText(73,38,string.format("5008: %d %.01f", packetStats[0x5008].tot, packetStats[0x5008].avg),SMLSIZE)
  lcd.drawText(73,47,string.format("5009: %d %.01f", packetStats[0x5009].tot, packetStats[0x5009].avg),SMLSIZE)

  lcd.drawText(145,11,string.format("500A: %d %.01f", packetStats[0x500A].tot, packetStats[0x500A].avg),SMLSIZE)
  lcd.drawText(145,20,string.format("500B: %d %.01f", packetStats[0x500B].tot, packetStats[0x500B].avg),SMLSIZE)
  lcd.drawText(145,29,string.format("500C: %d %.01f", packetStats[0x500C].tot, packetStats[0x500C].avg),SMLSIZE)
  lcd.drawText(145,38,string.format("500D: %d %.01f", packetStats[0x500D].tot, packetStats[0x500D].avg),SMLSIZE)
  lcd.drawText(1,LCD_H-7,"/LOGS/"..tostring(logfilename),SMLSIZE)
else
  lcd.drawText(1,1,string.format("Yaapu CRSF 1.9.5 %.01fHz",packetStats.link_rate),SMLSIZE)
  lcd.drawText(1,11,string.format("5000:%d", packetStats[0x5000].tot),SMLSIZE)
  lcd.drawText(1,20,string.format("5001:%d", packetStats[0x5001].tot),SMLSIZE)
  lcd.drawText(1,29,string.format("5002:%d", packetStats[0x5002].tot),SMLSIZE)
  lcd.drawText(1,38,string.format("5003:%d", packetStats[0x5003].tot),SMLSIZE)
  lcd.drawText(1,47,string.format("5004:%d", packetStats[0x5004].tot),SMLSIZE)

  lcd.drawText(43,11,string.format("5005:%d", packetStats[0x5005].tot),SMLSIZE)
  lcd.drawText(43,20,string.format("5006:%d", packetStats[0x5006].tot),SMLSIZE)
  lcd.drawText(43,29,string.format("5007:%d", packetStats[0x5007].tot),SMLSIZE)
  lcd.drawText(43,38,string.format("5008:%d", packetStats[0x5008].tot),SMLSIZE)
  lcd.drawText(43,47,string.format("5009:%d", packetStats[0x5009].tot),SMLSIZE)

  lcd.drawText(85,11,string.format("500A:%d", packetStats[0x500A].tot),SMLSIZE)
  lcd.drawText(85,20,string.format("500B:%d", packetStats[0x500B].tot),SMLSIZE)
  lcd.drawText(85,29,string.format("500C:%d", packetStats[0x500C].tot),SMLSIZE)
  lcd.drawText(85,38,string.format("500D:%d", packetStats[0x500D].tot),SMLSIZE)
  lcd.drawText(LCD_W,LCD_H-7,tostring(logfilename),SMLSIZE+RIGHT)
end

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


