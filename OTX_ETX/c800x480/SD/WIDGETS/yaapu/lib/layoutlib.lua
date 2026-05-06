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
    lcd.drawText(2, 4, modelString, CUSTOM_COLOR)
  end
  -- flight time
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, 8, strtime, RIGHT+CUSTOM_COLOR)
  -- tx voltage
  local vtx = string.format("%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(680, 8, vtx, RIGHT+CUSTOM_COLOR)
  -- RSSI
  if utils.telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawText(540, 8, "NO TELEM", RIGHT+CUSTOM_COLOR)
  else
    utils.drawRssi()
  end
end

function layoutLib.drawNoTelemetryData(telemetryEnabled)
  -- no telemetry data (ETHOS: 92,98, 600x140)
  if (not utils.telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawFilledRectangle(90,96, 604, 144, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawFilledRectangle(92,98, 600, 140, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(392, 115, "no telemetry data", DBLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(392, 180, "Yaapu Telemetry Widget 2.1.x dev".." ("..'7a17b47'..")", SMLSIZE+CUSTOM_COLOR+CENTER)
    libs.layoutLib.drawTopBar()
    local info = model.getInfo()
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(0,4,info.name,CUSTOM_COLOR)
  end
end

function layoutLib.drawWidgetPaused()
  if conf.pauseTelemetry == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawFilledRectangle(90,96, 604, 144, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    lcd.drawFilledRectangle(92,98, 600, 140, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawText(392, 115, "WIDGET PAUSED", DBLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(392, 180, "Yaapu Telemetry Widget 2.1.x dev".." ("..'7a17b47'..")", SMLSIZE+CUSTOM_COLOR+CENTER)
  end
end

function layoutLib.drawStatusBar(maxRows)
  local msgAreaH = 2 + maxRows*20
  local msgTop = LCD_H - msgAreaH
  local barTop = msgTop - 48

  lcd.setColor(CUSTOM_COLOR,utils.colors.bars)
  lcd.drawFilledRectangle(0,barTop,800,LCD_H-barTop,CUSTOM_COLOR)
  -- flight time (ETHOS: FONT_XXL at y+0, 48px bar)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawTimer(LCD_W, barTop+4, model.getTimer(2).value, DBLSIZE+CUSTOM_COLOR+RIGHT)
  -- flight mode
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.strFlightMode ~= nil then
    lcd.drawText(1,barTop+4,status.strFlightMode,DBLSIZE+CUSTOM_COLOR)
  end
  -- gps status, draw coordinatyes if good at least once
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(620, barTop+4, telemetry.strLat, SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(620, barTop+22, telemetry.strLon, SMLSIZE+CUSTOM_COLOR+RIGHT)
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
    lcd.drawNumber(425,barTop+4, hdop*mult,DBLSIZE+flags+CUSTOM_COLOR)
    -- SATS
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(380,barTop+6, utils.gpsStatuses[telemetry.gpsStatus][1], SMLSIZE+CUSTOM_COLOR)
    lcd.drawText(380,barTop+22, utils.gpsStatuses[telemetry.gpsStatus][2], SMLSIZE+CUSTOM_COLOR)

    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    if telemetry.numSats == 15 then
      lcd.drawNumber(325,barTop+4, telemetry.numSats, DBLSIZE+CUSTOM_COLOR+RIGHT)
      lcd.drawText(340,barTop+4, "+", SMLSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(325,barTop+4,telemetry.numSats, DBLSIZE+CUSTOM_COLOR+RIGHT)
    end
  elseif telemetry.gpsStatus == 0 then
    utils.drawBlinkBitmap("nogpsicon",322,barTop+8)
  else
    utils.drawBlinkBitmap("nolockicon",322,barTop+8)
  end

  local offset = math.min(maxRows,#status.messages+1)
  for i=0,offset-1 do
    lcd.setColor(CUSTOM_COLOR,utils.mavSeverity[status.messages[(status.messageCount + i - offset) % (#status.messages+1)][2]][2])
    lcd.drawText(1,msgTop+(19*i), status.messages[(status.messageCount + i - offset) % (#status.messages+1)][1],SMLSIZE+CUSTOM_COLOR)
  end
end

return layoutLib
