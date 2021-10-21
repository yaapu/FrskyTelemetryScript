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


local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,utils)--,getMaxValue,getBitmap,drawBlinkBitmap,lcdBacklightOn)
  local flags = 0
  if conf.rangeFinderMax > 0 then
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,utils.colors.black)
    lcd.drawText(25, 18, "Range("..unitLabel..")", SMLSIZE+CUSTOM_COLOR)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.setColor(CUSTOM_COLOR,utils.colors.red)
      lcd.drawFilledRectangle(92-65, 30+4,65,21,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(92, 30, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,12)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,utils.colors.black)
    lcd.drawText(25, 18, "AltAsl("..unitLabel..")", SMLSIZE+CUSTOM_COLOR)
    local stralt = string.format("%d",alt*unitScale)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(92, 30, stralt, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,utils.colors.black)
  lcd.drawText(92, 56, "Dist("..unitLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(92, 107, "WPD("..unitLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- VALUES
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- home distance
  drawLib.drawHomeIcon(4, 56 + 18,utils)
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*unitScale)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  if dist < 999 then
    lcd.drawText(92, 68, strdist, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  else
    lcd.drawText(92, 68+5, unitLongLabel, SMLSIZE+RIGHT+CUSTOM_COLOR)
    lcd.drawNumber(92-20, 68+2, dist*unitLongScale*100, flags+RIGHT+CUSTOM_COLOR+PREC2)
  end
  -- total distance
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(92, 89, unitLongLabel, SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawNumber(69, 89, telemetry.totalDist*unitLongScale*100, SMLSIZE+RIGHT+CUSTOM_COLOR+PREC2)
  -- draw WP info only for supported flight modes
  -- AUTO, GUIDED, LOITER, RTL, QRTL, QLOITER, QLAND, FOLLOW, ZIGZAG
  if status.wpEnabledMode == 1 then
    -- wp number
    lcd.drawText(92, 138, string.format("#%d",telemetry.wpNumber),SMLSIZE+RIGHT+CUSTOM_COLOR)
    -- wp distance
    lcd.drawNumber(92, 118, telemetry.wpDistance * unitScale,MIDSIZE+RIGHT+CUSTOM_COLOR)
    -- LINES
    lcd.setColor(CUSTOM_COLOR,utils.colors.white) --yellow
    -- wp bearing
    drawLib.drawRArrow(13,134,11,telemetry.wpOffsetFromCog,CUSTOM_COLOR)
  else
    -- wp number
    lcd.drawText(92, 138, "# ---",SMLSIZE+RIGHT+CUSTOM_COLOR)
    -- wp distance
    lcd.drawText(92, 118, "---",MIDSIZE+RIGHT+CUSTOM_COLOR)
    -- LINES
    lcd.setColor(CUSTOM_COLOR,utils.colors.white) --yellow
    -- wp bearing
    drawLib.drawRArrow(13, 134, 11, 0, CUSTOM_COLOR)
  end
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(3, 30+4,true,false,utils)
    drawLib.drawVArrow(3, 68+4 ,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
  -- RC CHANNELS
  --[[
  if conf.enableRCChannels == true then
    for i=1,#telemetry.rcchannels do
      setTelemetryValue(Thr_ID, Thr_SUBID, Thr_INSTANCE + i, telemetry.rcchannels[i], 13 , Thr_PRECISION , "RC"..i)
    end
  end
  --]]

  -- WP
  setTelemetryValue(0x050F, 0, 10, telemetry.wpNumber, 0 , 0 , "WPN")
  setTelemetryValue(0x082F, 0, 10, telemetry.wpDistance, 9 , 0 , "WPD")

  -- crosstrack error and wp bearing not exposed as OpenTX variables by default
  --[[
  setTelemetryValue(WPX_ID, WPX_SUBID, WPX_INSTANCE, telemetry.wpXTError, 9 , WPX_PRECISION , WPX_NAME)
  setTelemetryValue(WPB_ID, WPB_SUBID, WPB_INSTANCE, telemetry.wpOffsetFromCog, 20 , WPB_PRECISION , WPB_NAME)
  --]]
end

return {drawPane=drawPane,background=background}
