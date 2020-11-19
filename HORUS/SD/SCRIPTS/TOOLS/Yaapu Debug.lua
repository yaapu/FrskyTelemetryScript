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
  
  lcd.setColor(CUSTOM_COLOR, 0x0AB1)
  lcd.clear(CUSTOM_COLOR)
  
  lcd.setColor(CUSTOM_COLOR, 0xFFFF)
  
  lcd.drawText(1,1,"YAAPU DEBUG 1.0",MIDSIZE+CUSTOM_COLOR)
  for i=0,9
  do
    lcd.drawText(20,30+(i*20),string.format("500%d: %d", i, packetCount[0x5000+i]),MIDSIZE+CUSTOM_COLOR)
  end
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


