--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Horus X10 and X12 radios
--
-- Copyright (C) 2018-2019. Alessandro Apostoli
-- https://github.com/yaapu
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

---------------------
-- MAIN CONFIG
-- 480x272 LCD_W x LCD_H
---------------------

---------------------
-- VERSION
---------------------
-- load and compile of lua files
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable battery percentage based on voltage
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE

---------------------
-- DEV FEATURE CONFIG
---------------------
-- enable memory debuging 
--#define MEMDEBUG
-- enable dev code
--#define DEV
-- uncomment haversine calculation routine
--#define HAVERSINE
-- enable telemetry logging to file (experimental)
--#define LOGTELEMETRY
-- use radio channels imputs to generate fake telemetry data
--#define TESTMODE
-- enable debug of generated hash or short hash string
--#define HASHDEBUG
-- enable MESSAGES DEBUG
--#define DEBUG_MESSAGES
---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
-- #define BGTELERATE

---------------------
-- SENSOR IDS
---------------------
















-- Throttle and RC use RPM sensor IDs

---------------------
-- BATTERY DEFAULTS
---------------------
---------------------------------
-- BACKLIGHT SUPPORT
-- GV is zero based, GV 8 = GV 9 in OpenTX
---------------------------------
---------------------------------
-- CONF REFRESH GV
---------------------------------

--
--
--

--

----------------------
-- COMMON LAYOUT
----------------------
-- enable vertical bars HUD drawing (same as taranis)
--#define HUD_ALGO1
-- enable optimized hor bars HUD drawing
--#define HUD_ALGO2
-- enable hor bars HUD drawing, 2 px resolution
-- enable hor bars HUD drawing, 1 px resolution
--#define HUD_ALGO4






--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

--------------------------
-- UNIT OF MEASURE
--------------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
-- 


----------------------
--- COLORS
----------------------

--#define COLOR_LABEL 0x7BCF
--#define COLOR_BG 0x0169
--#define COLOR_BARSEX 0x10A3


--#define COLOR_SENSORS 0x0169

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------


--------------------------
-- CLIPPING ALGO DEFINES
--------------------------

---------------------------------
-- LAYOUT
---------------------------------


















local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)--,getMaxValue,getBitmap,drawBlinkBitmap,lcdBacklightOn)
  if conf.rangeFinderMax > 0 then
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.drawText(8, 20, "Range("..unitLabel..")", SMLSIZE+BLACK)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.drawFilledRectangle(68-65, 31+4,65,21,RED)
    end
    lcd.drawText(68, 31, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+RIGHT+WHITE)
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
    lcd.drawText(8, 20, "AltAsl("..unitLabel..")", SMLSIZE+BLACK)
    local stralt = string.format("%d",alt*unitScale)
    lcd.drawText(68, 31, stralt, MIDSIZE+flags+RIGHT+WHITE)
  end
  -- LABELS
  lcd.drawText(69, 122, "AS("..conf.horSpeedLabel..")", SMLSIZE+RIGHT+BLACK)
  lcd.drawText(69, 76, "WPN", SMLSIZE+RIGHT+BLACK)
  lcd.drawText(153, 76, "WPD("..unitLabel..")", SMLSIZE+RIGHT+BLACK)
  lcd.drawText(153, 122, "THR(%)", SMLSIZE+RIGHT+BLACK)
  -- VALUES
  -- home distance
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  if status.showMinMaxValues == true then
    flags = 0
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if getGeneralSettings().imperial == 0 then
    -- metric, special handling for km
    if dist > 9999 then
	  -- add "k" for kilo, draw icon 8 pixels to left
      lcd.drawText(153, 20, "Dist(k"..unitLabel..")", SMLSIZE+RIGHT+BLACK)
      if conf.enableTxGPS then
        -- radio home
        drawLib.drawRadioIcon(69 + 15 - 8, 20 + 2,utils)
      else
        -- vehicle home
        drawLib.drawHomeIcon(69 + 15 - 8, 20 + 2,utils)
      end
	  local strdist = string.format("%d",dist*unitScale/1000)
      lcd.drawText(153, 31, strdist, MIDSIZE+flags+RIGHT+WHITE)
    else
      lcd.drawText(153, 20, "Dist("..unitLabel..")", SMLSIZE+RIGHT+BLACK)
      if conf.enableTxGPS then
        -- radio home
        drawLib.drawRadioIcon(69 + 15, 20 + 2,utils)
      else
        -- vehicle home
        drawLib.drawHomeIcon(69 + 15, 20 + 2,utils)
      end
	  local strdist = string.format("%d",dist*unitScale)
      lcd.drawText(153, 31, strdist, MIDSIZE+flags+RIGHT+WHITE)
	end
  else
    -- imperial
    lcd.drawText(153, 20, "Dist("..unitLabel..")", SMLSIZE+RIGHT+BLACK)
    if conf.enableTxGPS then
      -- radio home
      drawLib.drawRadioIcon(69 + 15, 20 + 2,utils)
    else
      -- vehicle home
      drawLib.drawHomeIcon(69 + 15, 20 + 2,utils)
    end
	local strdist = string.format("%d",dist*unitScale)
    lcd.drawText(153, 31, strdist, MIDSIZE+flags+RIGHT+WHITE)
  end  
  -- total distance
  strdist = string.format("%.02f%s", telemetry.totalDist*unitLongScale,unitLongLabel)
  lcd.drawText(152, 54, strdist, SMLSIZE+RIGHT+WHITE)
  -- airspeed
  lcd.drawNumber(68,134,telemetry.airspeed * conf.horSpeedMultiplier,MIDSIZE+RIGHT+PREC1+WHITE)
  -- wp number
  lcd.drawNumber(57, 87, telemetry.wpNumber,MIDSIZE+RIGHT+WHITE)
  -- wp distance
  lcd.drawNumber(153, 87, telemetry.wpDistance * unitScale,MIDSIZE+RIGHT+WHITE)
  -- throttle %
  lcd.drawNumber(153,134,telemetry.throttle,MIDSIZE+RIGHT+WHITE)
  -- LINES
  -- wp bearing
  drawLib.drawRArrow(67,100,10,telemetry.wpBearing*45,WHITE)
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(68-70, 31+4,true,false,utils)
    drawLib.drawVArrow(153-78, 31+4 ,true,false,utils)
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
  
  -- VFR
  setTelemetryValue(0x0AF, 0, 0, telemetry.airspeed*0.1, 4 , 0 , "ASpd")
  setTelemetryValue(0x010F, 0, 1, telemetry.baroAlt*10, 9 , 1 , "BAlt")
  setTelemetryValue(0x050F, 0, 0, telemetry.throttle, 13 , 0 , "Thr")
  
  -- WP
  setTelemetryValue(0x050F, 0, 10, telemetry.wpNumber, 0 , 0 , "WPN")
  setTelemetryValue(0x082F, 0, 10, telemetry.wpDistance, 9 , 0 , "WPD")
  
  -- crosstrack error and wp bearing not exposed as OpenTX variables by default
  --[[
  setTelemetryValue(WPX_ID, WPX_SUBID, WPX_INSTANCE, telemetry.wpXTError, 9 , WPX_PRECISION , WPX_NAME)
  setTelemetryValue(WPB_ID, WPB_SUBID, WPB_INSTANCE, telemetry.wpBearing, 20 , WPB_PRECISION , WPB_NAME)
  --]]
end

return {drawPane=drawPane,background=background}
