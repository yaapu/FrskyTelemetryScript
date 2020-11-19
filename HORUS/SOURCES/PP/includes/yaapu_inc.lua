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
#define VERSION "Yaapu Telemetry Widget 1.9.1-beta1"
#define VERSION_CONFIG 191
-- load and compile of lua files
#define LOADSCRIPT
#ifdef LOADSCRIPT
#define LOAD_LUA
#endif
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
#ifdef COMPILE
#define LOAD_LUA
#endif
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764
#define X10_OPENTX_221

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable battery percentage based on voltage
#define BATTPERC_BY_VOLTAGE
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
#ifdef TESTMODE
  -- cell count
  #define CELLCOUNT 6
  --#define DEMO
  -- clone batt 1 data over fake batt 2
  #define BATT2TEST
  -- clone FLVSS1 data over a fake FLVSS 2
  --#define FLVSS2TEST
  --pushes some test messages
  --#define TESTMESSAGES
  --simulate voltage only battery monitor
  --#define NOCURRENT
#endif
-- enable debug of generated hash or short hash string
--#define HASHDEBUG

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
#define VFAS_ID 0x021F
#define VFAS_SUBID 0
#define VFAS_INSTANCE 0
#define VFAS_PRECISION 2
#define VFAS_NAME "VFAS"

#define CURR_ID 0x020F
#define CURR_SUBID 0
#define CURR_INSTANCE 0
#define CURR_PRECISION 1
#define CURR_NAME "CURR"

#define VSpd_ID 0x011F
#define VSpd_SUBID 0
#define VSpd_INSTANCE 0
#define VSpd_PRECISION 1
#define VSpd_NAME "VSpd"

#define GSpd_ID 0x083F
#define GSpd_SUBID 0
#define GSpd_INSTANCE 0
#define GSpd_PRECISION 0
#define GSpd_NAME "GSpd"

#define Alt_ID 0x010F
#define Alt_SUBID 0
#define Alt_INSTANCE 0
#define Alt_PRECISION 1
#define Alt_NAME "Alt"

#define GAlt_ID 0x082F
#define GAlt_SUBID 0
#define GAlt_INSTANCE 0
#define GAlt_PRECISION 0
#define GAlt_NAME "GAlt"

#define Hdg_ID 0x084F
#define Hdg_SUBID 0
#define Hdg_INSTANCE 0
#define Hdg_PRECISION 0
#define Hdg_NAME "Hdg"

#define Fuel_ID 0x060F
#define Fuel_SUBID 0
#define Fuel_INSTANCE 0
#define Fuel_PRECISION 0
#define Fuel_NAME "Fuel"

#define IMUTmp_ID 0x041F
#define IMUTmp_SUBID 0
#define IMUTmp_INSTANCE 0
#define IMUTmp_PRECISION 0
#define IMUTmp_NAME "IMUt"

#define ARM_ID 0x060F
#define ARM_SUBID 0
#define ARM_INSTANCE 1
#define ARM_PRECISION 0
#define ARM_NAME "ARM"

#define WPD_ID 0x082F
#define WPD_SUBID 0
#define WPD_INSTANCE 10
#define WPD_PRECISION 0
#define WPD_NAME "WPD"

#define WPN_ID 0x050F
#define WPN_SUBID 0
#define WPN_INSTANCE 10
#define WPN_PRECISION 0
#define WPN_NAME "WPN"

#define WPX_ID 0x082F
#define WPX_SUBID 0
#define WPX_INSTANCE 11
#define WPX_PRECISION 0
#define WPX_NAME "WPX"

#define WPB_ID 0x084F
#define WPB_SUBID 0
#define WPB_INSTANCE 10
#define WPB_PRECISION 0
#define WPB_NAME "WPB"

#define ASpd_ID 0x0AF
#define ASpd_SUBID 0
#define ASpd_INSTANCE 0
#define ASpd_PRECISION 0
#define ASpd_NAME "ASpd"

#define BAlt_ID 0x010F
#define BAlt_SUBID 0
#define BAlt_INSTANCE 1
#define BAlt_PRECISION 1
#define BAlt_NAME "BAlt"

-- Throttle and RC use RPM sensor IDs
#define Thr_ID 0x050F
#define Thr_SUBID 0
#define Thr_INSTANCE 0
#define Thr_PRECISION 0
#define Thr_NAME "Thr"

---------------------
-- BATTERY DEFAULTS
---------------------
#define CELLFULL 4.35
#define CELLEMPTY 3.0
---------------------------------
-- BACKLIGHT SUPPORT
-- GV is zero based, GV 8 = GV 9 in OpenTX
---------------------------------
#define BACKLIGHT_GV 8
#define BACKLIGHT_DURATION 5
---------------------------------
-- CONF REFRESH GV
---------------------------------
#define CONF_GV 8
#define CONF_FM_GV 8

#define ALARM_NOTIFIED 1
#define ALARM_START 2
#define ALARM_ARMED 3
#define ALARM_TYPE 4
#define ALARM_GRACE 5
#define ALARM_READY 6
#define ALARM_LAST_ALARM 7
--
#define ALARMS_MIN_ALT 1
#define ALARMS_MAX_ALT 2
#define ALARMS_MAX_DIST 3
#define ALARMS_FS_EKF 4
#define ALARMS_FS_BATT 5
#define ALARMS_TIMER 6
#define ALARMS_BATT_L1 7
#define ALARMS_BATT_L2 8
#define ALARMS_MAX_HDOP 9
--
#define ALARM_TYPE_MIN 0
#define ALARM_TYPE_MAX 1 
#define ALARM_TYPE_TIMER 2
#define ALARM_TYPE_BATT 3
#define ALARM_TYPE_BATT_CRT 4
--
#define ALARM_TYPE_BATT_GRACE 4

#define MIN_BATT1_FC 1
#define MIN_BATT2_FC 2
#define MIN_CELL1_VS 3
#define MIN_CELL2_VS 4
#define MIN_BATT1_VS 5
#define MIN_BATT2_VS 6
--
#define MAX_CURR 7
#define MAX_CURR1 8
#define MAX_CURR2 9
#define MAX_POWER 10
#define MINMAX_ALT 11
#define MAX_GPSALT 12
#define MAX_VSPEED 13
#define MAX_HSPEED 14
#define MAX_DIST 15
#define MAX_RANGE 16

----------------------
-- COMMON LAYOUT
----------------------
-- enable vertical bars HUD drawing (same as taranis)
--#define HUD_ALGO1
-- enable optimized hor bars HUD drawing
--#define HUD_ALGO2
-- enable hor bars HUD drawing
#define HUD_ALGO3

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 20
#define TOPBAR_WIDTH LCD_W

#define BOTTOMBAR_Y LCD_H-20
#define BOTTOMBAR_HEIGHT 20
#define BOTTOMBAR_WIDTH LCD_W

#define RSSI_X 323
#define RSSI_Y 0
#define RSSI_FLAGS 0 

#define TXVOLTAGE_X 391
#define TXVOLTAGE_Y 0
#define TXVOLTAGE_FLAGS 0


--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------
#define TYPEVALUE 0
#define TYPECOMBO 1
#define MENU_Y 25
#define MENU_PAGESIZE 11
#define MENU_ITEM_X 300

--------------------------
-- UNIT OF MEASURE
--------------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

#define UNIT_ALT_SCALE unitScale
#define UNIT_DIST_SCALE unitScale
#define UNIT_DIST_LONG_SCALE unitLongScale
#define UNIT_ALT_LABEL unitLabel
#define UNIT_DIST_LABEL unitLabel
#define UNIT_DIST_LONG_LABEL unitLongLabel
#define UNIT_HSPEED_SCALE conf.horSpeedMultiplier
#define UNIT_VSPEED_SCALE conf.vertSpeedMultiplier
#define UNIT_HSPEED_LABEL conf.horSpeedLabel
#define UNIT_VSPEED_LABEL conf.vertSpeedLabel

-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
#define BATT_CELL 1
#define BATT_VOLT 4
#define BATT_CURR 7
#define BATT_MAH 10
#define BATT_CAP 13
#define BATT_PERC 16
-- 
#define BATT_IDALL 0
#define BATT_ID1 1
#define BATT_ID2 2

#define BATTCONF_PARALLEL 1
#define BATTCONF_SERIES 2
#define BATTCONF_OTHER 3
#define BATTCONF_OTHER2 4
#define BATTCONF_OTHER3 5
#define BATTCONF_OTHER4 6
-----------------------
-- LIBRARY LOADING
-----------------------
#ifdef LOAD_LUA
#define loadMenuLib() dofile(basePath..menuLibFile..".lua")
#else
#define loadMenuLib() dofile(basePath..menuLibFile..".luac")
#endif

----------------------
--- COLORS
----------------------
#define COLOR_BLACK 0x0000
#define COLOR_WHITE 0xFFFF
#define COLOR_GREEN 0x1FEA
#define COLOR_DARKBLUE 0x0AB1
#define COLOR_DARKBLUE_2 0x0169
#define COLOR_DARKBLUE_3 0x01AB
#define COLOR_BLUE
#define COLOR_YELLOW 0xFE60
#define COLOR_ORANGE 0xFE60
#define COLOR_RED 0xF800
#define COLOR_LIGHT_GREY 0x8C71
#define COLOR_GREY 0x7BCF
#define COLOR_DARK_GREY 0x5AEB
#define COLOR_LIGHTRED 0xF9A0
#define COLOR_BARS_2 0x10A3

#define COLOR_BATTERY COLOR_YELLOW
--#define COLOR_LABEL COLOR_GREY
#define COLOR_LABEL COLOR_BLACK
#define COLOR_TEXT COLOR_WHITE
#define COLOR_TEXTEX COLOR_WHITE
--#define COLOR_BG COLOR_DARKBLUE_2
#define COLOR_BG COLOR_DARKBLUE
#define COLOR_BARS COLOR_BLACK
--#define COLOR_BARSEX COLOR_BARS_2
#define COLOR_BARSEX COLOR_BLACK
#define COLOR_LINES COLOR_WHITE
#define COLOR_NOTELEM COLOR_RED

#define COLOR_CRIT COLOR_RED
#define COLOR_WARN COLOR_YELLOW

--#define COLOR_SENSORS COLOR_DARKBLUE_2
#define COLOR_SENSORS COLOR_BLACK
#define COLOR_SENSORS_LABEL COLOR_LIGHT_GREY
#define COLOR_SENSORS_TEXT COLOR_WHITE

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------
#define TRANSITION_LASTVALUE 1
#define TRANSITION_LASTCHANGED 2
#define TRANSITION_DONE 3
#define TRANSITION_DELAY 4

#define TRANSITIONS_FLIGHTMODE 1

--------------------------
-- CLIPPING ALGO DEFINES
--------------------------
#define CS_INSIDE 0
#define CS_LEFT 1
#define CS_RIGHT 2
#define CS_BOTTOM 4
#define CS_TOP 8
