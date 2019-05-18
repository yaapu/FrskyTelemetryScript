--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Taranis X9D+ and QX7+ radios
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
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
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
---------------------
-- GLOBAL DEFINES
---------------------
--#define 
--#define X7
-- always use loadscript() instead of loadfile()
-- force a loadscript() on init() to compile all .lua in .luac
--#define COMPILE
---------------------
-- VERSION
---------------------
---------------------
-- FEATURES
---------------------
--#define BATTMAH3DEC
-- enable altitude/distance monitor and vocal alert (experimental)
--#define MONITOR
-- show incoming DIY packet rates
--#define TELEMETRY_STATS
-- enable synthetic vspeed when ekf is disabled
--#define SYNTHVSPEED
-- enable telemetry reset on timer 3 reset
-- always calculate FNV hash and play sound msg_<hash>.wav
-- enable telemetry logging menu option
--#define LOGTELEMETRY
-- enable max HDOP alert 
--#define HDOP_ALARM
-- enable support for custom background functions
--#define CUSTOM_BG_CALL
-- enable alert window for no telemetry
--#define NOTELEM_ALERT
-- enable popups for no telemetry data
--#define NOTELEM_POPUP
-- enable blinking rectangle on no telemetry
---------------------
-- DEBUG
---------------------
--#define DEBUG
--#define DEBUGEVT
--#define DEV
--#define MEMDEBUG
-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
---------------------
-- TESTMODE
---------------------
-- enable script testing via radio sticks
--#define TESTMODE


---------------------
-- SENSORS
---------------------












-- Throttle and RC use RPM sensor IDs





------------------------
-- MIN MAX
------------------------
-- min

------------------------
-- LAYOUT
------------------------
  














--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- ALARMS
--------------------------------------------------------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]


-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"



-----------------------
-- HUD AND YAW
-----------------------
-- vertical distance between roll horiz segments

-- vertical distance between roll horiz segments
-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1



-- X-Lite Support

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------

















local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- gps status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  local strNumSats = ""
  local flags = BLINK
  local mult = 1
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(x+0,6 + 2, strStatus, SMLSIZE)
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(x+0 + 35, 6+1, strNumSats, MIDSIZE+RIGHT)
    lcd.drawText(x+0 + 37, 6 + 2 , "H", SMLSIZE)
    lcd.drawNumber(x+0 + 60, 6+1, telemetry.gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(x+0 + 35,6+1,x+0+35,6 + 12,SOLID,FORCE)
  else
    lcd.drawText(x+0 + 10, 6+1, strStatus, MIDSIZE+INVERS+BLINK)
  end  
  lcd.drawLine(x+0 ,6 + 13,x+0+60,6 + 13,SOLID,FORCE)
  if status.showMinMaxValues == true then
    flags = 0
  end
  if conf.rangeFinderMax > 0 then
    -- rng finder
    flags = 0
    local rng = telemetry.range
    -- rng is centimeters, RANGE_MAX is feet
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,16)
    lcd.drawText(x+2 + 4, 30, "Rng", SMLSIZE)
    lcd.drawText(x+60, 31 , unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), 31-1 , rng*0.01*unitScale*100, PREC2+RIGHT+SMLSIZE+flags)
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10 -- meters
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,12)
    end
    lcd.drawText(x+2 + 4, 30, "Asl", SMLSIZE)
    lcd.drawText(x+60, 31, unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), 31-1 ,alt*unitScale, RIGHT+SMLSIZE+flags)
  end
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- home distance
  lcd.drawText(x+60, 37+5, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 37, dist*unitScale, RIGHT+MIDSIZE+flags)
  -- waypoints
  lcd.drawNumber(x+0, 21, telemetry.wpNumber, SMLSIZE)
  drawLib.drawRArrow(lcd.getLastRightPos()+4,25,5,telemetry.wpBearing*45,FORCE)
  lcd.drawText(x+60, 21+1, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 21, telemetry.wpDistance*unitScale, RIGHT)  
  -- total distance
  lcd.drawText(x+60, 49, unitLongLabel, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), 49, telemetry.totalDist*unitLongScale*10, RIGHT+SMLSIZE+PREC1)
  -- throttle
  lcd.drawNumber(x+0, 49, telemetry.throttle,SMLSIZE)
  lcd.drawText(lcd.getLastRightPos(), 49, "%", SMLSIZE)
  -- minmax
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+0 + 2, 41-2,6,true,false)
    drawLib.drawVArrow(x+2,30 - 1,6,true,false)
  else
    drawLib.drawVArrow(x+2,30 - 1,7,true,true)
    drawLib.drawHomeIcon(x+0 + 1,41,7)
  end
  -- airspeed
  local speed = telemetry.airspeed*conf.horSpeedMultiplier
  if math.abs(speed) > 99 then
    lcd.drawNumber(62+6,33 + 10,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(62+6,33 + 10,speed,SMLSIZE+PREC1)
  end  
end




return {
  drawPane=drawPane,
}
