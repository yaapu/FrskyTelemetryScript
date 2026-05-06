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

local customSensorXY = {
  { 100, 290, 100, 300},
  { 200, 290, 200, 300},
  { 300, 290, 300, 300},
  { 400, 290, 400, 300},
  { 500, 290, 500, 300},
  { 600, 290, 600, 300},
  { 700, 290, 700, 300},
  { 800, 290, 800, 300},
  boxY = 290
}

function layout.draw(widget, customSensors, leftPanel, centerPanel, rightPanel)
  local colorLabel = lcd.RGB(140, 140, 140)
  -- reset visibility, panels can override this
  status.hidePower = 0
  status.hideEfficiency = 0
  -- center panel
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  centerPanel[status.currentScreen].draw(widget)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  -- home direction arrow (ETHOS: two arrows at 400,314 r=28/35)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  libs.drawLib.drawRVehicle(400,314,28,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,BLACK)
  libs.drawLib.drawRVehicle(400,314,35,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  local battIdForPower = 1
  -- with dual battery default is to show aggregate view
  if status.batt2sources.fc or status.batt2sources.vs then
    if status.showDualBattery == false then
      -- dual battery: aggregate view (ETHOS right panel at x=600)
      rightPanel[status.currentScreen].draw(widget, 600, 36, 0)
      -- left pane info
      leftPanel[status.currentScreen].draw(widget, 0, 36, 0)
      battIdForPower = 0
    else
      -- dual battery:battery 1 right pane
      rightPanel[status.currentScreen].draw(widget, 600, 36, 1)
      -- dual battery:battery 2 left pane
      rightPanel[status.currentScreen].draw(widget, 600, 36, 2)
    end
  else
    -- battery 1 right pane in single battery mode
    rightPanel[status.currentScreen].draw(widget, 600, 36, 1)
    -- left pane info  in single battery mode
    leftPanel[status.currentScreen].draw(widget, 0, 36, 0)
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  -- RPM 1 (ETHOS: x=15, y=280/305 -> 262/287)
  if conf.enableRPM == 2  or conf.enableRPM == 3 then
    lcd.drawText(170, 280, "RPM 1", SMLSIZE+CUSTOM_COLOR+RIGHT)
    libs.drawLib.drawBar("rpm1", 15, 305, 150, 42, utils.colors.darkyellow, math.abs(telemetry.rpm1), MIDSIZE)
  end
  -- RPM 2 (ETHOS: x=180, y=280/305 -> 262/287)
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  if conf.enableRPM == 3 then
    lcd.drawText(335, 280, "RPM 2", SMLSIZE+CUSTOM_COLOR+RIGHT)
    libs.drawLib.drawBar("rpm2", 180, 305, 150, 42, utils.colors.darkyellow, math.abs(telemetry.rpm2), MIDSIZE)
  end
  -- throttle % (ETHOS: x=520, y=280/306 -> 262/288)
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(520, 280, "THR %", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawNumber(520,306,telemetry.throttle,MIDSIZE+RIGHT+CUSTOM_COLOR)
  -- efficiency (ETHOS: x=656, y=280/306 -> 262/288)
  if status.hideEfficiency == 0 then
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    lcd.drawText(656, 280, "EFF mAh", SMLSIZE+CUSTOM_COLOR+RIGHT)
    local speed = utils.getMaxValue(telemetry.hSpeed,14)
    -- efficiency for indipendent batteries makes sense only for battery 1
    local eff = speed > 2 and status.battery[7+battIdForPower]*1000/(speed*conf.horSpeedMultiplier) or 0
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawNumber(656,306+(eff > 9999 and 7 or 0),eff,(eff > 9999 and 0 or MIDSIZE)+RIGHT+CUSTOM_COLOR)
  end
  -- power (ETHOS: x=794, y=280/306 -> 262/288)
  if status.hidePower == 0 then
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    local power = status.battery[4+battIdForPower]*status.battery[7+battIdForPower]*0.01
    local powerUnit = (power > 999) and "kW" or "W"
    local flags = (power > 999) and PREC2 or 0
    lcd.drawText(794, 280, string.format("PWR %s",powerUnit), SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawNumber(794,306,power*(power > 999 and 0.1 or 1),MIDSIZE+RIGHT+CUSTOM_COLOR+flags)
  end
  libs.layoutLib.drawTopBar()
  local msgRows = 4
  if customSensors ~= nil then
    msgRows = 1
    -- draw custom sensors
    libs.drawLib.drawCustomSensors(customSensors, customSensorXY, utils.colors.lightgrey)
  end
  libs.layoutLib.drawStatusBar(msgRows)
  local nextX = libs.drawLib.drawTerrainStatus(205, 38)
  libs.drawLib.drawFenceStatus(nextX,38)
  lcd.setColor(CUSTOM_COLOR,WHITE)
end

return layout
