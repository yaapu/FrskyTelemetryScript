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

local function drawExtendedStatusBar(drawLib,conf,telemetry,status,battery,alarms,frame,utils)
  -- LEFT label
  lcd.setColor(CUSTOM_COLOR,utils.colors.black)
  lcd.drawText(153,165,"Alt("..unitLabel..")",SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.drawText(68,165,"VSI("..conf.vertSpeedLabel..")",SMLSIZE+CUSTOM_COLOR+RIGHT)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  if math.abs(alt) > 999 then
    lcd.drawNumber(153,178,alt,MIDSIZE+RIGHT+CUSTOM_COLOR)
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber(153,178,alt,MIDSIZE+RIGHT+CUSTOM_COLOR)
  else
    lcd.drawNumber(153,178,alt*10,MIDSIZE+RIGHT+PREC1+CUSTOM_COLOR)
  end
  -- vertical speed
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 * conf.vertSpeedMultiplier
  if (math.abs(telemetry.vSpeed) >= 10) then
    lcd.drawNumber(68,178, vSpeed ,MIDSIZE+RIGHT+CUSTOM_COLOR)
  else
    lcd.drawNumber(68,178,vSpeed*10,MIDSIZE+RIGHT+PREC1+CUSTOM_COLOR)
  end
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(3, 178 + 3,true,false,utils)
    drawLib.drawVArrow(68-70, 178 + 3,true,false,utils)
  end

end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,leftPanel,centerPanel,rightPanel)
  if leftPanel ~= nil and centerPanel ~= nil and rightPanel ~= nil then
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    drawLib.drawRArrow((LCD_W/2),180,22,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
    centerPanel.drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils,customSensors)
    -- with dual battery default is to show aggregate view
    if status.batt2sources.fc or status.batt2sources.vs then
      if status.showDualBattery == false then
        -- dual battery: aggregate view
        rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,0,utils,customSensors)
        -- left panel
        leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,utils,customSensors)
      else
        -- dual battery:battery 1 right pane
        rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,1,utils,customSensors)
        -- dual battery:battery 2 left pane
        rightPanel.drawPane(-37,drawLib,conf,telemetry,status,alarms,battery,2,utils,customSensors)
      end
    else
      -- battery 1 right pane in single battery mode
      rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,1,utils,customSensors)
        -- left panel
      leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,utils,customSensors)
    end
  end
  drawLib.drawStatusBar(3,conf,telemetry,status,battery,alarms,frame,utils)
  drawExtendedStatusBar(drawLib,conf,telemetry,status,battery,alarms,frame,utils)
  utils.drawTopBar()
  drawLib.drawFailsafe(telemetry,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
end

return {draw=draw}

