
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

local function background()
  for i=1,3
  do
    local sensor_id,frame_id,data_id,value = sportTelemetryPop()
    if frame_id == 0x10 then
      if packetCount[data_id] ~= nil then
        packetCount[data_id] = packetCount[data_id] + 1
      end
    end
  end
end

local function run(event)
  lcd.clear()
  for i=0,8 do
    lcd.drawText(1,1+7*i,string.format("500%d: %d", i, packetCount[0x5000+i]),SMLSIZE)
  end  
  collectgarbage()
  collectgarbage()
end

local function init()
end

return {run=run,  background=background, init=init}

