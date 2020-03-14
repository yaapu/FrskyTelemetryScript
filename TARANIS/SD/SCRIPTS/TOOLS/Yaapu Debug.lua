
local packetCount = {
  [0x5000] = 0,
  [0x5001] = 0,
  [0x5002] = 0,
  [0x5003] = 0,
  [0x5004] = 0,
  [0x5005] = 0,
  [0x5006] = 0,
  [0x5007] = 0,
  [0x5008] = 0,
  [0x5009] = 0
}

local logfilename
local logfile
local flushtime = getTime()

local function getLogFilename()
  local datenow = getDateTime()  
  local info = model.getInfo()
  local modelName = string.lower(string.gsub(info.name, "[%c%p%s%z]", ""))
  return modelName..string.format("-%04d%02d%02d_%02d%02d%02d.plog", datenow.year, datenow.mon, datenow.day, datenow.hour, datenow.min, datenow.sec)
end

local function background()
  for i=1,5
  do
    local sensor_id,frame_id,data_id,value = sportTelemetryPop()
    if frame_id == 0x10 then
      if packetCount[data_id] ~= nil then
        packetCount[data_id] = packetCount[data_id] + 1
      end
      io.write(logfile, getTime(), ";0;", data_id, ";", value, "\r\n")             
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
  lcd.drawText(1,1,"YAAPU DEBUG 1.0",SMLSIZE)  
  lcd.drawText(1,11,string.format("500%d: %d", 0, packetCount[0x5000]),SMLSIZE)
  lcd.drawText(1,20,string.format("500%d: %d", 1, packetCount[0x5001]),SMLSIZE)
  lcd.drawText(1,29,string.format("500%d: %d", 2, packetCount[0x5002]),SMLSIZE)
  lcd.drawText(1,38,string.format("500%d: %d", 3, packetCount[0x5003]),SMLSIZE)
  lcd.drawText(1,47,string.format("500%d: %d", 4, packetCount[0x5004]),SMLSIZE)
  lcd.drawText(63,11,string.format("500%d: %d", 5, packetCount[0x5005]),SMLSIZE)
  lcd.drawText(63,20,string.format("500%d: %d", 6, packetCount[0x5006]),SMLSIZE)
  lcd.drawText(63,29,string.format("500%d: %d", 7, packetCount[0x5007]),SMLSIZE)
  lcd.drawText(63,38,string.format("500%d: %d", 8, packetCount[0x5008]),SMLSIZE)
  lcd.drawText(63,47,string.format("500%d: %d", 9, packetCount[0x5009]),SMLSIZE)
  lcd.drawText(1,LCD_H-7,tostring(logfilename),SMLSIZE)
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


