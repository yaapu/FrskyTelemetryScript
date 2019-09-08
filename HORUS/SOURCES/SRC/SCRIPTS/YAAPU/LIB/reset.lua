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
--#define LOADSCRIPT
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable battery percentage based on voltage
--#define BATTPERC_BY_VOLTAGE
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE
-- enable support for FNV hash based sound files

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

---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE

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

---------------------------------
-- ALARMS
---------------------------------
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
--]]--
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
-- enable hor bars HUD drawing






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

-----------------------
-- LIBRARY LOADING
-----------------------

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









local function resetTelemetry(status,telemetry,battery,alarms,utils)
  -- sport queue max pops to prevent looping forever
  local i = 0  
  -- empty sport queue
  local a,b,c,d = sportTelemetryPop()
  while a ~= null and i < 50 do
    a,b,c,d = sportTelemetryPop()
    i = i + 1
  end
  -----------------------------
  -- TELEMETRY
  -----------------------------
  -- AP STATUS 
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
  -- GPS
  telemetry.lat = nil
  telemetry.lon = nil
  telemetry.homeLat = nil
  telemetry.homeLon = nil
  -- WP
  telemetry.wpNumber = 0
  telemetry.wpDistance = 0
  telemetry.wpXTError = 0
  telemetry.wpBearing = 0
  telemetry.wpCommands = 0
  -- RC channels
  telemetry.rcchannels = {}
  -- VFR
  telemetry.airspeed = 0
  telemetry.throttle = 0
  telemetry.baroAlt = 0
  --
  telemetry.totalDist = 0
  -----------------------------
  -- SCRIPT STATUS
  -----------------------------
  -- FLVSS 1
  status.cell1min = 0
  status.cell1sum = 0
  -- FLVSS 2
  status.cell2min = 0
  status.cell2sum = 0
  -- FC 1
  status.cell1sumFC = 0
  status.cell1maxFC = 0
  -- FC 2
  status.cell2sumFC = 0
  status.cell2maxFC = 0
  -- BATT
  status.cell1count = 0
  status.cell2count = 0
  
  status.battsource = "na"
  -- BATT 1
  status.batt1sources = {
    vs = false,
    fc = false
  }
  -- BATT 2
  status.batt2sources = {
    vs = false,
    fc = false
  }
  -- TELEMETRY
  status.noTelemetryData = 1
  -- MESSAGES
  status.msgBuffer = ""
  status.lastMsgValue = 0
  status.lastMsgTime = 0
  -- FLIGHT TIME
  status.lastTimerStart = 0
  status.timerRunning = 0
  status.flightTime = 0
  -- EVENTS
  status.lastStatusArmed = 0
  status.lastGpsStatus = 0
  status.lastFlightMode = 0
  status.lastSimpleMode = 0
  -- battery levels
  status.batLevel = 99
  status.battLevel1 = false
  status.battLevel2 = false
  status.lastBattLevel = 14
  -- messages
  status.lastMessage = nil
  status.lastMessageSeverity = 0
  status.lastMessageCount = 1
  status.messageCount = 0
  -------------------------
  -- BATTERY ARRAY
  -------------------------
  battery = {0,0,0,0,0,0,0,0,0,0,0,0}
  -- clear message queue
  utils.clearTable(status.messages)
  ---
  status.messages = {}
  -- reset alarms
  alarms[1] = { false, 0 , false, 0, 0, false, 0} --MIN_ALT
  alarms[2] = { false, 0 , true, 1 , 0, false, 0 } --MAX_ALT
  alarms[3] = { false, 0 , true, 1 , 0, false, 0 } --15
  alarms[4] = { false, 0 , true, 1 , 0, false, 0 } --FS_EKF
  alarms[5] = { false, 0 , true, 1 , 0, false, 0 } --FS_BAT
  alarms[6] = { false, 0 , true, 2, 0, false, 0 } --FLIGTH_TIME
  alarms[7] = { false, 0 , false, 3, 4, false, 0 } --BATT L1
  alarms[8] = { false, 0 , false, 4, 4, false, 0 } --BATT L2
  alarms[9] = { false, 0 , false, 1 , 0, false, 0 } --MAX_HDOP
  -- stop and reset timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
end

return {resetTelemetry=resetTelemetry}
