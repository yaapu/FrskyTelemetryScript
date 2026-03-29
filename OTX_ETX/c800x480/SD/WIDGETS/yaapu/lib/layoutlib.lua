--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Horus class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

local layoutLib = {}

local status
local telemetry
local conf
local utils
local libs

-- cached values to avoid per-frame lookups
local txVoltageFieldId = nil
local cachedTimeStr = "00:00:00"
local lastTimeSec = -1

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

function layoutLib.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

function layoutLib.drawTopBar()
  lcd.setColor(CUSTOM_COLOR, utils.colors.bars)
  -- black bar
  lcd.drawFilledRectangle(0,0, LCD_W, 30, CUSTOM_COLOR)
  -- frametype and model name
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.modelString ~= nil then
    local modelString = status.currentScreen == 1 and status.modelString or string.format("[%d] %s",status.currentScreen, status.modelString)
    lcd.drawText(2, 3, modelString, CUSTOM_COLOR)
  end
  -- flight time
  local time = getDateTime()
  if time.sec ~= lastTimeSec then
    cachedTimeStr = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
    lastTimeSec = time.sec
  end
  lcd.drawText(LCD_W, 3, cachedTimeStr, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- RSSI
  if utils.telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawText(500, 3, "NO TELEM", 0+CUSTOM_COLOR)
  else
    utils.drawRssi()
  end
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- tx voltage
  if txVoltageFieldId == nil then
    local fi = getFieldInfo("tx-voltage")
    if fi then txVoltageFieldId = fi.id end
  end
  local vtx = txVoltageFieldId and string.format("%.1fv",getValue(txVoltageFieldId)) or "---"
  lcd.drawText(652,3, vtx, 0+CUSTOM_COLOR+SMLSIZE)
end

function layoutLib.drawNoTelemetryData(telemetryEnabled)
  -- no telemetry data
  if (not utils.telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawFilledRectangle(147,131, 507, 148, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawFilledRectangle(150,134, 500, 142, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(400, 155, "no telemetry data", DBLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(400, 210, "Yaapu Telemetry Widget 2.1.x dev".." (".."7a17b47"..")", SMLSIZE+CUSTOM_COLOR+CENTER)
    libs.layoutLib.drawTopBar()
    local info = model.getInfo()
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(0,3,info.name,CUSTOM_COLOR)
  end
end

function layoutLib.drawWidgetPaused()
  if conf.pauseTelemetry == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawFilledRectangle(147,131, 507, 148, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    lcd.drawFilledRectangle(150,134, 500, 142, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawText(400, 155, "WIDGET PAUSED", DBLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(400, 210, "Yaapu Telemetry Widget 2.1.x dev".." (".."7a17b47"..")", SMLSIZE+CUSTOM_COLOR+CENTER)
  end
end

function layoutLib.drawStatusBar(maxRows)
  local yDelta = (maxRows-1)*20

  lcd.setColor(CUSTOM_COLOR,utils.colors.bars)
  lcd.drawFilledRectangle(0,404-yDelta,800,LCD_H-(404-yDelta),CUSTOM_COLOR)
  -- flight time
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawTimer(LCD_W, 396-yDelta, model.getTimer(2).value, DBLSIZE+CUSTOM_COLOR+RIGHT)
  -- flight mode
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.strFlightMode ~= nil then
    lcd.drawText(1,406-yDelta,status.strFlightMode,MIDSIZE+CUSTOM_COLOR)
  end
  -- gps status, draw coordinates if good at least once
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(625, 400-yDelta, telemetry.strLat, SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(625, 424-yDelta, telemetry.strLon, SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- gps status
  local hdop = telemetry.gpsHdopC
  local strStatus = utils.gpsStatuses[telemetry.gpsStatus]
  local flags = BLINK
  local mult = 1

  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if hdop > 999 then
      hdop = 999
      flags = 0
      mult=0.1
    elseif hdop > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawNumber(407,398-yDelta, hdop*mult,DBLSIZE+flags+CUSTOM_COLOR)
    -- SATS
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(343,406-yDelta, utils.gpsStatuses[telemetry.gpsStatus][1], SMLSIZE+CUSTOM_COLOR)
    lcd.drawText(343,426-yDelta, utils.gpsStatuses[telemetry.gpsStatus][2], SMLSIZE+CUSTOM_COLOR)

    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    if telemetry.numSats == 15 then
      lcd.drawNumber(330,398-yDelta, telemetry.numSats, DBLSIZE+CUSTOM_COLOR+RIGHT)
      lcd.drawText(330,412-yDelta, "+", SMLSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(330,398-yDelta,telemetry.numSats, DBLSIZE+CUSTOM_COLOR+RIGHT)
    end
  elseif telemetry.gpsStatus == 0 then
    utils.drawBlinkBitmap("nogpsicon",250,393-yDelta)
  else
    utils.drawBlinkBitmap("nolockicon",250,393-yDelta)
  end

  local offset = math.min(maxRows,#status.messages+1)
  for i=0,offset-1 do
    lcd.setColor(CUSTOM_COLOR,utils.mavSeverity[status.messages[(status.messageCount + i - offset) % (#status.messages+1)][2]][2])
    lcd.drawText(1,(448-yDelta)+(20*i), status.messages[(status.messageCount + i - offset) % (#status.messages+1)][1],SMLSIZE+CUSTOM_COLOR)
  end
end

return layoutLib
