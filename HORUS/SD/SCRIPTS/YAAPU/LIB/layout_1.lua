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


local customSensorXY = {
  { 80, 193, 80, 203},
  { 160, 193, 160, 203},
  { 240, 193, 240, 203},
  { 320, 193, 320, 203},
  { 400, 193, 400, 203},
  { 480, 193, 480, 203},
}

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,leftPanel,centerPanel,rightPanel)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  centerPanel.drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  drawLib.drawRArrow(240,174,20,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
  -- with dual battery default is to show aggregate view
  if status.batt2sources.fc or status.batt2sources.vs then
    if status.showDualBattery == false then
      -- dual battery: aggregate view
      rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,0,utils)
      -- left pane info
      leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,utils)
    else
      -- dual battery:battery 1 right pane
      rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,1,utils)
      -- dual battery:battery 2 left pane
      rightPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,2,utils)
    end
  else
    -- battery 1 right pane in single battery mode
    rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,1,utils)
    -- left pane info  in single battery mode
    leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,utils)
  end
  -- throttle %
  lcd.setColor(CUSTOM_COLOR,utils.colors.black)
  lcd.drawText(315, 154, "Thr(%)", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawNumber(310,165,telemetry.throttle,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.black)
  -- RPM 1
  if conf.enableRPM == 2  or conf.enableRPM == 3 then
    lcd.drawText(92, 154, "RPM 1", SMLSIZE+RIGHT+CUSTOM_COLOR)
    drawLib.drawBar("rpm1", 4, 169, 86, 22, utils.colors.darkyellow, math.abs(telemetry.rpm1), MIDSIZE)
  end
  -- RPM 2
  if conf.enableRPM == 3 then
    lcd.drawText(192, 154, "RPM 2", SMLSIZE+RIGHT+CUSTOM_COLOR)
    drawLib.drawBar("rpm2", 104, 169, 86, 22, utils.colors.darkyellow, math.abs(telemetry.rpm2), MIDSIZE)
  end

  utils.drawTopBar()
  local msgRows = 4
  if customSensors ~= nil then
    msgRows = 1
    -- draw custom sensors
    drawLib.drawCustomSensors(0,customSensors,customSensorXY,utils,status,utils.colors.lightgrey)
  end
  drawLib.drawStatusBar(msgRows,conf,telemetry,status,battery,alarms,frame,utils)
  drawLib.drawFailsafe(telemetry,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
  local nextX = drawLib.drawTerrainStatus(utils,status,telemetry,101,19)
  drawLib.drawFenceStatus(utils,status,telemetry,nextX,19)
--]]
  lcd.setColor(CUSTOM_COLOR,WHITE)
end
return {draw=draw}

