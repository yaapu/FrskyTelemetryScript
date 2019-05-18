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
--#define X9
--#define 
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
  










--#define HOMEDIR_X 42




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














--------------------
-- Single long function much more memory efficient than many little functions
---------------------

local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  local perc = 0
  if (battery[13+battId] > 0) then
    perc = math.min(math.max((1 - (battery[10+battId]/battery[13+battId]))*100,0),99)
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if status.showMinMaxValues == false then
    if status.battAlertLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif status.battAlertLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  -- +0.5 because PREC2 does a math.floor()  and not a math.round()
  lcd.drawNumber(x+1, 7, (battery[1+battId] + 0.5)*(battery[1+battId] < 1000 and 1 or 0.1), MIDSIZE+flags+(battery[1+battId] < 1000 and PREC2 or PREC1))
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+1+26, 7+2,6,false,true)
  else
    local lx = lcd.getLastRightPos()
    lcd.drawText(lx-1, 7, "V", dimFlags+SMLSIZE)
    --local xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
    local s = status.battsource == "a2" and "a" or (status.battsource == "vs" and "s" or "f")
    lcd.drawText(lx, 13, s, SMLSIZE)  
  end
  -- battery voltage
  lcd.drawText(x+30, 19, "V", SMLSIZE+RIGHT)  
  lcd.drawNumber(lcd.getLastLeftPos(), 19, battery[4+battId],SMLSIZE+PREC1+RIGHT)
  -- battery current
  lcd.drawText(x+30, 26, "A", SMLSIZE+RIGHT)  
  lcd.drawNumber(lcd.getLastLeftPos(), 26, battery[7+battId],PREC1+SMLSIZE+RIGHT)
  -- battery percentage
  lcd.drawNumber(x+1, 32, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos()+1, 36, "%", SMLSIZE)
  -- battery mah
  lcd.drawNumber(x+1, 44, battery[10+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 44, "Ah", SMLSIZE)
  -- battery cap
  lcd.drawNumber(x+1, 44+7, battery[13+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 44+7, "Ah", SMLSIZE)
end


return {
  drawPane=drawPane,
}
