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
  lcd.drawFilledRectangle(0,0, LCD_W, 28, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, utils.colors.white)
  if status.modelString ~= nil then
    local modelString = status.currentScreen == 1 and status.modelString or string.format("[%d] %s",status.currentScreen, status.modelString)
    lcd.drawText(2, 0, modelString, CUSTOM_COLOR)
  end
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, 0, strtime, SMLSIZE+RIGHT+CUSTOM_COLOR)
  if utils.telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR, utils.colors.red)
    lcd.drawText(538-23, 0, "NO TELEM", 0+CUSTOM_COLOR)
  else
    utils.drawRssi()
  end
  lcd.setColor(CUSTOM_COLOR, utils.colors.white)
  local vtx = string.format("%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(651, 0, vtx, 0+CUSTOM_COLOR+SMLSIZE)
end

function layoutLib.drawNoTelemetryData(telemetryEnabled)
  if (not utils.telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawFilledRectangle(146, 131, 506, 148, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.red)
    lcd.drawFilledRectangle(150, 134, 500, 141, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(400, 150, "no telemetry data", DBLSIZE + CUSTOM_COLOR + CENTER)
    lcd.drawText(400, 221, "Yaapu Telemetry Widget 2.2.x dev".." ("..'33fb4a0'..")", SMLSIZE + CUSTOM_COLOR + CENTER)
    libs.layoutLib.drawTopBar()
    local info = model.getInfo()
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawText(0, 0, info.name, CUSTOM_COLOR)
  end
end

function layoutLib.drawWidgetPaused()
  if conf.pauseTelemetry == true then
    lcd.setColor(CUSTOM_COLOR, BLACK)
    lcd.drawFilledRectangle(146, 123, 506, 140, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.darkyellow)
    lcd.drawFilledRectangle(150, 126, 500, 133, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, BLACK)
    lcd.drawText(400, 141, "WIDGET PAUSED", DBLSIZE + CUSTOM_COLOR + CENTER)
    lcd.drawText(400, 208, "Yaapu Telemetry Widget 2.2.x dev".." ("..'33fb4a0'..")", SMLSIZE + CUSTOM_COLOR + CENTER)
  end
end

function layoutLib.drawStatusBar(maxRows)
  local yDelta = (maxRows - 1) * 21
  local base_y = 404 - yDelta
  lcd.setColor(CUSTOM_COLOR, utils.colors.bars)
  lcd.drawFilledRectangle(0, base_y, LCD_W, LCD_H - base_y, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, utils.colors.white)
  lcd.drawTimer(LCD_W, 395 - yDelta, model.getTimer(2).value, DBLSIZE + CUSTOM_COLOR + RIGHT)
  if status.strFlightMode ~= nil then
    lcd.drawText(1, 406 - yDelta, status.strFlightMode, MIDSIZE + CUSTOM_COLOR)
  end
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(610, 402 - yDelta, telemetry.strLat, 0 + CUSTOM_COLOR + RIGHT)
    lcd.drawText(610, 422 - yDelta, telemetry.strLon, 0 + CUSTOM_COLOR + RIGHT)
  end
  local hdop = telemetry.gpsHdopC
  local flags = BLINK
  local mult = 1
  if telemetry.gpsStatus > 2 then
    if telemetry.homeAngle ~= -1 then flags = PREC1 end
    if hdop > 99 then 
        if hdop > 999 then hdop = 999 end
        flags = 0
        mult = 0.1 
    end
    lcd.drawNumber(410, 400 - yDelta, hdop * mult, DBLSIZE + flags + CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(362, 406 - yDelta, utils.gpsStatuses[telemetry.gpsStatus][1], SMLSIZE + CUSTOM_COLOR)
    lcd.drawText(362, 424 - yDelta, utils.gpsStatuses[telemetry.gpsStatus][2], SMLSIZE + CUSTOM_COLOR)
    if telemetry.numSats == 15 then
      lcd.drawNumber(350, 400 - yDelta, telemetry.numSats, DBLSIZE + CUSTOM_COLOR + RIGHT)
      lcd.drawText(350, 406 + 4 - yDelta, "+", SMLSIZE + CUSTOM_COLOR)
    else
      lcd.drawNumber(350, 400 - yDelta, telemetry.numSats, DBLSIZE + CUSTOM_COLOR + RIGHT)
    end
  elseif telemetry.gpsStatus == 0 then
    utils.drawBlinkBitmap("nogpsicon", 300, 406 - yDelta)
  else
    utils.drawBlinkBitmap("nolockicon", 300, 406 - yDelta)
  end
  local offset = math.min(maxRows, #status.messages + 1)
  local msg_start_y = 452 - yDelta
  for i = 0, offset - 1 do
    local msg_idx = (status.messageCount + i - offset) % (#status.messages + 1)
    lcd.setColor(CUSTOM_COLOR, utils.mavSeverity[status.messages[msg_idx][2]][2])
    lcd.drawText(1, msg_start_y + (21 * i), status.messages[msg_idx][1], 0 + CUSTOM_COLOR)
  end
end

return layoutLib
