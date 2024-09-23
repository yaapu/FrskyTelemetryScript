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

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

local layout = {}

local conf
local telemetry
local status
local utils
local libs

function layout.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

local function drawMiniHud(x,y)
  libs.drawLib.drawArtificialHorizon(x, y, 48, 36, nil, lcd.RGB(0x7B, 0x9D, 0xFF), lcd.RGB(0x63, 0x30, 0x00), 6, 6.5, 1.3)
  lcd.drawBitmap(utils.getBitmap("hud_48x48a"), 3-1, 22-10)
end

local flipFlop = true

local function drawTelemetryBar(widget)
  local colorLabel = lcd.RGB(140,140,140)
  -- CELL
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 20-3, string.upper(status.battsource).." V", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  if status.battery[1] * 0.01 < 10 then
    lcd.drawNumber(LCD_W-2, 20+7, status.battery[1] + 0.5, PREC2+MIDSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(LCD_W-2, 20+7, (status.battery[1] + 0.5)*0.1, PREC1+MIDSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- aggregate batt %
  local strperc = string.format("%2d", status.battery[16])
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-4, 60-3, "BATT %", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-4, 60+7, strperc, MIDSIZE+CUSTOM_COLOR+RIGHT)

  -- alt
  local alt = telemetry.homeAlt * unitScale
  local altLabel = "ALT"
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    altLabel = "HAT"
  end
  lcd.drawBitmap(utils.getBitmap("graph_bg_120x48"),278, 192)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(278+118,192-2,altLabel.." "..unitLabel,SMLSIZE+CUSTOM_COLOR+RIGHT)
  local lastY = libs.drawLib.drawGraph("map_alt", 278-4, 192, 120, 48, utils.colors.darkyellow, alt, false, false, nil, nil)
  local altMin = libs.drawLib.getGraphMin("map_alt")
  local altMax = libs.drawLib.getGraphMax("map_alt")
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawText(278,192+9,string.format("%d",alt),MIDSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(190,190,190))
  lcd.drawText(278,192+32,string.format("%d",altMin),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(278,192-3,string.format("%d",altMax),SMLSIZE+CUSTOM_COLOR)

  -- speed
  local speed = telemetry.hSpeed * 0.1 * conf.horSpeedMultiplier
  local speedLabel = "GSPD"
  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    speedLabel = "ASPD"
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 100-3, string.format("%s %s", speedLabel, conf.horSpeedLabel), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-2, 100+7, string.format("%.01f",speed), MIDSIZE+CUSTOM_COLOR+RIGHT)
  -- home distance
  local label = unitLabel
  local dist = telemetry.homeDist
  local flags = 0
  if dist*unitScale > 999 then
    flags = flags + PREC2
    dist = dist*unitLongScale*100
    label = unitLongLabel
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 140-3, string.format("HOME %s", label), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawNumber(LCD_W-2, 140+7, dist, MIDSIZE+flags+CUSTOM_COLOR+RIGHT)

  -- home angle
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  libs.drawLib.drawRVehicle(450,194,18,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
end

function layout.draw(widget)
  libs.mapLib.drawMap(widget, 0, 18, 480, 250, status.mapZoomLevel, 4, 3)
  if status.wpEnabledMode == 1 and status.wpEnabled == 1 and telemetry.wpNumber > 0 then
    -- wp number and distance
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawBitmap(utils.getBitmap("maps_box_60x22"),396-58,21-1)
    lcd.drawBitmap(utils.getBitmap("maps_box_60x22"),396-58,21+23)

    lcd.drawText(396, 21, string.format("#%d", telemetry.wpNumber),CUSTOM_COLOR+RIGHT)
    lcd.drawText(396, 21+22, string.format("%d%s", telemetry.wpDistance * unitScale,unitLabel),CUSTOM_COLOR+RIGHT)
  end
  drawTelemetryBar(widget)
  drawMiniHud(3, 22)
  libs.layoutLib.drawTopBar()
  libs.layoutLib.drawStatusBar(2)
  -- wind
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawBitmap(utils.getBitmap("maps_box_60x22"),60,22)
    lcd.drawBitmap(utils.getBitmap("maps_box_60x22"),60+60,22)
    lcd.drawText(60+30, 22, string.format("%.01f %s", telemetry.trueWindSpeed*conf.horSpeedMultiplier*0.1,conf.horSpeedLabel),CUSTOM_COLOR)
    libs.drawLib.drawRArrow(60+15,22+11,8,5,45,telemetry.trueWindAngle-180,CUSTOM_COLOR)
  end

  local nextX = libs.drawLib.drawTerrainStatus(4, 60)
  libs.drawLib.drawFenceStatus(nextX, 60)
  --]]
end

function layout.background(widget)
  libs.drawLib.updateGraph("map_alt", telemetry.homeAlt)
end

return layout

