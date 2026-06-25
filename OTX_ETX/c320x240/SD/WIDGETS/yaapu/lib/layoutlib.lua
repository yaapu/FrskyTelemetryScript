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
  lcd.drawFilledRectangle(0,0, 320, 14, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, utils.colors.white)
  if status.modelString ~= nil then
    local modelString = status.currentScreen == 1 and status.modelString or string.format("[%d] %s",status.currentScreen, status.modelString)
    lcd.drawText(2, 0, modelString, CUSTOM_COLOR)
  end
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(320, 0, strtime, SMLSIZE+RIGHT+CUSTOM_COLOR)
  if utils.telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR, utils.colors.red)
    lcd.drawText(213-23, 0, "NO TELEM", 0+CUSTOM_COLOR)
  else
    utils.drawRssi()
  end
  lcd.setColor(CUSTOM_COLOR, utils.colors.white)
  local vtx = string.format("%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(258, 0, vtx, 0+CUSTOM_COLOR+SMLSIZE)
end

function layoutLib.drawNoTelemetryData(telemetryEnabled)
  if (not utils.telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawFilledRectangle(30, 50, 260, 56, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.red)
    lcd.drawFilledRectangle(32, 52, 256, 52, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(160, 56, "no telemetry data", DBLSIZE + CUSTOM_COLOR + CENTER)
    lcd.drawText(160, 83, "Yaapu Telemetry Widget 2.2.x dev".." ("..'2964276'..")", SMLSIZE + CUSTOM_COLOR + CENTER)
    libs.layoutLib.drawTopBar()
    local info = model.getInfo()
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawText(0, 0, info.name, CUSTOM_COLOR)
  end
end

function layoutLib.drawWidgetPaused()
  if conf.pauseTelemetry == true then
    lcd.setColor(CUSTOM_COLOR, BLACK)
    lcd.drawFilledRectangle(58, 49, 201, 55, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.darkyellow)
    lcd.drawFilledRectangle(60, 51, 198, 53, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, BLACK)
    lcd.drawText(160, 56, "WIDGET PAUSED", DBLSIZE + CUSTOM_COLOR + CENTER)
    lcd.drawText(160, 83, "Yaapu Telemetry Widget 2.2.x dev".." ("..'2964276'..")", SMLSIZE + CUSTOM_COLOR + CENTER)
  end
end

function layoutLib.drawStatusBar(maxRows)
  local yDelta = (maxRows - 1) * 12
  local base_y = 194 - yDelta
  lcd.setColor(CUSTOM_COLOR, utils.colors.bars)
  lcd.drawFilledRectangle(0, base_y, 320, 240 - base_y, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, utils.colors.white)
  lcd.drawTimer(320, 202 - yDelta, model.getTimer(2).value, DBLSIZE + CUSTOM_COLOR + RIGHT)
  if status.strFlightMode ~= nil then
    lcd.drawText(1, 204 - yDelta, status.strFlightMode, MIDSIZE + CUSTOM_COLOR)
  end
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(320, 192 - yDelta, telemetry.strLat .. "    " .. telemetry.strLon, 0 + CUSTOM_COLOR + RIGHT)
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
    lcd.drawNumber(173, 206 - yDelta, hdop * mult, MIDSIZE + flags + CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(140, 208 - yDelta, utils.gpsStatuses[telemetry.gpsStatus][1], SMLSIZE + CUSTOM_COLOR)
    lcd.drawText(140, 216 - yDelta, utils.gpsStatuses[telemetry.gpsStatus][2], SMLSIZE + CUSTOM_COLOR)
    if telemetry.numSats == 15 then
      lcd.drawNumber(132, 206 - yDelta, telemetry.numSats, MIDSIZE + CUSTOM_COLOR + RIGHT)
      lcd.drawText(132, 208 + 6 - yDelta, "+", CUSTOM_COLOR)
    else
      lcd.drawNumber(132, 206 - yDelta, telemetry.numSats, MIDSIZE + CUSTOM_COLOR + RIGHT)
    end
  elseif telemetry.gpsStatus == 0 then
    utils.drawBlinkBitmap("nogpsicon", 88, 190 - yDelta)
  else
    utils.drawBlinkBitmap("nolockicon", 88, 190 - yDelta)
  end
  local offset = math.min(maxRows, #status.messages + 1)
  local msg_start_y = 226 - yDelta
  for i = 0, offset - 1 do
    local msg_idx = (status.messageCount + i - offset) % (#status.messages + 1)
    lcd.setColor(CUSTOM_COLOR, utils.mavSeverity[status.messages[msg_idx][2]][2])
    lcd.drawText(1, msg_start_y + (12 * i), status.messages[msg_idx][1], 0 + CUSTOM_COLOR)
  end
end

return layoutLib

