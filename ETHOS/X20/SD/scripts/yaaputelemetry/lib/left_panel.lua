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

function panel.draw(widget,x)
  --[[
  lcd.color(255,0,255)
  lcd.font(XXL)
  lcd.drawText(0, 20, "XXL")
  lcd.font(XL)
  lcd.drawText(0, 60, "XL")
  lcd.font(L)
  lcd.drawText(0, 90, "L")
  lcd.font(STD)
  lcd.drawText(0, 110, "STD")
  lcd.font(BOLD)
  lcd.drawText(80, 110, "BOLD")
  lcd.font(ITALIC)
  lcd.drawText(220, 110, "ITALIC",RIGHT)
  lcd.font(S)
  lcd.drawText(5, 130, "S")
  lcd.font(XS)
  lcd.drawText(5, 150, "XS")
  --]]
  -- 245 x 168
  lcd.color(status.colors.panelLabel)
  lcd.font(FONT_S)
  lcd.drawText(110, 40, "Range ("..status.conf.distUnitLabel..")", RIGHT)
  if status.conf.rangeFinderMax > 0 then
    local rng = status.telemetry.range
    rng = libs.utils.getMaxValue(rng,16)
    if rng > status.conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.color(status.colors.red)
      lcd.pen(SOLID)
      lcd.drawFilledRectangle(20, 56, 90,38)
    end
    lcd.color(status.colors.panelText)
    lcd.font(FONT_XXL)
    if rng*0.01*status.conf.distUnitScale < 10 then
      lcd.drawText(110,55, string.format("%.1f",rng*0.01*status.conf.distUnitScale), RIGHT)
    else
        lcd.drawText(110,55, string.format("%.0f",rng*0.01*status.conf.distUnitScale), RIGHT)
    end
  else
    lcd.color(status.colors.panelText)
    lcd.font(FONT_XXL)
    lcd.drawText(110,55, "---", RIGHT)
  end
  -- always display gps altitude even without 3d lock
  local blink = true
  local alt = status.telemetry.gpsAlt/10
  if status.telemetry.gpsStatus  > 2 then
    -- update max only with 3d or better lock
    alt = libs.utils.getMaxValue(alt,12)
    blink = false
  end
  if status.showMinMaxValues == true then
    blink = false
  end
  lcd.color(status.colors.panelLabel)
  lcd.font(FONT_S)
  lcd.drawText(238, 40, "GPSAlt ("..status.conf.distUnitLabel..")", RIGHT)
  local stralt = string.format("%.0f",alt*status.conf.distUnitScale)
  local font = FONT_XXL
  local offset = 0
  if alt*status.conf.distUnitScale > 9999 then
    font = FONT_XL
    offset = 9
  end
  libs.drawLib.drawText(238, 55 + offset, status.telemetry.gpsStatus > 2 and stralt or "---", font, status.colors.panelText, RIGHT, blink)
  -- LABELS
  -- VALUES
  -- home distance
  blink = false
  if status.telemetry.homeAngle == -1 then
    blink = true
  end
  lcd.color(status.colors.panelLabel)
  lcd.font(FONT_S)
  local dist = libs.utils.getMaxValue(status.telemetry.homeDist,15)
  local strdist = string.format("%.0f",dist*status.conf.distUnitScale)
  if dist*status.conf.distUnitScale > 999 then
    lcd.drawText(110, 116, "Home ("..status.conf.distUnitLongLabel..")", RIGHT)
    strdist = string.format("%.02f",dist*status.conf.distUnitLongScale)
  else
    lcd.drawText(110, 116, "Home ("..status.conf.distUnitLabel..")", RIGHT)
  end
  libs.drawLib.drawText(110, 131, strdist, FONT_XXL, status.colors.panelText, RIGHT, blink)
  -- travel distance
  lcd.color(status.colors.panelLabel)
  lcd.font(FONT_S)
  lcd.drawText(238, 116, "Travel ("..status.conf.distUnitLongLabel..")", RIGHT)
  libs.drawLib.drawNumber(238, 140, status.telemetry.totalDist*status.conf.distUnitLongScale, 2, FONT_XL, status.colors.panelText, RIGHT)
  --[[
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(4, ALTASL_Y + 4,true,false,utils)
    drawLib.drawVArrow(4, HOMEDIST_Y + 4 ,true,false,utils)
  end
  --]]
  libs.drawLib.drawText(1, 37, "L1", FONT_XS, lcd.RGB(100,100,100))
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
