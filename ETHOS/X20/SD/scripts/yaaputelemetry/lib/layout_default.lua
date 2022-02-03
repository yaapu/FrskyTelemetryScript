--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Ethos OS
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

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local panel = {}
local status = nil
local libs = nil

function panel.draw(widget)
  widget.centerPanel.draw(widget)
  widget.leftPanel.draw(widget, 0)
  widget.rightPanel.draw(widget, 538)
  -- home directory arrow
  libs.drawLib.drawRArrow(485, 204, 26, math.floor(status.telemetry.homeAngle - status.telemetry.yaw),status.colors.white)
  libs.drawLib.drawRArrow(485, 204, 30, math.floor(status.telemetry.homeAngle - status.telemetry.yaw),status.colors.black)

  -- RPM 1
  if status.conf.enableRPM == 2  or status.conf.enableRPM == 3 then
    lcd.color(status.colors.panelLabel)
    lcd.font(FONT_S)
    lcd.drawText(117, 181, "RPM 1", RIGHT)
    libs.drawLib.drawBar("rpm1", 10, 197, 105, 32, status.colors.rpmBar, math.abs(status.telemetry.rpm1), FONT_XL)
  end
  -- RPM 2
  if status.conf.enableRPM == 3 then
    lcd.color(status.colors.panelLabel)
    lcd.font(FONT_S)
    lcd.drawText(238, 181, "RPM 2", RIGHT)
    libs.drawLib.drawBar("rpm2", 128, 197, 105, 32, status.colors.rpmBar, math.abs(status.telemetry.rpm2), FONT_XL)
  end
  -- throttle %
  lcd.color(status.colors.hudText)
  lcd.font(FONT_S)
  lcd.drawText(311, 216, "%")
  libs.drawLib.drawNumber(313, 200, status.telemetry.throttle, 0, FONT_XL, status.colors.hudText, RIGHT)

  -- efficiency (check if hidden by another panel)
  if status.hideEfficiency == 0 then
    lcd.color(status.colors.panelLabel)
    lcd.font(FONT_S)
    lcd.drawText(660, 187, "Eff(mAh)", RIGHT)
    local speed = libs.utils.getMaxValue(status.telemetry.hSpeed,14)
    -- efficiency for indipendent batteries makes sense only for battery 1
    local eff = speed > 2 and status.battery[7]*1000/(speed*status.conf.horSpeedMultiplier) or 0
    libs.drawLib.drawNumber(660, 200, eff, 0, FONT_XL, status.colors.white, RIGHT)
  end
  -- power (check if hidden by another panel)
  if status.hidePower == 0 then
    lcd.color(status.colors.panelLabel)
    lcd.font(FONT_S)
    lcd.drawText(780, 187, "Power(W)", RIGHT)
    local power = status.battery[4]*status.battery[7]*0.01
    libs.drawLib.drawNumber(780, 200, power, 0, FONT_XL, status.colors.white, RIGHT)
  end

  libs.drawLib.drawStatusBar(widget,4)
  local nextX = libs.drawLib.drawTerrainStatus(248,38)
  libs.drawLib.drawFenceStatus(nextX,38)

  lcd.font(FONT_XS)
  lcd.color(status.colors.green)
  lcd.drawText(784, 302, "default", RIGHT)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
