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
#define X9
--#define X7
-- always use loadscript() instead of loadfile()
#define LOADSCRIPT
-- force a loadscript() on init() to compile all .lua in .luac
--#define COMPILE
#ifdef COMPILE
#define LOAD_LUA
#endif
---------------------
-- VERSION
---------------------
#ifdef X9
  #define VERSION "Yaapu X9 telemetry script 1.8.0"
#else
  #define VERSION "Yaapu X7 1.8.0"
#endif
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
#define RESET
-- always calculate FNV hash and play sound msg_<hash>.wav
#define FNV_HASH
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
#define NOTELEM_BLINK
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

#ifdef TESTMODE
-- force cellcount
#define CELLCOUNT 12
-- copy 1st battery data over 2nd battery data
--#define BATT2TEST
-- copy 1st FLVSS data over 2nd FLVSS data
#define FLVSS2TEST
-- generate sample messages to parse
--#define MESSAGES
-- put the script in demo mode for screenshots
--#define DEMO
#endif

---------------------
-- SENSORS
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

#define WPD_ID 0x082F
#define WPD_SUBID 0
#define WPD_INSTANCE 10
#define WPD_PRECISION 0
#define WPD_NAME "WPD"

#define WPX_ID 0x082F
#define WPX_SUBID 0
#define WPX_INSTANCE 11
#define WPX_PRECISION 0
#define WPX_NAME "WPX"

#define WPN_ID 0x050F
#define WPN_SUBID 0
#define WPN_INSTANCE 10
#define WPN_PRECISION 0
#define WPN_NAME "WPN"

#define WPB_ID 0x084F
#define WPB_SUBID 0
#define WPB_INSTANCE 10
#define WPB_PRECISION 0
#define WPB_NAME "WPB"

#define CELLFULL 4.36
------------------------
-- MIN MAX
------------------------
-- min
#define MIN_BATT1_FC 1
#define MIN_BATT2_FC 2
#define MIN_CELL1_VS 3
#define MIN_CELL2_VS 4
#define MIN_BATT1_VS 5
#define MIN_BATT2_VS 6

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
------------------------
-- LAYOUT
------------------------
#ifdef X9
  
#define LCD_W 212

#define HUD_X 62
#define HUD_WIDTH 88
#define HUD_X_MID 33

#define LEFTPANE_X 1
#define RIGHTPANE_X 152

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 7
#define TOPBAR_WIDTH 212

#define BOTTOMBAR_Y 56
#define BOTTOMBAR_HEIGHT 9
#define BOTTOMBAR_WIDTH 212

#define BOX1_X 0
#define BOX1_Y 38
#define BOX1_WIDTH 66  
#define BOX1_HEIGHT 8

#define BOX2_X 61
#define BOX2_Y 46
#define BOX2_WIDTH 17  
#define BOX2_HEIGHT 12

#define FLIGHTMODE_X 1
#define FLIGHTMODE_Y 0
#define FLIGHTMODE_FLAGS SMLSIZE+INVERS

#define HOMEANGLE_X 60
#define HOMEANGLE_Y 27
#define HOMEANGLE_XLABEL 3
#define HOMEANGLE_YLABEL 27
#define HOMEANGLE_FLAGS SMLSIZE

#define HSPEED_X 60
#define HSPEED_Y 49
#define HSPEED_XLABEL 12
#define HSPEED_YLABEL 48
#define HSPEED_XDIM 61
#define HSPEED_YDIM 49
#define HSPEED_FLAGS SMLSIZE
#define HSPEED_ARROW_WIDTH 10

#define HOMEDIR_X 133
#define HOMEDIR_Y 47
#define HOMEDIR_R 7

#define FLIGHTTIME_X 176
#define FLIGHTTIME_Y 0
#define FLIGHTTIME_FLAGS SMLSIZE+INVERS+TIMEHOUR

#define RSSI_X 69
#define RSSI_Y 0
#define RSSI_FLAGS SMLSIZE+INVERS 

#define TXVOLTAGE_X 115
#define TXVOLTAGE_Y 0
#define TXVOLTAGE_FLAGS SMLSIZE+INVERS

#else
  
#define LCD_W 128

#define HUD_X 32
#define HUD_WIDTH 64
#define HUD_X_MID 33

#define LEFTPANE_X 0
#define RIGHTPANE_X 97

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 7
#define TOPBAR_WIDTH 128

#define BOTTOMBAR_Y 57
#define BOTTOMBAR_HEIGHT 8
#define BOTTOMBAR_WIDTH 128

#define BOX1_X 65
#define BOX1_Y 28
#define BOX1_WIDTH 23 
#define BOX1_HEIGHT 15

#define BOX2_X 65
#define BOX2_Y 7
#define BOX2_WIDTH 38  
#define BOX2_HEIGHT 7

#define FLIGHTMODE_X 1
#define FLIGHTMODE_Y 0
#define FLIGHTMODE_FLAGS SMLSIZE+INVERS

#define HOMEANGLE_X 0
#define HOMEANGLE_Y 0
#define HOMEANGLE_XLABEL 0
#define HOMEANGLE_YLABEL 0
#define HOMEANGLE_FLAGS SMLSIZE

#define HSPEED_X 107
#define HSPEED_Y 8
#define HSPEED_XLABEL 66
#define HSPEED_YLABEL 10
#define HSPEED_XDIM 102
#define HSPEED_YDIM 9
#define HSPEED_FLAGS SMLSIZE
#define HSPEED_ARROW_WIDTH 6

--#define HOMEDIR_X 42
#define HOMEDIR_X 82
#define HOMEDIR_Y 48
#define HOMEDIR_R 7

#define FLIGHTTIME_X 98
#define FLIGHTTIME_Y 0
#define FLIGHTTIME_FLAGS SMLSIZE+INVERS

#define RSSI_X 70
#define RSSI_Y 0
#define RSSI_FLAGS SMLSIZE+INVERS 

#define TXVOLTAGE_X 104
#define TXVOLTAGE_Y 21
#define TXVOLTAGE_FLAGS SMLSIZE

#endif --X7
--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------
#define TYPEVALUE 0
#define TYPECOMBO 1
#define MENU_Y 7
#define MENU_PAGESIZE 7

#ifdef X9
#define MENU_ITEM_X 150
#else
#define MENU_ITEM_X 102
#endif

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
#define ALARM_NOTIFIED 1
#define ALARM_START 2
#define ALARM_ARMED 3
#define ALARM_TYPE 4
#define ALARM_GRACE 5
#define ALARM_READY 6
#define ALARM_LAST_ALARM 7

#define ALARMS_MIN_ALT 1
#define ALARMS_MAX_ALT 2
#define ALARMS_MAX_DIST 3
#define ALARMS_FS_EKF 4
#define ALARMS_FS_BATT 5
#define ALARMS_TIMER 6
#define ALARMS_BATT_L1 7
#define ALARMS_BATT_L2 8
#define ALARMS_MAX_HDOP 9

#define ALARM_TYPE_MIN 0
#define ALARM_TYPE_MAX 1 
#define ALARM_TYPE_TIMER 2
#define ALARM_TYPE_BATT 3
#define ALARM_TYPE_BATT_CRT 4

#define ALARM_TYPE_BATT_GRACE 4
-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

#define UNIT_ALT_SCALE unitScale
#define UNIT_ALT_LABEL unitLabel
#define UNIT_DIST_SCALE unitScale
#define UNIT_DIST_LABEL unitLabel
#define UNIT_DIST_LONG_LABEL unitLongLabel
#define UNIT_DIST_LONG_SCALE unitLongScale
#define UNIT_HSPEED_SCALE conf.horSpeedMultiplier
#define UNIT_VSPEED_SCALE conf.vertSpeedMultiplier
#define UNIT_HSPEED_LABEL conf.horSpeedLabel
#define UNIT_VSPEED_LABEL conf.vertSpeedLabel

#define OPENTX_UNIT_METERS 9
#define OPENTX_UNIT_FEET 10

-----------------------
-- HUD AND YAW
-----------------------
#define YAW_Y TOPBAR_Y+TOPBAR_HEIGHT
#ifdef X9
#define YAW_STEPWIDTH 8
#define YAW_X_MIN (LCD_W-HUD_WIDTH)/2 + 6
#define YAW_X_MAX (LCD_W+HUD_WIDTH)/2 - 8
#define YAW_WIDTH HUD_WIDTH-7
#else
#define YAW_STEPWIDTH 6.2
#define YAW_X_MIN 34
#define YAW_X_MAX 26+HUD_WIDTH
#define YAW_WIDTH HUD_WIDTH-5
#endif --X9
-- vertical distance between roll horiz segments
#define HUD_R2 6

#define LEFTWIDTH   17
#define RIGHTWIDTH  17
-- vertical distance between roll horiz segments
#define R2 6
-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
#define BATT_CELL 1
#define BATT_VOLT 4
#define BATT_CURR 7
#define BATT_MAH 10
#define BATT_CAP 13

#define BATT_IDALL 0
#define BATT_ID1 1
#define BATT_ID2 2

#define BATTCONF_PARALLEL 1
#define BATTCONF_SERIAL 2
#define BATTCONF_OTHER 3

-- X-Lite Support
#define XLITE_UP 36
#define XLITE_UP_RPT 68
#define XLITE_DOWN 35
#define XLITE_DOWN_RPT 67
#define XLITE_RTN 33
#define XLITE_ENTER 34
#define XLITE_MENU_LONG 128
#define XLITE_MENU 32

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------
#define TRANSITION_LASTVALUE 1
#define TRANSITION_LASTCHANGED 2
#define TRANSITION_DONE 3
#define TRANSITION_DELAY 4

#define TRANSITIONS_FLIGHTMODE 1

#define MONITOR_ALTITUDE 1
#define MONITOR_DISTANCE 2

#define LIB_BASE_PATH "/SCRIPTS/TELEMETRY/yaapu/"

#define HAPTIC_DURATION 12

#define DRAWLIB_LOAD_CYCLE 0
#define MENU_LOAD_CYCLE 4
#define ALTVIEW_LOAD_CYCLE 2
#define LEFT_LOAD_CYCLE 2
#define CENTER_LOAD_CYCLE 4
#define RIGHT_LOAD_CYCLE 6
#define LOAD_CYCLE_MAX 8
