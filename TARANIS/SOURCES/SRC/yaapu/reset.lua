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







local function resetTelemetry(status,telemetry,battery,alarms,transitions)
  -----------------------------
  -- TELEMETRY
  -----------------------------
  telemetry.flightMode = 0
  telemetry.simpleMode = 0
  telemetry.landComplete = 0
  telemetry.statusArmed = 0
  telemetry.battFailsafe = 0
  telemetry.ekfFailsafe = 0
  telemetry.imuTemp = 0
  -- GPS
  telemetry.numSats = 0
  telemetry.gpsStatus = 0
  telemetry.gpsHdopC = 100
  telemetry.gpsAlt = 0
  -- BATT 1
  telemetry.batt1volt = 0
  telemetry.batt1current = 0
  telemetry.batt1mah = 0
  -- BATT 2
  telemetry.batt2volt = 0
  telemetry.batt2current = 0
  telemetry.batt2mah = 0
  -- HOME
  telemetry.homeDist = 0
  telemetry.homeAlt = 0
  telemetry.homeAngle = -1
  -- VELANDYAW
  telemetry.vSpeed = 0
  telemetry.hSpeed = 0
  telemetry.yaw = 0
  -- ROLLPITCH
  telemetry.roll = 0
  telemetry.pitch = 0
  telemetry.range = 0 
  -- PARAMS
  telemetry.frameType = -1
  telemetry.batt1Capacity = 0
  telemetry.batt2Capacity = 0
  -- WP
  telemetry.wpNumber = 0
  telemetry.wpDistance = 0
  telemetry.wpXTError = 0
  telemetry.wpBearing = 0
  telemetry.wpCommands = 0
  -- VFR
  telemetry.airspeed = 0
  telemetry.throttle = 0
  telemetry.baroAlt = 0
  -- TOTAL DISTANCE
  telemetry.totalDist = 0

  -----------------------------
  -- SCRIPT STATUS
  -----------------------------
  status.battAlertLevel1 = false
  status.battAlertLevel2 = false
  status.flightTime = 0    -- updated from model timer 3
  status.timerRunning = 0  -- triggered by landcomplete from AP
  
  -- reset alarms
  alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , true, 1 , 0, false, 0 }, --MAX_ALT
    { false, 0 , true, 1 , 0, false, 0 }, --15
    { false, 0 , true, 1 , 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1 , 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 4, 4, false, 0 } --BATT L2
  }

  transitions = {
  --{ last_value, last_changed, transition_done, delay }  
    { 0, 0, false, 30 }, -- flightmode
  }
  
  battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

  -- stop and reset timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
end

return {resetTelemetry=resetTelemetry}
