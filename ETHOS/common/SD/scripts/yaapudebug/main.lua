local CRSF_FRAME_CUSTOM_TELEM = 0x80
local CRSF_FRAME_CUSTOM_TELEM_LEGACY = 0x7F
local CRSF_CUSTOM_TELEM_PASSTHROUGH = 0xF0
local CRSF_CUSTOM_TELEM_STATUS_TEXT = 0xF1
local CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY = 0xF2

local passthroughSensor = sport.getSensor({module=0xFFFF, appIdStart=0x800, appIdEnd=0x51FF})

local translations = {en="Yaapu Debug"}
local telemetryPop = nil

local packetStats = {
  [0x5000] = {"TEXT MSG", count = 0, avg = 0 , tot = 0},
  [0x5001] = {"AP STATUS", count = 0, avg = 0 , tot = 0},
  [0x5002] = {"GPS STATUS", count = 0, avg = 0 , tot = 0},
  [0x5003] = {"BATT 1", count = 0, avg = 0 , tot = 0},
  [0x5004] = {"HOME STATUS", count = 0, avg = 0 , tot = 0},
  [0x5005] = {"VEL & YAW", count = 0, avg = 0 , tot = 0},
  [0x5006] = {"ATTI & RNG", count = 0, avg = 0 , tot = 0},
  [0x5007] = {"PARAMS", count = 0, avg = 0 , tot = 0},
  [0x5008] = {"BATT 2", count = 0, avg = 0 , tot = 0},
  [0x5009] = {"WP MavToPT", count = 0, avg = 0 , tot = 0},
  [0x500A] = {"RPM", count = 0, avg = 0 , tot = 0},
  [0x500B] = {"TERRAIN", count = 0, avg = 0 , tot = 0},
  [0x500C] = {"WIND", count = 0, avg = 0 , tot = 0},
  [0x500D] = {"WP ArduPilot", count = 0, avg = 0 , tot = 0},
  link_rate = 0
}


local conf = {
  protocol = 1 -- 1=sport, 2=crsf, 3=external sport
}

local function getTime()
  return os.clock()*100 -- 1/100th
end

local function crossfireTelemetryPop()
  --print("crsf")
  local now = getTime()
  local command, data = crsf.popFrame()
  if command == nil or data == nil then
    return
  end
  if command == CRSF_FRAME_CUSTOM_TELEM or command == CRSF_FRAME_CUSTOM_TELEM_LEGACY then
    -- actual payload starts at data[2]
    if #data >= 7 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH then
      local app_id = (data[3] << 8) + data[2]
      local value =  (data[7] << 24) + (data[6] << 16) + (data[5] << 8) + data[4]
      return 0x00, 0x10, app_id, value
    elseif #data > 4 and data[1] == CRSF_CUSTOM_TELEM_STATUS_TEXT then
      return 0x00, 0x10, 0x5000, 0x00
    elseif #data >= 8 and data[1] == CRSF_CUSTOM_TELEM_PASSTHROUGH_ARRAY then
      -- passthrough array
      local app_id, value
      for i=0, math.min(data[2]-1, 9)
      do
        app_id = (data[4+(6*i)] << 8) + data[3+(6*i)]
        value =  (data[8+(6*i)] << 24) + (data[7+(6*i)] << 16) + (data[6+(6*i)] << 8) + data[5+(6*i)]
        processTelemetry(app_id, value, now)
      end
    end
  end
  return nil, nil ,nil ,nil
end

local function passthroughTelemetryPop()
  --print("sport")
  local frame = passthroughSensor:popFrame()
  if frame == nil then
    return nil, nil, nil, nil
  end
  return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

local function processTelemetry(app_id, data, now)
  if packetStats[app_id] ~= nil then
    packetStats[app_id].tot = packetStats[app_id].tot + 1
    packetStats[app_id].count = packetStats[app_id].count + 1
  end
end


local last_refresh = getTime()

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end


local function reset()
  print("DEBUG RESET")
  for i=0x00,0x0D
  do
    packetStats[0x5000+i].count = 0
    packetStats[0x5000+i].avg = 0
    packetStats[0x5000+i].tot = 0
  end
  packetStats.link_rate = 0
  telemetryPop = passthroughTelemetryPop
  print("proto", conf.protocol)
  if conf.protocol == 2 then
    telemetryPop = crossfireTelemetryPop
  end
end

local cols = {}
local vOffset = 0
local rowHeight = 0
local font = FONT_L

local function create()
  local version = system.getVersion()

  if string.find(version.board,"X20") ~= nil then
    cols = {190, 210, 320, 430}
    vOffset = 60
    font = FONT_L
    rowHeight = 24
  elseif string.find(version.board,"X18") ~= nil then
    cols = {100, 120, 230, 300}
    vOffset = 55
    font = FONT_NORMAL
    rowHeight = 14
  else --X10
    cols = {100, 120, 230, 300}
    vOffset = 40
    font = FONT_NORMAL
    rowHeight = 14
  end

  local w,h = lcd.getWindowSize()
  local line = form.addLine("Yaapu Debug ("..'07e404e'..")")
  local slots = form.getFieldSlots(line, {0,math.floor(w*0.25), math.floor(w*0.3)})
  local command = form.addTextButton(line, slots[2], "RESET STATS", function() return reset() end)
  command:enable(true)
  local field = form.addChoiceField(line, slots[3], {{"sport",1},{"crsf",2},{"ext sport",3}}, function() return conf.protocol end,
    function(value)
      print(value, conf.protocol)
      conf.protocol=value
      reset()
    end
  )
  field:enable(true)

  reset()
end

local function paint()
  local LCD_W, LCD_H = lcd.getWindowSize()

  local link_rate = 0
  for i=0x00,0x0D
  do
    lcd.color(WHITE)
    if packetStats[0x5000+i].avg > 0 then
      lcd.color(GREEN)
    end
    lcd.drawText(cols[1], vOffset+(i*rowHeight), packetStats[0x5000+i][1], RIGHT)
    lcd.drawText(cols[2], vOffset+(i*rowHeight), string.format("0x50%02X", i))
    lcd.drawText(cols[3], vOffset+(i*rowHeight), string.format("%02.01fHz", packetStats[0x5000+i].avg))
    lcd.drawText(cols[4], vOffset+(i*rowHeight), string.format("count: %d", packetStats[0x5000+i].tot))
  end
  lcd.drawText(LCD_W, vOffset,string.format("link: %.01fHz", packetStats.link_rate), RIGHT)
end

local function wakeup(widget)
  if conf.protocol < 3 then
    for i=1,10
    do
      local physId, primId, appId, data = telemetryPop()
      --print("loop",physId, primId, appId, data)
      if primId == 0x10 then
        processTelemetry(appId, data, now)
      end
    end
  --[[
  elseif conf.protocol == 3 then
    if sportConn == nil then
      sportConn = serial.open("sport")
    else
      local buff = sportConn:read()
      for i=1,#buff
      do
        if libs.sportLib.process_byte(sportPacket, buff:byte(i)) then
          status.noTelemetryData = 0
          -- no telemetry dialog only shown once
          status.hideNoTelemetry = true
          if sportPacket.primId == 0x10 then
            libs.utils.processTelemetry(sportPacket.appId, sportPacket.data, now)
          end
        end
      end
    end
  --]]
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
  lcd.invalidate()
end

local function event(widget, category, value, x, y)
  return false
end

local icon = lcd.loadMask("mask_toolbox.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup, event=event, paint=paint})
end

return {init=init}
