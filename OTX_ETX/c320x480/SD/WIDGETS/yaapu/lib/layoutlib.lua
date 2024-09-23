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
  lcd.drawFilledRectangle(0,0, LCD_W, 36, CUSTOM_COLOR)
  -- frametype and model name
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.modelString ~= nil then
    local modelString = status.currentScreen == 1 and status.modelString or string.format("[%d] %s",status.currentScreen, status.modelString)
    lcd.drawText(2, 0, modelString, CUSTOM_COLOR)
  end
  -- flight time
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, 0, strtime, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- RSSI
  if utils.telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawText(200-23, 18, "NO TELEM", 0+CUSTOM_COLOR)
  else
    utils.drawRssi()
  end
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- tx voltage
  local vtx = string.format("%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(LCD_W,18, vtx, 0+CUSTOM_COLOR+SMLSIZE+RIGHT)
end

function layoutLib.drawNoTelemetryData(telemetryEnabled)
  -- no telemetry data
  if (not utils.telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawFilledRectangle(28,44, 264, 84, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawFilledRectangle(30,46, 260, 80, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(160, 55, "no telemetry", DBLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(160, 95, "Yaapu Telemery 2.0.x dev".." ("..'1997425'..")", SMLSIZE+CUSTOM_COLOR+CENTER)
    libs.layoutLib.drawTopBar()
    local info = model.getInfo()
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(0,0,info.name,CUSTOM_COLOR)
  end
end

function layoutLib.drawWidgetPaused()
  if conf.pauseTelemetry == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawFilledRectangle(88,44, 304, 84, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    lcd.drawFilledRectangle(90,46, 300, 80, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawText(160, 55, "WIDGET PAUSED", DBLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(160, 95, "Yaapu Telemetry Widget 2.0.x dev".." ("..'1997425'..")", SMLSIZE+CUSTOM_COLOR+CENTER)
  end
end

function layoutLib.drawStatusBar(maxRows)
  local yDelta = maxRows*12
  local yMax = LCD_H-43-yDelta
  
  lcd.setColor(CUSTOM_COLOR,utils.colors.bars)
  lcd.drawFilledRectangle(0,yMax,LCD_W,LCD_H-yMax,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.bars)
  -- flight time
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawTimer(LCD_W, yMax-4, model.getTimer(2).value, DBLSIZE+CUSTOM_COLOR+RIGHT)
  -- flight mode
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.strFlightMode ~= nil then
    lcd.drawText(1,yMax+1,status.strFlightMode,MIDSIZE+CUSTOM_COLOR)
  end
  -- gps status, draw coordinatyes if good at least once
  lcd.setColor(CUSTOM_COLOR,utils.colors.green)
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(LCD_W-4, yMax+26, telemetry.strLat.."    "..telemetry.strLon, SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- gps status
  local hdop = telemetry.gpsHdopC
  local strStatus = utils.gpsStatuses[telemetry.gpsStatus]
  local flags = BLINK
  local mult = 1

  if telemetry.gpsStatus  > 2 then
    lcd.setColor(CUSTOM_COLOR,utils.colors.green)
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
    lcd.drawBitmap(utils.getBitmap("hdop"),202,yMax+7)
    lcd.drawNumber(200,yMax, hdop*mult,MIDSIZE+flags+CUSTOM_COLOR+RIGHT)
    -- SATS
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(156,yMax+26, utils.gpsStatuses[telemetry.gpsStatus][1]..utils.gpsStatuses[telemetry.gpsStatus][2], SMLSIZE+CUSTOM_COLOR+RIGHT)

    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    if telemetry.numSats == 15 then
      lcd.drawNumber(156,yMax, telemetry.numSats, MIDSIZE+CUSTOM_COLOR+RIGHT)
      lcd.drawText(156,yMax, "+", SMLSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(156,yMax,telemetry.numSats, MIDSIZE+CUSTOM_COLOR+RIGHT)
    end
  elseif telemetry.gpsStatus == 0 then
    utils.drawBlinkBitmap("gpsicon",145,yMax+2)
  else
    utils.drawBlinkBitmap("gpsicon",145,yMax+2)
  end

  local offset = math.min(maxRows,#status.messages+1)
  for i=0,offset-1 do
    lcd.setColor(CUSTOM_COLOR,utils.mavSeverity[status.messages[(status.messageRow + i - offset) % (#status.messages+1)][2]][2])
    lcd.drawText(1,LCD_H-yDelta-4+(12*i), status.messages[(status.messageRow + i - offset) % (#status.messages+1)][1],SMLSIZE+CUSTOM_COLOR)
  end
end

return layoutLib
