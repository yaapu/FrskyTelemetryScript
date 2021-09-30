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

local function getLogFilename()
  local datenow = getDateTime()
  local info = model.getInfo()
  local modelName = string.lower(string.gsub(info.name, "[%c%p%s%z]", ""))
  return modelName..string.format("-frsky-%04d%02d%02d_%02d%02d%02d.plog", datenow.year, datenow.mon, datenow.day, datenow.hour, datenow.min, datenow.sec)
end

local last_refresh = getTime()

local function background()
  for i=1,5
  do
    local success,sensor_id,frame_id,data_id,value = pcall(sportTelemetryPop)
    if success and sensor_id ~= nil then
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
  lcd.drawText(1,1,string.format("Yaapu FRSKY Debug 1.9.5 - %.01fHz",packetStats.link_rate),SMLSIZE)
  lcd.drawText(1,11,string.format("5000: %04.01f %d", packetStats[0x5000].avg, packetStats[0x5000].tot),SMLSIZE)
  lcd.drawText(1,20,string.format("5001: %04.01f %d", packetStats[0x5001].avg, packetStats[0x5001].tot),SMLSIZE)
  lcd.drawText(1,29,string.format("5002: %04.01f %d", packetStats[0x5002].avg, packetStats[0x5002].tot),SMLSIZE)
  lcd.drawText(1,38,string.format("5003: %04.01f %d", packetStats[0x5003].avg, packetStats[0x5003].tot),SMLSIZE)
  lcd.drawText(1,47,string.format("5004: %04.01f %d", packetStats[0x5004].avg, packetStats[0x5004].tot),SMLSIZE)

  lcd.drawText(73,11,string.format("5005: %04.01f %d", packetStats[0x5005].avg, packetStats[0x5005].tot),SMLSIZE)
  lcd.drawText(73,20,string.format("5006: %04.01f %d", packetStats[0x5006].avg, packetStats[0x5006].tot),SMLSIZE)
  lcd.drawText(73,29,string.format("5007: %04.01f %d", packetStats[0x5007].avg, packetStats[0x5007].tot),SMLSIZE)
  lcd.drawText(73,38,string.format("5008: %04.01f %d", packetStats[0x5008].avg, packetStats[0x5008].tot),SMLSIZE)
  lcd.drawText(73,47,string.format("5009: %04.01f %d", packetStats[0x5009].avg, packetStats[0x5009].tot),SMLSIZE)

  lcd.drawText(145,11,string.format("500A: %04.01f %d", packetStats[0x500A].avg, packetStats[0x500A].tot),SMLSIZE)
  lcd.drawText(145,20,string.format("500B: %04.01f %d", packetStats[0x500B].avg, packetStats[0x500B].tot),SMLSIZE)
  lcd.drawText(145,29,string.format("500C: %04.01f %d", packetStats[0x500C].avg, packetStats[0x500C].tot),SMLSIZE)
  lcd.drawText(145,38,string.format("500D: %04.01f %d", packetStats[0x500D].avg, packetStats[0x500D].tot),SMLSIZE)
  lcd.drawText(1,LCD_H-7,"/LOGS/"..tostring(logfilename),SMLSIZE)
else
  lcd.drawText(1,1,string.format("Yaapu FRSKY 1.9.5 %.01fHz",packetStats.link_rate),SMLSIZE)
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


