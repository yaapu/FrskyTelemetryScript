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
-- Borrowed some code from the LI-xx BATTCHECK v3.30 script
--  http://frskytaranis.forumactif.org/t2800-lua-download-un-testeur-de-batterie-sur-la-radio

---------------------
-- radio model
---------------------
#define X9
--#define X7

---------------------
-- script version 
---------------------
#ifdef X9
  #define VERSION "Yaapu X9 telemetry script 1.5.0-rc1"
#else
  #define VERSION "Yaapu X7 1.5.0-rc1"
#endif

---------------------
-- frame types: copter always enabled
---------------------
#define PLANE
#define ROVER

---------------------
-- features
---------------------
#define MINMAX
#define SENSORS
#define ALARMS
--#define RESETBATTALARMS
--#define MENUEX
--#define ALERTS
--#define FRAMETYPE

---------------------
-- dev features
---------------------
--#define LOGTELEMETRY
--#define DEBUG
--#define TESTMODE
--#define BATT2TEST
--#define CELLCOUNT 5
--#define DEMO
--#define DEV

-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
-- calc and show actual incoming telemetry rate
--#define TELERATE

--

#ifdef SENSORS

#define VFAS_ID 0x0210
#define VFAS_SUBID 0
#define VFAS_INSTANCE 2
#define VFAS_PRECISION 2
#define VFAS_NAME "VFAS"

#define CURR_ID 0x0200
#define CURR_SUBID 0
#define CURR_INSTANCE 3
#define CURR_PRECISION 1
#define CURR_NAME "CURR"

#define VSpd_ID 0x0110
#define VSpd_SUBID 0
#define VSpd_INSTANCE 1
#define VSpd_PRECISION 1
#define VSpd_NAME "VSpd"

#define GSpd_ID 0x0830
#define GSpd_SUBID 0
#define GSpd_INSTANCE 4
#define GSpd_PRECISION 0
#define GSpd_NAME "GSpd"

#define Alt_ID 0x0100
#define Alt_SUBID 0
#define Alt_INSTANCE 1
#define Alt_PRECISION 1
#define Alt_NAME "Alt"

#define GAlt_ID 0x0820
#define GAlt_SUBID 0
#define GAlt_INSTANCE 4
#define GAlt_PRECISION 0
#define GAlt_NAME "GAlt"

#define Hdg_ID 0x0840
#define Hdg_SUBID 0
#define Hdg_INSTANCE 4
#define Hdg_PRECISION 0
#define Hdg_NAME "Hdg"

#define Tmp1_ID 0x0400
#define Tmp1_SUBID 0
#define Tmp1_INSTANCE 0
#define Tmp1_PRECISION 0
#define Tmp1_NAME "Tmp1"

#define Tmp2_ID 0x0410
#define Tmp2_SUBID 0
#define Tmp2_INSTANCE 0
#define Tmp2_PRECISION 0
#define Tmp2_NAME "Tmp2"

#define Fuel_ID 0x0600
#define Fuel_SUBID 0
#define Fuel_INSTANCE 0
#define Fuel_PRECISION 0
#define Fuel_NAME "Fuel"

#endif --SENSORS

#ifdef DEBUG
--[[
	MAV_TYPE_GENERIC=0,               /* Generic micro air vehicle. | */
	MAV_TYPE_FIXED_WING=1,            /* Fixed wing aircraft. | */
	MAV_TYPE_QUADROTOR=2,             /* Quadrotor | */
	MAV_TYPE_COAXIAL=3,               /* Coaxial helicopter | */
	MAV_TYPE_HELICOPTER=4,            /* Normal helicopter with tail rotor. | */
	MAV_TYPE_ANTENNA_TRACKER=5,       /* Ground installation | */
	MAV_TYPE_GCS=6,                   /* Operator control unit / ground control station | */
	MAV_TYPE_AIRSHIP=7,               /* Airship, controlled | */
	MAV_TYPE_FREE_BALLOON=8,          /* Free balloon, uncontrolled | */
	MAV_TYPE_ROCKET=9,                /* Rocket | */
	MAV_TYPE_GROUND_ROVER=10,         /* Ground rover | */
	MAV_TYPE_SURFACE_BOAT=11,         /* Surface vessel, boat, ship | */
	MAV_TYPE_SUBMARINE=12,            /* Submarine | */
  MAV_TYPE_HEXAROTOR=13,            /* Hexarotor | */
	MAV_TYPE_OCTOROTOR=14,            /* Octorotor | */
	MAV_TYPE_TRICOPTER=15,            /* Tricopter | */
	MAV_TYPE_FLAPPING_WING=16,        /* Flapping wing | */
	MAV_TYPE_KITE=17,                 /* Kite | */
	MAV_TYPE_ONBOARD_CONTROLLER=18,   /* Onboard companion controller | */
	MAV_TYPE_VTOL_DUOROTOR=19,        /* Two-rotor VTOL using control surfaces in vertical operation in addition. Tailsitter. | */
	MAV_TYPE_VTOL_QUADROTOR=20,       /* Quad-rotor VTOL using a V-shaped quad config in vertical operation. Tailsitter. | */
	MAV_TYPE_VTOL_TILTROTOR=21,       /* Tiltrotor VTOL | */
	MAV_TYPE_VTOL_RESERVED2=22,       /* VTOL reserved 2 | */
	MAV_TYPE_VTOL_RESERVED3=23,       /* VTOL reserved 3 | */
	MAV_TYPE_VTOL_RESERVED4=24,       /* VTOL reserved 4 | */
	MAV_TYPE_VTOL_RESERVED5=25,       /* VTOL reserved 5 | */
	MAV_TYPE_GIMBAL=26,               /* Onboard gimbal | */
	MAV_TYPE_ADSB=27,                 /* Onboard ADSB peripheral | */
	MAV_TYPE_PARAFOIL=28,             /* Steerable, nonrigid airfoil | */
	MAV_TYPE_DODECAROTOR=29,          /* Dodecarotor | */
]]--
#endif --DEBUG

#ifdef FRAMETYPE
local frameNames = {}
-- copter
frameNames[0]   = "GEN"
frameNames[2]   = "QUAD"
frameNames[3]   = "COAX"
frameNames[4]   = "HELI"
frameNames[13]  = "HEX"
frameNames[14]  = "OCTO"
frameNames[15]  = "TRI"
frameNames[29]  = "DODE"

#ifdef PLANE
-- plane
frameNames[1]   = "WING"
frameNames[16]  = "FLAP"
frameNames[19]  = "VTOL2"
frameNames[20]  = "VTOL4"
frameNames[21]  = "VTOLT"
frameNames[22]  = "VTOL"
frameNames[23]  = "VTOL"
frameNames[24]  = "VTOL"
frameNames[25]  = "VTOL"
frameNames[28]  = "FOIL"
#endif --PLANE

#ifdef ROVER
-- rover
frameNames[10]  = "ROV"
-- boat
frameNames[11]  = "SUB"
#endif --ROVER
#endif --FRAMETYPE

local frameTypes = {}
-- copter
frameTypes[0]   = "c"
frameTypes[2]   = "c"
frameTypes[3]   = "c"
frameTypes[4]   = "c"
frameTypes[13]  = "c"
frameTypes[14]  = "c"
frameTypes[15]  = "c"
frameTypes[29]  = "c"

#ifdef PLANE
-- plane
frameTypes[1]   = "p"
frameTypes[16]  = "p"
frameTypes[19]  = "p"
frameTypes[20]  = "p"
frameTypes[21]  = "p"
frameTypes[22]  = "p"
frameTypes[23]  = "p"
frameTypes[24]  = "p"
frameTypes[25]  = "p"
frameTypes[28]  = "p"
#endif --PLANE

#ifdef ROVER
-- rover
frameTypes[10]  = "r"
-- boat
frameTypes[11]  = "b"
#endif --ROVER

#ifdef TESTMODE
-- undefined
frameTypes[5] = ""
frameTypes[6] = ""
frameTypes[7] = ""
frameTypes[8] = ""
frameTypes[9] = ""
frameTypes[12] = ""
frameTypes[17] = ""
frameTypes[18] = ""
frameTypes[26] = ""
frameTypes[27] = ""
frameTypes[30] = ""
#endif --TESTMODE
--
local flightModes = {}
flightModes["c"] = {}
#ifdef PLANE
flightModes["p"] = {}
#endif --PLANE
#ifdef ROVER
flightModes["r"] = {}
#endif --ROVER
-- copter flight modes
flightModes["c"][1]="Stabilize"
flightModes["c"][2]="Acro"
flightModes["c"][3]="AltHold"
flightModes["c"][4]="Auto"
flightModes["c"][5]="Guided"
flightModes["c"][6]="Loiter"
flightModes["c"][7]="RTL"
flightModes["c"][8]="Circle"
flightModes["c"][10]="Land"
flightModes["c"][12]="Drift"
flightModes["c"][14]="Sport"
flightModes["c"][15]="Flip"
flightModes["c"][16]="AutoTune"
flightModes["c"][17]="PosHold"
flightModes["c"][18]="Brake"
flightModes["c"][19]="Throw"
flightModes["c"][20]="AvoidADSB"
flightModes["c"][21]="GuidedNOGPS"
flightModes["c"][22]="SmartRTL"
#ifdef TESTMODE
flightModes["c"][0]=""
flightModes["c"][9]=""
flightModes["c"][11]=""
flightModes["c"][13]=""
#endif --TESTMODE
#ifdef PLANE
-- plane flight modes
flightModes["p"][1]="Manual"
flightModes["p"][2]="Circle"
flightModes["p"][3]="Stabilize"
flightModes["p"][4]="Training"
flightModes["p"][5]="Acro"
flightModes["p"][6]="FlyByWireA"
flightModes["p"][7]="FlyByWireB"
flightModes["p"][8]="Cruise"
flightModes["p"][9]="Autotune"
flightModes["p"][11]="Auto"
flightModes["p"][12]="RTL"
flightModes["p"][13]="Loiter"
flightModes["p"][15]="AvoidADSB"
flightModes["p"][16]="Guided"
flightModes["p"][17]="Initializing"
flightModes["p"][18]="QStabilize"
flightModes["p"][19]="QHover"
flightModes["p"][20]="QLoiter"
flightModes["p"][21]="Qland"
flightModes["p"][22]="QRTL"
#ifdef TESTMODE
flightModes["p"][0]=""
flightModes["p"][10]=""
flightModes["p"][14]=""
#endif --TESTMODE
#endif --PLANE
#ifdef ROVER
-- rover flight modes
flightModes["r"][1]="Manual"
flightModes["r"][2]="Acro"
flightModes["r"][4]="Steering"
flightModes["r"][5]="Hold"
flightModes["r"][11]="Auto"
flightModes["r"][12]="RTL"
flightModes["r"][13]="SmartRTL"
flightModes["r"][16]="Guided"
flightModes["r"][17]="Initializing"
#ifdef TESTMODE
flightModes["r"][0]=""
flightModes["r"][6]=""
flightModes["r"][7]=""
flightModes["r"][8]=""
flightModes["r"][9]=""
flightModes["r"][10]=""
flightModes["r"][14]=""
flightModes["r"][15]=""
flightModes["r"][18]=""
flightModes["r"][19]=""
flightModes["r"][20]=""
flightModes["r"][21]=""
flightModes["r"][22]=""
#endif --TESTMODE
#endif --ROVER
--
local soundFileBasePath = "/SOUNDS/yaapu0"
local gpsStatuses = {}

gpsStatuses[0]="NoGPS"
gpsStatuses[1]="NoLock"
gpsStatuses[2]="2D"
gpsStatuses[3]="3D"
gpsStatuses[4]="DGPS"
gpsStatuses[5]="RTK"
gpsStatuses[6]="RTK"

local mavSeverity = {}
mavSeverity[0]="EMR"
mavSeverity[1]="ALR"
mavSeverity[2]="CRT"
mavSeverity[3]="ERR"
mavSeverity[4]="WRN"
mavSeverity[5]="NOT"
mavSeverity[6]="INF"
mavSeverity[7]="DBG"

#define CELLFULL 4.35
--------------------------------
-- FLVSS 1
local cell1min = 0
local cell1sum = 0
-- FLVSS 2
local cell2min = 0
local cell2sum = 0
-- FC 1
local cell1minFC = 0
local cell1sumFC = 0
local cell1maxFC = 0
-- FC 2
local cell2minFC = 0
local cell2sumFC = 0
local cell2maxFC = 0
-- A2
local cellminA2 = 0
local cellsumA2 = 0
local cellmaxA2 = 0
--------------------------------
-- STATUS
local flightMode = 0
local simpleMode = 0
local landComplete = 0
local statusArmed = 0
local battFailsafe = 0
local ekfFailsafe = 0
#ifndef ALARMS
local lastBattFailsafe = 0
local lastEkfFailsafe = 0
#endif --ALARMS
-- GPS
local numSats = 0
local gpsStatus = 0
local gpsHdopC = 100
local gpsAlt = 0
-- BATT
local cellcount = 0
local battsource = "na"
-- BATT 1
local batt1volt = 0
local batt1current = 0
local batt1mah = 0
local batt1sources = {
  a2 = false,
  vs = false,
  fc = false
}
-- BATT 2
local batt2volt = 0
local batt2current = 0
local batt2mah = 0
local batt2sources = {
  a2 = false,
  vs = false,
  fc = false
}
-- TELEMETRY
local SENSOR_ID,FRAME_ID,DATA_ID,VALUE
local c1,c2,c3,c4
local noTelemetryData = 1
-- HOME
local homeDist = 0
local homeAlt = 0
local homeAngle = -1
-- MESSAGES
local msgBuffer = ""
local lastMsgValue = 0
local lastMsgTime = 0
-- VELANDYAW
local vSpeed = 0
local hSpeed = 0
local yaw = 0
-- ROLLPITCH
local roll = 0
local pitch = 0
-- PARAMS
local paramId,paramValue
local frameType = -1
local battFailsafeVoltage = 0
local battFailsafeCapacity = 0
local batt1Capacity = 0
local batt2Capacity = 0
-- FLIGHT TIME
local seconds = 0
local lastTimerStart = 0
local timerRunning = 0
local flightTime = 0
-- EVENTS
local lastStatusArmed = 0
local lastGpsStatus = 0
local lastFlightMode = 0
local lastBattLevel = 0
-- battery levels
local batLevel = 99
local batLevels = {}
batLevels[12]=0
batLevels[11]=5
batLevels[10]=10
batLevels[9]=15
batLevels[8]=20
batLevels[7]=25
batLevels[6]=30
batLevels[5]=40
batLevels[4]=50
batLevels[3]=60
batLevels[2]=70
batLevels[1]=80
batLevels[0]=90
-- dual battery
local showDualBattery = false
--
#ifdef MINMAX  
  
#define MIN_CELL_FC 1
#define MIN_CELL1_FC 2
#define MIN_CELL2_FC 3
#define MIN_CELL_VS 4
#define MIN_CELL1_VS 5
#define MIN_CELL2_VS 6
#define MIN_CELL_A2 7
#define MIN_CELL1_A2 8
#define MIN_CELL2_A2 9

#define MIN_BATT_FC 10
#define MIN_BATT1_FC 11
#define MIN_BATT2_FC 12
#define MIN_BATT_VS 13
#define MIN_BATT1_VS 14
#define MIN_BATT2_VS 15
#define MIN_BATT_A2 16
#define MIN_BATT1_A2 17
#define MIN_BATT2_A2 18

#define MAX_CURR 19
#define MAX_CURR1 20
#define MAX_CURR2 21
#define MAX_POWER 22
#define MINMAX_ALT 23
#define MAX_GPSALT 24
#define MAX_VSPEED 25
#define MAX_HSPEED 26
#define MAX_DIST 27

-- offsets
local minmaxOffsets = {}
minmaxOffsets["fc"] = 0
minmaxOffsets["vs"] = 3
minmaxOffsets["a2"] = 6
minmaxOffsets["na"] = 0
--
local minmaxValues = {}
-- min
minmaxValues[1] = 0
minmaxValues[2] = 0
minmaxValues[3] = 0
minmaxValues[4] = 0
minmaxValues[5] = 0
minmaxValues[6] = 0
minmaxValues[7] = 0
minmaxValues[8] = 0
minmaxValues[9] = 0
minmaxValues[10] = 0
minmaxValues[11] = 0
minmaxValues[12] = 0
minmaxValues[13] = 0
minmaxValues[14] = 0
minmaxValues[15] = 0
minmaxValues[16] = 0
minmaxValues[17] = 0
minmaxValues[18] = 0
-- max
minmaxValues[19] = 0
minmaxValues[20] = 0
minmaxValues[21] = 0
minmaxValues[22] = 0
minmaxValues[23] = 0
minmaxValues[24] = 0
minmaxValues[25] = 0
minmaxValues[26] = 0
minmaxValues[27] = 0

local showMinMaxValues = false
#endif --MINMAX
--
#ifdef TESTMODE
-- TEST MODE
local thrOut = 0
#endif --TESTMODE

#ifdef X9
  
#define HUD_X 68
#define HUD_WIDTH 76

#define LEFTPANE_X 68
#define RIGHTPANE_X 68

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 7
#define TOPBAR_WIDTH 212

#define BOTTOMBAR_Y 56
#define BOTTOMBAR_HEIGHT 9
#define BOTTOMBAR_WIDTH 212

#define BOX1_X 0
#define BOX1_Y 38
#define BOX1_WIDTH 67  
#define BOX1_HEIGHT 8

#define BOX2_X 61
#define BOX2_Y 46
#define BOX2_WIDTH 17  
#define BOX2_HEIGHT 12

#define BATTVOLT_X 2
#define BATTVOLT_Y 43
#define BATTVOLT_YV 43
#define BATTVOLT_FLAGS MIDSIZE+PREC1
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCELL_X 27
#define BATTCELL_Y 10
#define BATTCELL_YV 11
#define BATTCELL_YS 20
#define BATTCELL_FLAGS DBLSIZE+PREC2

#define BATTCURR_X 37
#define BATTCURR_Y 43
#define BATTCURR_YA 43
#define BATTCURR_FLAGS MIDSIZE+PREC1
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 4
#define BATTPERC_Y 14
#define BATTPERC_YPERC 19
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 5
#define BATTGAUGE_Y 27
#define BATTGAUGE_WIDTH 59
#define BATTGAUGE_HEIGHT 5
#define BATTGAUGE_STEPS 10

#define BATTMAH_X 12
#define BATTMAH_Y 34
#define BATTMAH_FLAGS SMLSIZE+PREC1

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

#define GPS_X 0
#define GPS_Y 6
#define GPS_BORDER 0

#define ALTASL_X 2
#define ALTASL_Y 32
#define ALTASL_XLABEL 2
#define ALTASL_YLABEL 24

#define BATTPOWER_X 35
#define BATTPOWER_Y 39
#define BATTPOWER_YW 39
#define BATTPOWER_FLAGS SMLSIZE+INVERS
#define BATTPOWER_FLAGSW SMLSIZE+INVERS

#define HOMEDIST_X 35
#define HOMEDIST_Y 32
#define HOMEDIST_XLABEL 34
#define HOMEDIST_YLABEL 25
#define HOMEDIST_FLAGS SMLSIZE
#define HOMEDIST_ARROW_WIDTH 8

#define HOMEDIR_X 75
#define HOMEDIR_Y 48
#define HOMEDIR_R 7

#define FLIGHTTIME_X 180
#define FLIGHTTIME_Y 0
#define FLIGHTTIME_FLAGS SMLSIZE+INVERS

#define RSSI_X 69
#define RSSI_Y 0
#define RSSI_FLAGS SMLSIZE+INVERS 

#define TXVOLTAGE_X 116
#define TXVOLTAGE_Y 0
#define TXVOLTAGE_FLAGS SMLSIZE+INVERS

#endif --X9

#ifdef X7
  
#define HUD_X 0
#define HUD_WIDTH 64

#define LEFTPANE_X 68
#define RIGHTPANE_X 68

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
#define BOX2_Y 46
#define BOX2_WIDTH 17  
#define BOX2_HEIGHT 12

#define BATTVOLT_X 1
#define BATTVOLT_Y 29
#define BATTVOLT_YV 29
#define BATTVOLT_FLAGS INVERS+PREC1+SMLSIZE
#define BATTVOLT_FLAGSV INVERS+SMLSIZE

#define BATTCELL_X 24
#define BATTCELL_Y 27
#define BATTCELL_YV 28
#define BATTCELL_YS 36
#define BATTCELL_FLAGS DBLSIZE+PREC2

#define BATTCURR_X 1
#define BATTCURR_Y 36
#define BATTCURR_YA 36
#define BATTCURR_FLAGS INVERS+SMLSIZE+PREC1
#define BATTCURR_FLAGSA INVERS+SMLSIZE

#define BATTPERC_X 16
#define BATTPERC_Y 44
#define BATTPERC_YPERC 48
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 0
#define BATTGAUGE_Y 0
#define BATTGAUGE_WIDTH 0
#define BATTGAUGE_HEIGHT 0
#define BATTGAUGE_STEPS 0

#define BATTMAH_X 64
#define BATTMAH_Y 43
#define BATTMAH_FLAGS SMLSIZE+PREC1

#define FLIGHTMODE_X 1
#define FLIGHTMODE_Y 0
#define FLIGHTMODE_FLAGS SMLSIZE+INVERS

#define HOMEANGLE_X 0
#define HOMEANGLE_Y 0
#define HOMEANGLE_XLABEL 0
#define HOMEANGLE_YLABEL 0
#define HOMEANGLE_FLAGS SMLSIZE

#define HSPEED_X 0
#define HSPEED_Y 0
#define HSPEED_XLABEL 0
#define HSPEED_YLABEL 0
#define HSPEED_XDIM 0
#define HSPEED_YDIM 0
#define HSPEED_FLAGS SMLSIZE
#define HSPEED_ARROW_WIDTH 10

#define GPS_X 65
#define GPS_Y 6
#define GPS_BORDER 0

#define ALTASL_X 0
#define ALTASL_Y 0
#define ALTASL_XLABEL 0
#define ALTASL_YLABEL 0

#define HOMEDIST_X 76
#define HOMEDIST_Y 21
#define HOMEDIST_XLABEL 66
#define HOMEDIST_YLABEL 21
#define HOMEDIST_FLAGS SMLSIZE
#define HOMEDIST_ARROW_WIDTH 7

#define HOMEDIR_X 73
#define HOMEDIR_Y 50
#define HOMEDIR_R 7

#define FLIGHTTIME_X 96
#define FLIGHTTIME_Y 0
#define FLIGHTTIME_FLAGS SMLSIZE+INVERS

#define RSSI_X 60
#define RSSI_Y 0
#define RSSI_FLAGS SMLSIZE+INVERS 

#define TXVOLTAGE_X 104
#define TXVOLTAGE_Y 21
#define TXVOLTAGE_FLAGS SMLSIZE

#endif --X7
--------------------------------------------------------------------------------
-- CONFIGURATION MENU
--------------------------------------------------------------------------------
local conf = {
  language = "en",
  defaultBattSource = nil, -- auto
  battAlertLevel1 = 0,
  battAlertLevel2 = 0,
  battCapOverride1 = 0,
  battCapOverride2 = 0,
  disableAllSounds = false,
  disableMsgBeep = false,
  disableMsgBlink = false,
  timerAlert = 0,
  minAltitudeAlert = 0,
  maxAltitudeAlert = 0,
  maxDistanceAlert = 0
}
--
#ifdef MENUEX
--------------------------------------------------------------------------------
-- EXTENDED MENU VALUE,COMBO,COMBOVALUE
--------------------------------------------------------------------------------
#define MENU_PAGESIZE   5
#define MENU_ROWHEIGHT  9
#define MENU_Y          1
#define TYPEVALUE           0
#define TYPECOMBO           1
#define TYPECOMBOVALUE      2

local menu  = {
  selectedItem = 1,
  editSelected = false,
  editComboValue = false,
  page  = 0
}

local menuItems = {
  {"force sound language:", TYPECOMBO, "L1", 1, { "english", "italiano" } , {"en","it"} },
  {"battery warning level:", TYPEVALUE, "V1", 350, 320,420,"V",PREC2 },
  {"battery critical level:", TYPEVALUE, "V2", 330, 320,420,"V",PREC2 },
  {"battery capacity override:", TYPECOMBOVALUE, "B1", 1, { {nil},{0,0,500}, {27,0,500}, {30,0,500}, {52,0,500} }, PREC1,"Ah"},
  {"battery capacity override:", TYPECOMBOVALUE, "B2", 1, { {nil},{0,0,500}, {27,0,500}, {30,0,500}, {52,0,500} }, PREC1,"Ah"},
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable message beep:", TYPECOMBO, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable message blink:", TYPECOMBO, "S3", 1, { "no", "yes" }, { false, true } }
}

local function getConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues()
  conf.language = menuItems[1][6][menuItems[1][4]]
  conf.battAlertLevel1 = menuItems[2][4]
  conf.battAlertLevel2 = menuItems[3][4]
  conf.battCapOverride1 = menuItems[4][5][menuItems[4][4]][1]*0.1
  conf.battCapOverride2 = menuItems[5][5][menuItems[5][4]][1]*0.1
  conf.disableAllSounds = menuItems[6][6][menuItems[6][4]]
  conf.disableMsgBeep = menuItems[7][6][menuItems[7][4]]
  conf.disableMsgBlink = menuItems[8][6][menuItems[8][4]]  
  collectgarbage()
end

local function loadConfig()
  local cfg = io.open(getConfigFilename(),"r")
  if cfg == nil then
    return
  end
  local str = io.read(cfg,200)
  if string.len(str) > 0 then
    for i=1,#menuItems
    do
      if  menuItems[i][2] == TYPECOMBOVALUE then
        local value = string.match(str, menuItems[i][3]..":(%d+)")
        if value ~= nil then
          menuItems[i][4] = tonumber(value)
          for c=1,#menuItems[i][5]
          do
            local value_option = string.match(str, menuItems[i][3].."_O"..c..":(%d+)")
            if value_option ~= nil then
              if value_option == "---" then
                menuItems[i][5][c] = nil
              else
                menuItems[i][5][c][1] = tonumber(value_option)
              end
            end
          end
        end
      else
        local value = string.match(str, menuItems[i][3]..":(%d+)")
        if value ~= nil then
          menuItems[i][4] = tonumber(value)
        end
      end
    end

  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function saveConfig()
  local cfg = assert(io.open(getConfigFilename(),"w"))
  if cfg == nil then
    return
  end
  for i=1,#menuItems
  do
    if  menuItems[i][2] == TYPECOMBOVALUE then
      io.write(cfg,menuItems[i][3],":",menuItems[i][4],"[")
      for c=1,#menuItems[i][5]
      do
        if menuItems[i][5][c][1] == nil then
          io.write(cfg,menuItems[i][3],"_","O",c,":","---")
        else
          io.write(cfg,menuItems[i][3],"_","O",c,":",menuItems[i][5][c][1])
        end
        if c < #menuItems[i][5] then
          io.write(cfg,",")
        end
      end
      io.write(cfg,"]")
    else
      io.write(cfg,menuItems[i][3],":",menuItems[i][4])
    end
    if i < #menuItems then
      io.write(cfg,",")
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function drawConfigMenuBars()
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y+1,getConfigFilename(),SMLSIZE+INVERS)
  lcd.drawText(BOTTOMBAR_WIDTH,BOTTOMBAR_Y+1,"/2",SMLSIZE+INVERS+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(),BOTTOMBAR_Y+1,menu.page+1,SMLSIZE+INVERS+RIGHT)
  lcd.drawText(lcd.getLastLeftPos(),BOTTOMBAR_Y+1,"Page:",SMLSIZE+INVERS+RIGHT)
end

local function incMenuItem(idx)
  if menuItems[idx][2] == TYPEVALUE then
    menuItems[idx][4] = menuItems[idx][4] + 10
    if menuItems[idx][4] > menuItems[idx][6] then
      menuItems[idx][4] = menuItems[idx][6]
    end
  elseif menuItems[idx][2] == TYPECOMBO then
    menuItems[idx][4] = menuItems[idx][4] + 1
    if menuItems[idx][4] > #menuItems[idx][5] then
      menuItems[idx][4] = 1
    end
  else
    if menu.editComboValue then
      if menuItems[idx][5][menuItems[idx][4]][1] ~= nil then
        menuItems[idx][5][menuItems[idx][4]][1] = menuItems[idx][5][menuItems[idx][4]][1] + 1
        if menuItems[idx][5][menuItems[idx][4]][1] > menuItems[idx][5][menuItems[idx][4]][3] then
          menuItems[idx][5][menuItems[idx][4]][1] = menuItems[idx][5][menuItems[idx][4]][2]
        end
      end
    else
      menuItems[idx][4] = menuItems[idx][4] + 1
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
    end
  end
end

local function decMenuItem(idx)
  if menuItems[idx][2] == TYPEVALUE then
    menuItems[idx][4] = menuItems[idx][4] - 10
    if menuItems[idx][4] < menuItems[idx][5] then
      menuItems[idx][4] = menuItems[idx][5]
    end
  elseif menuItems[idx][2] == TYPECOMBO then
    menuItems[idx][4] = menuItems[idx][4] - 1
    if menuItems[idx][4] < 1 then
      menuItems[idx][4] = #menuItems[idx][5]
    end
  else
    if menu.editComboValue then
      if menuItems[idx][5][menuItems[idx][4]][1] ~= nil then
        menuItems[idx][5][menuItems[idx][4]][1] = menuItems[idx][5][menuItems[idx][4]][1] - 1
        if menuItems[idx][5][menuItems[idx][4]][1] < menuItems[idx][5][menuItems[idx][4]][2] then
          menuItems[idx][5][menuItems[idx][4]][1] = menuItems[idx][5][menuItems[idx][4]][3]
        end
      end
    else
      menuItems[idx][4] = menuItems[idx][4] - 1
      if menuItems[idx][4] < 1 then
        menuItems[idx][4] = #menuItems[idx][5]
      end
    end
  end
end

local function drawEditItem(m)
  local idx = menu.page*MENU_PAGESIZE + m
  if menuItems[idx][2] == TYPEVALUE then
    lcd.drawNumber(150,MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][4],0+SMLSIZE+INVERS+BLINK+menuItems[idx][8])
    lcd.drawText(lcd.getLastRightPos(),MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][7],0+SMLSIZE+INVERS+BLINK+menuItems[idx][8])
  elseif menuItems[idx][2] == TYPECOMBO then
    lcd.drawText(150,MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][5][menuItems[idx][4]],0+SMLSIZE+INVERS+BLINK)
  else
    if menu.editComboValue then
      if menuItems[idx][5][menuItems[idx][4]][1] == nil then -- value cannot be changed
        lcd.drawText(150,MENU_Y + m*MENU_ROWHEIGHT, "---",SMLSIZE+INVERS+BLINK+menuItems[idx][6])
      else
        lcd.drawNumber(150,MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][5][menuItems[idx][4]][1],0+SMLSIZE+INVERS+BLINK+menuItems[idx][6])
        lcd.drawText(lcd.getLastRightPos(),MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][7],0+SMLSIZE+INVERS+BLINK+menuItems[idx][6])
        lcd.drawText(lcd.getLastRightPos() + 5,MENU_Y + m*MENU_ROWHEIGHT, "+/-",0+SMLSIZE+INVERS+BLINK)
      end
    else
      if menuItems[idx][5][menuItems[idx][4]][1] == nil then
        lcd.drawText(150,MENU_Y + m*MENU_ROWHEIGHT, "---",0+SMLSIZE+INVERS+BLINK)
      else
        lcd.drawNumber(150,MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][5][menuItems[idx][4]][1],0+SMLSIZE+INVERS+BLINK+menuItems[idx][6])
        lcd.drawText(lcd.getLastRightPos(),MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][7],0+SMLSIZE+INVERS+BLINK+menuItems[idx][6])
      end
    end
  end
end

local function drawItem(m,flags)
  local idx = menu.page*MENU_PAGESIZE + m
  if menuItems[idx][2] == TYPEVALUE then
    lcd.drawNumber(150,MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][4],0+SMLSIZE+menuItems[idx][8]+flags)
    lcd.drawText(lcd.getLastRightPos(),MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][7],0+SMLSIZE+menuItems[idx][8]+flags)
  elseif menuItems[idx][2] == TYPECOMBO then
    lcd.drawText(150,MENU_Y +  m*MENU_ROWHEIGHT, menuItems[idx][5][menuItems[idx][4]],0+SMLSIZE+flags)
  else
    if menuItems[idx][5][menuItems[idx][4]][1] == nil then
      lcd.drawText(150,MENU_Y + m*MENU_ROWHEIGHT, "---",0+SMLSIZE+menuItems[idx][6]+flags)
    else
      lcd.drawNumber(150,MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][5][menuItems[idx][4]][1],0+SMLSIZE+menuItems[idx][6]+flags)
      lcd.drawText(lcd.getLastRightPos(),MENU_Y + m*MENU_ROWHEIGHT, menuItems[idx][7],0+SMLSIZE+menuItems[idx][6]+flags)
    end
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if menu.editSelected and event == EVT_ENTER_BREAK then
    if menuItems[menu.selectedItem][2] == TYPECOMBOVALUE and menuItems[menu.selectedItem][5][menuItems[menu.selectedItem][4]][1] ~= nil then
      menu.editComboValue = not menu.editComboValue
      if not menu.editComboValue then
        menu.editSelected = false
      end
    else
      menu.editSelected = not menu.editSelected
    end
  elseif menu.editSelected and event == EVT_PLUS_BREAK then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and event == EVT_MINUS_BREAK then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and event == EVT_PLUS_BREAK then
    menu.selectedItem = (menu.selectedItem - 1)
  elseif not menu.editSelected and event == EVT_MINUS_BREAK then
    menu.selectedItem = (menu.selectedItem + 1)
  elseif not menu.editComboValue and event == EVT_ENTER_BREAK then
    menu.editSelected = not menu.editSelected
  elseif menu.editComboValue and event == EVT_ENTER_BREAK then
    menu.editComboValue = not menu.editComboValue
  end
  --wrap
  if menu.selectedItem - menu.page*MENU_PAGESIZE > math.min(MENU_PAGESIZE,#menuItems - menu.page*MENU_PAGESIZE) then
    menu.selectedItem = 1 + menu.page*MENU_PAGESIZE
  elseif menu.selectedItem - menu.page*MENU_PAGESIZE < 1 then
    if menu.page == 0 then
      menu.selectedItem = MENU_PAGESIZE
    else
      menu.selectedItem = menu.page*MENU_PAGESIZE + math.min(menu.page*MENU_PAGESIZE,#menuItems-menu.page*MENU_PAGESIZE)
    end
  end

  for m=1,math.min(MENU_PAGESIZE,#menuItems - menu.page*MENU_PAGESIZE) do
    local idx = menu.page*MENU_PAGESIZE + m
    lcd.drawText(2,1 + m*MENU_ROWHEIGHT, menuItems[idx][1],0+SMLSIZE)
    if idx == menu.selectedItem then
      if menu.editSelected then
        drawEditItem(m)
      else
        drawItem(m,INVERS)
      end
    else
      drawItem(m,0)
    end
  end
end
#else --MENUEX
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

#define L1 1
#define V1 2
#define V2 3
#define B1 4
#define B2 5
#define S1 6
#define S2 7
#define S3 8
#define VS 9
#define T1 10
#define A1 11
#define A2 12
#define D1 13
#define T2 14
#define AA 15
  
local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}

#ifdef X9
local menuItems = {
  {"voice language:", TYPECOMBO, "L1", 1, { "english", "italian", "french" } , {"en","it","fr"} },
  {"batt alert level 1:", TYPEVALUE, "V1", 350, 320,420,"V",PREC2,5 },
  {"batt alert level 2:", TYPEVALUE, "V2", 350, 320,420,"V",PREC2,5 },
  {"batt[1] capacity override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] capacity override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", TYPECOMBO, "S3", 1, { "no", "yes" }, { false, true } },
  {"default voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 10,600,"sec",0,5 },
#ifdef ALERTS 
  {"ack alerts after 10s:", TYPECOMBO, "AA", 2, { "yes", "no" } , {true,false} },
#endif --ALERTS
}
#endif --X9

#ifdef X7
local menuItems = {
  {"voice language:", TYPECOMBO, "L1", 1, { "eng", "ita", "fre" } , {"en","it","fr"} },
  {"batt alert level 1:", TYPEVALUE, "V1", 350, 320,420,"V",PREC2,5 },
  {"batt alert level 2:", TYPEVALUE, "V2", 350, 320,420,"V",PREC2,5 },
  {"batt[1] mAh override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] mAh override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", TYPECOMBO, "S3", 1, { "no", "yes" }, { false, true } },
  {"def voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 10,600,"sec",0,5 },
#ifdef ALERTS 
  {"ack alerts after 10s:", TYPECOMBO, "AA", 2, { "yes", "no" } , {true,false} },
#endif --ALERTS
}
#endif --X7

local function getConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues()
  conf.language = menuItems[L1][6][menuItems[L1][4]]
  conf.battAlertLevel1 = menuItems[V1][4]
  conf.battAlertLevel2 = menuItems[V2][4]
  conf.battCapOverride1 = menuItems[B1][4]*0.1
  conf.battCapOverride2 = menuItems[B2][4]*0.1
  conf.disableAllSounds = menuItems[S1][6][menuItems[S1][4]]
  conf.disableMsgBeep = menuItems[S2][6][menuItems[S2][4]]
  conf.disableMsgBlink = menuItems[S3][6][menuItems[S3][4]]  
  conf.defaultBattSource = menuItems[VS][6][menuItems[VS][4]]
  conf.timerAlert = math.floor(menuItems[T1][4]*0.1*60)
  conf.minAltitudeAlert = menuItems[A1][4]*0.1
  conf.maxAltitudeAlert = menuItems[A2][4]
  conf.maxDistanceAlert = menuItems[D1][4]
  --
  if conf.defaultBattSource ~= nil then
    battsource = conf.defaultBattSource
  end
  collectgarbage()
end

local function loadConfig()
  local cfg = io.open(getConfigFilename(),"r")
  if cfg == nil then
    return
  end
  local str = io.read(cfg,200)
  if string.len(str) > 0 then
    for i=1,#menuItems
    do
		local value = string.match(str, menuItems[i][3]..":(%d+)")
		if value ~= nil then
		  menuItems[i][4] = tonumber(value)
		end
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function saveConfig()
  local cfg = assert(io.open(getConfigFilename(),"w"))
  if cfg == nil then
    return
  end
  for i=1,#menuItems
  do
    io.write(cfg,menuItems[i][3],":",menuItems[i][4])
    if i < #menuItems then
      io.write(cfg,",")
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function drawConfigMenuBars()
#ifdef X9
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawRectangle(0, TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawText(0,0,VERSION,SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y+1,getConfigFilename(),SMLSIZE+INVERS)
  lcd.drawNumber(BOTTOMBAR_WIDTH,BOTTOMBAR_Y+1,#menuItems,SMLSIZE+INVERS+RIGHT)
  lcd.drawText(lcd.getLastLeftPos(),BOTTOMBAR_Y+1,"/",SMLSIZE+INVERS+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(),BOTTOMBAR_Y+1,menu.selectedItem,SMLSIZE+INVERS+RIGHT)
#endif --X9
#ifdef X7
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawRectangle(0, TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawText(0,0,VERSION,SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y-2, BOTTOMBAR_WIDTH, 9, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y-2, BOTTOMBAR_WIDTH, 9, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y-1,string.sub(getConfigFilename(),8),SMLSIZE+INVERS)
  lcd.drawNumber(BOTTOMBAR_WIDTH,BOTTOMBAR_Y-1,#menuItems,SMLSIZE+INVERS+RIGHT)
  lcd.drawText(lcd.getLastLeftPos(),BOTTOMBAR_Y-1,"/",SMLSIZE+INVERS+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(),BOTTOMBAR_Y-1,menu.selectedItem,SMLSIZE+INVERS+RIGHT)
#endif --X7
end

local function incMenuItem(idx)
  if menuItems[idx][2] == TYPEVALUE then
    menuItems[idx][4] = menuItems[idx][4] + menuItems[idx][9]
    if menuItems[idx][4] > menuItems[idx][6] then
      menuItems[idx][4] = menuItems[idx][6]
    end
  else
    menuItems[idx][4] = menuItems[idx][4] + 1
    if menuItems[idx][4] > #menuItems[idx][5] then
      menuItems[idx][4] = 1
    end
  end
end

local function decMenuItem(idx)
  if menuItems[idx][2] == TYPEVALUE then
    menuItems[idx][4] = menuItems[idx][4] - menuItems[idx][9]
    if menuItems[idx][4] < menuItems[idx][5] then
      menuItems[idx][4] = menuItems[idx][5]
    end
  else
    menuItems[idx][4] = menuItems[idx][4] - 1
    if menuItems[idx][4] < 1 then
      menuItems[idx][4] = #menuItems[idx][5]
    end
  end
end

local function drawItem(idx,flags)
  if menuItems[idx][2] == TYPEVALUE then
    if menuItems[idx][4] == 0 then
      lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, "---",0+SMLSIZE+flags+menuItems[idx][8])
    else
      lcd.drawNumber(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][4],0+SMLSIZE+flags+menuItems[idx][8])
      lcd.drawText(lcd.getLastRightPos(),MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][7],SMLSIZE+flags+menuItems[idx][8])
    end
  else
    lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][5][menuItems[idx][4]],SMLSIZE+flags)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK then
	menu.editSelected = not menu.editSelected
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_PLUS_REPT) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_MINUS_REPT) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT) then
    menu.selectedItem = (menu.selectedItem - 1)
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT) then
    menu.selectedItem = (menu.selectedItem + 1)
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1 
  elseif menu.selectedItem  < 1 then
      menu.selectedItem = #menuItems
  end
  --
  if menu.selectedItem > MENU_PAGESIZE then
    menu.offset = menu.selectedItem - MENU_PAGESIZE
  elseif menu.selectedItem <= MENU_PAGESIZE then
    menu.offset = 0
  end
  --
  for m=1+menu.offset,math.min(#menuItems,MENU_PAGESIZE+menu.offset) do
    lcd.drawText(2,MENU_Y + (m-menu.offset-1)*7, menuItems[m][1],0+SMLSIZE)
    if m == menu.selectedItem then
      if menu.editSelected then
        drawItem(m,INVERS+BLINK)
      else
        drawItem(m,INVERS)
      end
    else
      drawItem(m,0)
    end
  end
end
#endif --MENUEX

local function playSound(soundFile)
  if conf.disableAllSounds then
    return
  end
  playFile(soundFileBasePath .."/"..conf.language.."/".. soundFile..".wav")
end

----------------------------------------------
-- sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
local function playSoundByFrameTypeAndFlightMode(frameType,flightMode)
  if conf.disableAllSounds then
    return
  end
  if frameType ~= -1 then
    if flightModes[frameTypes[frameType]][flightMode] ~= nil then
      playFile(soundFileBasePath.."/"..conf.language.."/".. string.lower(flightModes[frameTypes[frameType]][flightMode])..".wav")
    end
  end
end

local function roundTo(val,int)
  return math.floor(val/int) * int
end

local function drawHArrow(x,y,width,left,right)
  lcd.drawLine(x, y, x + width,y, SOLID, 0)
  if left == true then
    lcd.drawLine(x + 1,y  - 1,x + 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + 1,x + 2,y  + 2, SOLID, 0)
  end
  if right == true then
    lcd.drawLine(x + width - 1,y  - 1,x + width - 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + width - 1,y  + 1,x + width - 2,y  + 2, SOLID, 0)
  end
end

local function drawVArrow(x,y,h,top,bottom)
  lcd.drawLine(x,y,x,y + h, SOLID, 0)
  if top == true then
    lcd.drawLine(x - 1,y + 1,x - 2,y  + 2, SOLID, 0)
    lcd.drawLine(x + 1,y + 1,x + 2,y  + 2, SOLID, 0)
  end
  if bottom == true then
    lcd.drawLine(x - 1,y  + h - 1,x - 2,y + h - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + h - 1,x + 2,y + h - 2, SOLID, 0)
  end
end
--
local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,5,5,SOLID)
  lcd.drawLine(x+2,y+3,x+2,y+4,SOLID,FORCE)
  lcd.drawPoint(x+2,y-1,FORCE)
  lcd.drawLine(x,y+1,x+5,y+1,SOLID,FORCE)
  lcd.drawLine(x-1,y+1,x+2,y-2,SOLID, FORCE)
  lcd.drawLine(x+5,y+1,x+3,y-1,SOLID, FORCE)
end
-- draws a line centered at ox,oy with given angle and length WITH CROPPING
local function drawCroppedLine(ox,oy,angle,len,style,minX,maxX,minY,maxY)
  --
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  --
  local x1 = ox - xx
  local x2 = ox + xx
  local y1 = oy - yy
  local y2 = oy + yy
  --
  -- crop right
  if (x1 >= maxX and x2 >= maxX) then
    return
  end

  if (x1 >= maxX) then
    y1 = y1 - math.tan(math.rad(angle)) * (maxX - x1)
    x1 = maxX - 1
  end

  if (x2 >= maxX) then
    y2 = y2 + math.tan(math.rad(angle)) * (maxX - x2)
    x2 = maxX - 1
  end
  -- crop left
  if (x1 <= minX and x2 <= minX) then
    return
  end

  if (x1 <= minX) then
    y1 = y1 - math.tan(math.rad(angle)) * (x1 - minX)
    x1 = minX + 1
  end

  if (x2 <= minX) then
    y2 = y2 + math.tan(math.rad(angle)) * (x2 - minX)
    x2 = minX + 1
  end
  --
  -- crop right
  if (y1 >= maxY and y2 >= maxY) then
    return
  end

  if (y1 >= maxY) then
    x1 = x1 - (y1 - maxY)/math.tan(math.rad(angle))
    y1 = maxY - 1
  end

  if (y2 >= maxY) then
    x2 = x2 -  (y2 - maxY)/math.tan(math.rad(angle))
    y2 = maxY - 1
  end
  -- crop left
  if (y1 <= minY and y2 <= minY) then
    return
  end

  if (y1 <= minY) then
    x1 = x1 + (minY - y1)/math.tan(math.rad(angle))
    y1 = minY + 1
  end

  if (y2 <= minY) then
    x2 = x2 + (minY - y2)/math.tan(math.rad(angle))
    y2 = minY + 1
  end

  lcd.drawLine(x1,y1,x2,y2, style,0)
end

#ifdef DEV
local function draw8(x0,y0,x,y)
  lcd.drawPoint(x0 + x, y0 + y);
  lcd.drawPoint(x0 + y, y0 + x);
  lcd.drawPoint(x0 - y, y0 + x);
  lcd.drawPoint(x0 - x, y0 + y);
  lcd.drawPoint(x0 - x, y0 - y);
  lcd.drawPoint(x0 - y, y0 - x);
  lcd.drawPoint(x0 + y, y0 - x);
  lcd.drawPoint(x0 + x, y0 - y);
end

local function drawCircle10(x0,y0)
  draw8(x0,y0,5,1)
  draw8(x0,y0,5,2)
  draw8(x0,y0,4,3)
  draw8(x0,y0,4,4)
  lcd.drawPoint(x0 + 5,y0)
  lcd.drawPoint(x0 - 5,y0)
  lcd.drawPoint(x0,y0 + 5)
  lcd.drawPoint(x0,y0 - 5)
end

local function drawCircle(x0,y0,radius,delta)
  local x = radius-1
  local y = 0
  local dx = delta
  local dy = delta
  local err = dx - bit32.lshift(radius,1)
  while (x >= y) do
    lcd.drawPoint(x0 + x, y0 + y);
    lcd.drawPoint(x0 + y, y0 + x);
    lcd.drawPoint(x0 - y, y0 + x);
    lcd.drawPoint(x0 - x, y0 + y);
    lcd.drawPoint(x0 - x, y0 - y);
    lcd.drawPoint(x0 - y, y0 - x);
    lcd.drawPoint(x0 + y, y0 - x);
    lcd.drawPoint(x0 + x, y0 - y);
    if err <= 0 then
      y=y+1
      err = err + dy
      dy = dy + 2
    end
    if err > 0 then

      x=x-1
      dx = dx + 2
      err = err + dx - bit32.lshift(radius,1)
    end
  end
end

local function drawHomePad(x0,y0)
  drawCircle(x0 + 5,y0,5,2)
  lcd.drawText(x0 + 5 - 2,y0 - 3,"H")
end
#endif --DEV

local function drawNumberWithTwoDims(x,y,yTop,yBottom,number,topDim,bottomDim,flags,topFlags,bottomFlags)
  lcd.drawNumber(x, y, number, flags)
  local lx = lcd.getLastRightPos()
  lcd.drawText(lx, yTop, topDim, topFlags)
  lcd.drawText(lx, yBottom, bottomDim, bottomFlags)
end

local function drawNumberWithDim(x,y,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(lcd.getLastRightPos(), yDim, dim, dimFlags)
end

#ifdef LOGTELEMETRY
local function logMessageToFile(msg)
  local logFile = io.open("yaapu.log","a")
  io.write(logFile,string.format("%d,%s", getTime(), msg),"\r\n")
  io.close(logFile)
end

local function logTelemetryToFile(S_ID,F_ID,D_ID,VA)
  local lc1 = 0
  local lc2 = 0
  local lc3 = 0
  local lc4 = 0
  if (S_ID) then
    lc1 = S_ID
  end
  if (F_ID) then
    lc2 = F_ID
  end
  if (D_ID) then
    lc3 = D_ID
  end
  if (VA) then
    lc4 = VA
  end
  local logFile = io.open("yaapu.log","a")
  io.write(logFile,string.format("%d,%#04x,%#04x,%#04x,%#04x", getTime(), lc1, lc2, lc3, lc4),"\r\n")
  io.close(logFile)
end
#endif --LOGTELEMETRY

#define MAX_MESSAGES 9

local messages = {
  -- { idx,severity,message,duplicates }
}

local function pushMessage(severity, msg)
  if  conf.disableMsgBeep == false and conf.disableAllSounds == false then
    if ( severity < 4) then
      playTone(400,300,0)
    else
      playTone(600,300,0)
    end
  end
  -- wrap at 9
  if #messages == MAX_MESSAGES and messages[#messages][3] ~= msg then
    for i=1,MAX_MESSAGES-1 do
      messages[i]=messages[i+1]
    end
    -- trunc at 9
    messages[MAX_MESSAGES] = nil
  end
  -- is there at least 1 message?
  local nextIdx = 1
  if messages[#messages] then
    -- is it a duplicate?
    if messages[#messages][3] == msg then
      messages[#messages][4] = messages[#messages][4] + 1
      return
    end
    nextIdx = messages[#messages][1] + 1
  end
  -- append new message
  messages[#messages+1] = {nextIdx, severity, msg, 1}
  collectgarbage()
end
--
local function startTimer()
  lastTimerStart = getTime()/100
end

local function stopTimer()
  seconds = seconds + getTime()/100 - lastTimerStart
  lastTimerStart = 0
end

#ifdef TESTMODE
-----------------------------------------------------
-- TEST MODE
-----------------------------------------------------
local function symTimer()
#ifdef DEMO
  seconds = 60 * 9 + 30
#endif --DEMO
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
    landComplete = 1
  else
    landComplete = 0
  end
end

local function symGPS()
  thrOut = getValue("thr")
  if thrOut > 500 then
    numSats = 13
    gpsStatus = 5
    gpsHdopC = 6
    ekfFailsafe = 0
    battFailsafe = 0
    noTelemetryData = 0
    statusArmed = 1
  elseif thrOut < 500 and thrOut > 0  then
    numSats = 13
    gpsStatus = 4
    gpsHdopC = 6
    ekfFailsafe = 1
    battFailsafe = 0
    noTelemetryData = 0
    statusArmed = 1
  elseif thrOut > -500  then
    numSats = 6
    gpsStatus = 3
    gpsHdopC = 120
    ekfFailsafe = 0
    battFailsafe = 1
    noTelemetryData = 0
    statusArmed = 0
  else
    numSats = 0
    gpsStatus = 0
    gpsHdopC = 100
    ekfFailsafe = 0
    battFailsafe = 0
    noTelemetryData = 1
    statusArmed = 0
  end
end

local function symFrameType()
  local ch11 = getValue("ch11")
  if ch11 < -300 then
    frameType = 2
  elseif ch11 < 300 then
    frameType = 1
  else
    frameType = 10
  end
end

local function symBatt()
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
#ifdef DEMO
    if battFailsafe == 1 then
      minmaxValues[MIN_BATT_FC] = CELLCOUNT * 3.40 * 10
      minmaxValues[MIN_BATT1_FC] = CELLCOUNT * 3.40 * 10
      minmaxValues[MIN_BATT2_FC] = CELLCOUNT * 3.43 * 10
      minmaxValues[MIN_CELL_FC] = 340
      minmaxValues[MIN_CELL1_FC] = 340
      minmaxValues[MIN_CELL2_FC] = 343
      minmaxValues[MAX_CURR] = 341 + 335
      minmaxValues[MAX_CURR1] = 341
      minmaxValues[MAX_CURR2] = 335
      minmaxValues[MAX_POWER] = (CELLCOUNT * 3.43)*(34.1 + 33.5)
      -- battery voltage
      batt1current = 235
      batt1volt = CELLCOUNT * 3.43 * 10
      batt1Capacity = 5200
      batt1mah = 4400
#ifdef BATT2TEST
      batt2current = 238
      batt2volt = CELLCOUNT  * 3.44 * 10
      batt2Capacity = 5200
      batt2mah = 4500
#endif --BATT2TEST
    else
      minmaxValues[MIN_BATT_FC] = CELLCOUNT * 3.75 * 10
      minmaxValues[MIN_BATT1_FC] = CELLCOUNT * 3.75 * 10
      minmaxValues[MIN_BATT2_FC] = CELLCOUNT * 3.77 * 10
      minmaxValues[MIN_CELL_FC] = 375
      minmaxValues[MIN_CELL1_FC] = 375
      minmaxValues[MIN_CELL2_FC] = 377
      minmaxValues[MAX_CURR] = 341+335
      minmaxValues[MAX_CURR1] = 341
      minmaxValues[MAX_CURR2] = 335
      minmaxValues[MAX_POWER] = (CELLCOUNT * 3.89)*(34.1+33.5)
      -- battery voltage
      batt1current = 235
      batt1volt = CELLCOUNT * 3.87 * 10
      batt1Capacity = 5200
      batt1mah = 2800
#ifdef BATT2TEST
      batt2current = 238
      batt2volt = CELLCOUNT * 3.89 * 10
      batt2Capacity = 5200
      batt2mah = 2700
#endif --BATT2TEST
    end
#else --DEMO
    -- battery voltage
    batt1current = 100 +  ((thrOut)*0.01 * 30)
    batt1volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    batt1Capacity = 5200
    batt1mah = math.abs(1000*(thrOut/200))
#ifdef BATT2TEST
    batt2current = 100 +  ((thrOut)*0.01 * 30)
    batt2volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    batt2Capacity = 5200
    batt2mah = math.abs(1000*(thrOut/200))
#endif --BATT2TEST
#endif --DEMO
  -- flightmode
#ifdef DEMO
    flightMode = 1
    minmaxValues[MAX_GPSALT] = 270*0.1
    minmaxValues[MAX_DIST] = 130
    gpsAlt = 200
    homeDist = 95
#else --DEMO
    flightMode = math.floor(20 * math.abs(thrOut)*0.001)
    gpsAlt = math.floor(10 * math.abs(thrOut)*0.1)
    homeDist = math.floor(10 * math.abs(thrOut)*0.1)
#endif --DEMO
  else
    batt1mah = 0
  end
end

-- simulates attitude by using channel 1 for roll, channel 2 for pitch and channel 4 for yaw
local function symAttitude()
#ifdef DEMO
  roll = 14
  pitch = -0.8
  yaw = 33
#else --DEMO
  local rollCh = 0
  local pitchCh = 0
  local yawCh = 0
  -- roll [-1024,1024] ==> [-180,180]
  rollCh = getValue("ch1") * 0.175
  -- pitch [1024,-1024] ==> [-90,90]
  pitchCh = getValue("ch2") * 0.0878
  -- yaw [-1024,1024] ==> [0,360]
  yawCh = getValue("ch10")
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  roll = rollCh/3
  pitch = pitchCh/2
  yaw = yawCh
#endif --DEMO
end

local function symHome()
  local yawCh = 0
  local S2Ch = 0
  -- home angle in deg [0-360]
  S2Ch = getValue("ch12")
  yawCh = getValue("ch4")
#ifdef DEMO
  minmaxValues[MINMAX_ALT] = 45
  minmaxValues[MAX_VSPEED] = 4
  minmaxValues[MAX_HSPEED] = 77
  homeAlt = 24
  vSpeed = 2
  hSpeed = 34
#else --DEMO
  homeAlt = yawCh * 0.1
  vSpeed = yawCh * 0.1 * -1
  hSpeed = vSpeed
#endif --DEMO  
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  yaw = yawCh
  if ( S2Ch >= 0) then
    S2Ch = S2Ch * 0.175
  else
    S2Ch = 360 + (S2Ch * 0.175)
  end
  if (thrOut > 0 ) then
    homeAngle = S2Ch
  else
    homeAngle = -1
  end
end

local function symMode()
  symGPS()
  symAttitude()
  symTimer()
  symHome()
  symBatt()
  symFrameType()
end
#endif --TESTMODE

-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
#ifdef TELERATE
local telecounter = 0
local telerate = 0
local telestart = 0
#endif --TELERATE
--
local function processTelemetry()
  SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
  if ( FRAME_ID == 0x10) then
#ifdef LOGTELEMETRY
    -- log all but pitch and roll
    if DATA_ID ~= 0x5006 then
      logTelemetryToFile(SENSOR_ID,FRAME_ID,DATA_ID,VALUE)
    end
#endif --LOGTELEMETRY
#ifdef TELERATE
    ------------------------
    -- CALC ACTUAL TELE RATE
    ------------------------
    local now = getTime()/100
    if telecounter == 0 then
      telestart = now
    else
      telerate = telecounter / (now - telestart)
    end
    --
    telecounter=telecounter+1
#endif --TELERATE
    noTelemetryData = 0
    if ( DATA_ID == 0x5006) then -- ROLLPITCH
      -- roll [0,1800] ==> [-180,180]
      roll = (bit32.extract(VALUE,0,11) - 900) * 0.2
      -- pitch [0,900] ==> [-90,90]
      pitch = (bit32.extract(VALUE,11,10) - 450) * 0.2
    elseif ( DATA_ID == 0x5005) then -- VELANDYAW
      vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1))
      if (bit32.extract(VALUE,8,1) == 1) then
        vSpeed = -vSpeed
      end
      hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      yaw = bit32.extract(VALUE,17,11) * 0.2
    elseif ( DATA_ID == 0x5001) then -- AP STATUS
      flightMode = bit32.extract(VALUE,0,5)
      simpleMode = bit32.extract(VALUE,5,2)
      landComplete = bit32.extract(VALUE,7,1)
      statusArmed = bit32.extract(VALUE,8,1)
      battFailsafe = bit32.extract(VALUE,9,1)
      ekfFailsafe = bit32.extract(VALUE,10,2)
    elseif ( DATA_ID == 0x5002) then -- GPS STATUS
      numSats = bit32.extract(VALUE,0,4)
      -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
      -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
      gpsStatus = bit32.extract(VALUE,4,2) + bit32.extract(VALUE,14,2)
      gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
      gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) -- dm
      if (bit32.extract(VALUE,31,1) == 1) then
        gpsAlt = gpsAlt * -1
      end
    elseif ( DATA_ID == 0x5003) then -- BATT
      batt1volt = bit32.extract(VALUE,0,9)
      batt1current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt1mah = bit32.extract(VALUE,17,15)
#ifdef BATT2TEST
      batt2volt = bit32.extract(VALUE,0,9)
      batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt2mah = bit32.extract(VALUE,17,15)
#endif --BATT2TEST
    elseif ( DATA_ID == 0x5008) then -- BATT2
      batt2volt = bit32.extract(VALUE,0,9)
      batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt2mah = bit32.extract(VALUE,17,15)
    elseif ( DATA_ID == 0x5004) then -- HOME
      homeDist = bit32.extract(VALUE,2,10) * (10^bit32.extract(VALUE,0,2))
      homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1
      if (bit32.extract(VALUE,24,1) == 1) then
        homeAlt = homeAlt * -1
      end
      homeAngle = bit32.extract(VALUE, 25,  7) * 3
    elseif ( DATA_ID == 0x5000) then -- MESSAGES
      if (VALUE ~= lastMsgValue) then
        lastMsgValue = VALUE
        c1 = bit32.extract(VALUE,0,7)
        c2 = bit32.extract(VALUE,8,7)
        c3 = bit32.extract(VALUE,16,7)
        c4 = bit32.extract(VALUE,24,7)
        msgBuffer = msgBuffer .. string.char(c4)
        msgBuffer = msgBuffer .. string.char(c3)
        msgBuffer = msgBuffer .. string.char(c2)
        msgBuffer = msgBuffer .. string.char(c1)
        if (c1 == 0 or c2 == 0 or c3 == 0 or c4 == 0) then
          local severity = (bit32.extract(VALUE,15,1) * 4) + (bit32.extract(VALUE,23,1) * 2) + (bit32.extract(VALUE,30,1) * 1)
          pushMessage( severity, msgBuffer)
#ifdef LOGTELEMETRY    
          logMessageToFile(string.format("[%s] %s",mavSeverity[severity],msgBuffer))
#endif --LOGTELEMETRY
          msgBuffer = ""
        end
    end
    elseif ( DATA_ID == 0x5007) then -- PARAMS
      paramId = bit32.extract(VALUE,24,4)
      paramValue = bit32.extract(VALUE,0,24)
      if paramId == 1 then
        frameType = paramValue
      elseif paramId == 2 then
        battFailsafeVoltage = paramValue
      elseif paramId == 3 then
        battFailsafeCapacity = paramValue
      elseif paramId == 4 then
        batt1Capacity = paramValue
#ifdef BATT2TEST
        batt2Capacity = paramValue
#endif --BATT2TEST
      elseif paramId == 5 then
        batt2Capacity = paramValue
      end
    end
  end
end

#ifdef TESTMODE
local function telemetryEnabled()
  return true
end
#else --TESTMODE
local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end
#endif --TESTMODE

#ifdef MINMAX
local function getMinValue(value,idx)
  if showMinMaxValues == true then
    return minmaxValues[idx]
  end
  return value
end

local function getMaxValue(value,idx)
  minmaxValues[idx] = math.max(value,minmaxValues[idx])
  if showMinMaxValues == true then
    return minmaxValues[idx]
  end
  return value
end

local function calcMinValue(value,min)
  if min == 0 then
    return value
  else
    return math.min(value,min)
  end
end
#endif --MINMAX

-- returns the actual minimun only if both are > 0
local function calcCellMin(v1,v2)
  if v1 == 0 then
    return v2
  elseif v2 == 0 then
    return v1
  else
    return math.min(v1,v2)
  end
end

local function calcCellCount(battmax)
  -- cellcount is cached
  if cellcount > 1 then
    return cellcount
  end
  local count = 0
  if battmax*0.1 > 21.75 then
    -- battmax > 4.35 * 5 ==> 6s (lowest allowed cell on boot 3.625)
    count = 6
  elseif battmax*0.1 > 17.4 then
    -- battmax > 4.35 * 4 ==> 5s (lowest allowed cell on boot 3.48)
    count = 5
  elseif battmax*0.1 > 13.05 then
    -- battmax > 4.35 * 3 ==> 4s (lowest allowed cell on boot 3.27)
    count = 4
  elseif battmax*0.1 > 8.7 then
    -- battmax > 4.35 * 2 ==> 3s (lowest allowed cell on boot 2.9)
    count = 3
  else
    count = 2
  end
  return count
end

#ifdef DEV
local function calcCellValue(cellsum)
  local cellcount = 0
  if cellsum > 21 then
    cellcount = 6
  elseif cellsum > 17 then
    cellcount = 5
  elseif cellsum > 13 then
    cellcount = 4
  else
    cellcount = 3
  end
  return cellsum/cellcount
end
#endif --DEV

local function calcBattery()
  local battA2 = 0
  local cell = {0, 0, 0, 0, 0 ,0}
  ------------
  -- FLVSS 1
  ------------
  local cellResult = getValue("Cels")
  if type(cellResult) == "table" then
    cell1min = CELLFULL
    cell1sum = 0
    -- cellcount is global and shared
    cellcount = #cellResult
    for i, v in pairs(cellResult) do
      cell1sum = cell1sum + v
      if cell1min > v then
        cell1min = v
      end
    end
    -- if connected after scritp started
    if batt1sources.vs == false then
      battsource = "na"
    end
    if battsource == "na" then
      battsource = "vs"
    end
    batt1sources.vs = true
  else
    batt1sources.vs = false
    cell1min = 0
    cell1sum = 0
  end
  ------------
  -- FLVSS 2
  ------------
#ifdef BATT2TEST
  cellResult = getValue("Cels")
#else --BATT2TEST
  cellResult = getValue("Cel2")
#endif --BATT2TEST
  if type(cellResult) == "table" then
    cell2min = CELLFULL
    cell2sum = 0
    for i = 1, #cell do cell[i] = 0 end
    -- cellcount is global and shared
    cellcount = #cellResult
    for i, v in pairs(cellResult) do
      cell2sum = cell2sum + v
      if cell2min > v then
        cell2min = v
      end
    end
    -- if connected after scritp started
    if batt2sources.vs == false then
      battsource = "na"
    end
    if battsource == "na" then
      battsource = "vs"
    end
    batt2sources.vs = true
  else
    batt2sources.vs = false
    cell2min = 0
    cell2sum = 0
  end
  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if batt1volt > 0 then
    cell1sumFC = batt1volt*0.1
    cell1maxFC = math.max(batt1volt,cell1maxFC)
    cell1minFC = cell1sumFC/calcCellCount(cell1maxFC)
    if battsource == "na" then
      battsource = "fc"
    end
    batt1sources.fc = true
  else
    batt1sources.fc = false
    cell1minFC = 0
    cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if batt2volt > 0 then
    cell2sumFC = batt2volt*0.1
    cell2maxFC = math.max(batt2volt,cell2maxFC)
    cell2minFC = cell2sumFC/calcCellCount(cell2maxFC)
    if battsource == "na" then
      battsource = "fc"
    end
    batt2sources.fc = true
  else
    batt2sources.fc = false
    cell2minFC = 0
    cell2sumFC = 0
  end
  ----------------------------------
  -- A2 analog voltage only 1 supported
  ----------------------------------
  battA2 = getValue("A2")
  --
  if battA2 > 0 then
    cellsumA2 = battA2
    cellmaxA2 = math.max(battA2*10,cellmaxA2)
    cellminA2 = cellsumA2/calcCellCount(cellmaxA2)
    batt1sources.a2 = true
    if battsource == "na" then
      battsource = "a2"
    end
  else
    batt1sources.a2 = false
    cellminA2 = 0
    cellsumA2 = 0
  end
#ifdef MINMAX
  -- cell fc
  minmaxValues[MIN_CELL_FC] = calcMinValue(calcCellMin(cell1minFC,cell2minFC)*100,minmaxValues[MIN_CELL_FC])
  minmaxValues[MIN_CELL1_FC] = calcMinValue(cell1minFC*100,minmaxValues[MIN_CELL1_FC])
  minmaxValues[MIN_CELL2_FC] = calcMinValue(cell2minFC*100,minmaxValues[MIN_CELL2_FC])
  -- cell flvss
  minmaxValues[MIN_CELL_VS] = calcMinValue(calcCellMin(cell1min,cell2min)*100,minmaxValues[MIN_CELL_VS])
  minmaxValues[MIN_CELL1_VS] = calcMinValue(cell1min*100,minmaxValues[MIN_CELL1_VS])
  minmaxValues[MIN_CELL2_VS] = calcMinValue(cell2min*100,minmaxValues[MIN_CELL2_VS])
  -- cell A2
  minmaxValues[MIN_CELL_A2] = calcMinValue(cellminA2*100,minmaxValues[MIN_CELL_A2])
  minmaxValues[MIN_CELL1_A2] = minmaxValues[MIN_CELL_A2]
  minmaxValues[MIN_CELL2_A2] = 0
  -- batt fc
  minmaxValues[MIN_BATT_FC] = calcMinValue(calcCellMin(cell1sumFC,cell2sumFC)*10,minmaxValues[MIN_BATT_FC])
  minmaxValues[MIN_BATT1_FC] = calcMinValue(cell1sumFC*10,minmaxValues[MIN_BATT1_FC])
  minmaxValues[MIN_BATT2_FC] = calcMinValue(cell2sumFC*10,minmaxValues[MIN_BATT2_FC])
  -- batt flvss
  minmaxValues[MIN_BATT_VS] = calcMinValue(calcCellMin(cell1sum,cell2sum)*10,minmaxValues[MIN_BATT_VS])
  minmaxValues[MIN_BATT1_VS] = calcMinValue(cell1sum*10,minmaxValues[MIN_BATT1_VS])
  minmaxValues[MIN_BATT2_VS] = calcMinValue(cell2sum*10,minmaxValues[MIN_BATT2_VS])
  -- batt A2
  minmaxValues[MIN_BATT_A2] = calcMinValue(cellsumA2*10,minmaxValues[MIN_BATT_A2])
  minmaxValues[MIN_BATT1_A2] = minmaxValues[MIN_BATT_A2]
  minmaxValues[MIN_BATT2_A2] = 0
#endif --MINMAX
end

local function checkLandingStatus()
  if ( timerRunning == 0 and landComplete == 1 and lastTimerStart == 0) then
    startTimer()
  end
  if (timerRunning == 1 and landComplete == 0 and lastTimerStart ~= 0) then
    stopTimer()
    playSound("landing")
  end
  timerRunning = landComplete
end

local function calcFlightTime()
  local elapsed = 0
  if ( lastTimerStart ~= 0) then
    elapsed = getTime()/100 - lastTimerStart
  end
  flightTime = elapsed + seconds
end

local function getBatt1Capacity()
  if conf.battCapOverride1 > 0 then
    return conf.battCapOverride1*100
  else
    return batt1Capacity
  end
end

local function getBatt2Capacity()
  if conf.battCapOverride2 > 0 then
    return conf.battCapOverride2*100
  else
    return batt2Capacity
  end
end

local function getVoltageBySource(battsource,cell,cellFC,cellA2)
  if battsource == "vs" then
    return cell
  elseif battsource == "fc" then
    return cellFC
  elseif battsource == "a2" then
    return cellA2
  end
  return 0
end

#ifdef ALARMS

#define ALARMS_MIN_ALT 1
#define ALARMS_MAX_ALT 2
#define ALARMS_MAX_DIST 3
#define ALARMS_EKF 4
#define ALARMS_BATT 5
#define ALARMS_TIMER 6
#define ALARMS_BATT1 7
#define ALARMS_BATT2 8

#define ALARM_TYPE_MIN 0
#define ALARM_TYPE_MAX 1
#define ALARM_TYPE_TIMER 2
#define ALARM_TYPE_BATT 3
--[[
  min alarms need to be armed, i.e since values start at 0 in order to avoid
  immediate triggering upon start, the value must first reach the treshold
  only then will it trigger the alarm
]]--
local alarms = {
  --{ triggered, time, armed, type(0=min,1=max,2=timer,3=batt),  }  
    { false, 0 , false, ALARM_TYPE_MIN},
    { false, 0 , true, ALARM_TYPE_MAX },
    { false, 0 , true, ALARM_TYPE_MAX },
    { false, 0 , true, ALARM_TYPE_MAX },
    { false, 0 , true, ALARM_TYPE_MAX },
    { false, 0 , true, ALARM_TYPE_TIMER },
    { false, 0 , true, ALARM_TYPE_BATT },
    { false, 0 , true, ALARM_TYPE_BATT },
}

local function checkCellVoltage(battsource,cellmin,cellminFC,cellminA2)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  -- trigger batt1 and batt2
  if celm > conf.battAlertLevel2 and celm < conf.battAlertLevel1 and alarms[ALARMS_BATT1][1] == false then
    alarms[ALARMS_BATT1][1] = true
    playSound("batalert1")
  end
  if celm > 320 and celm < conf.battAlertLevel2 and alarms[ALARMS_BATT2][1] == false then
    alarms[ALARMS_BATT2][1] = true
    playSound("batalert2")
  end
#ifdef RESETBATTALARMS
  -- reset alarms when voltage rises
  if celm > conf.battAlertLevel1 then
    alarms[ALARMS_BATT1][1] = false
  elseif celm > conf.battAlertLevel2 then
    alarms[ALARMS_BATT2][1] = false
  end
#endif --RESETBATTALARMS
end

#endif --ALARMS

#ifdef SENSORS
local function setSensorValues()
  if (not telemetryEnabled()) then
    return
  end
  local battmah = batt1mah
  local battcapacity = getBatt1Capacity()
  if batt2mah > 0 then
    battcapacity =  getBatt1Capacity() + getBatt2Capacity()
    battmah = batt1mah + batt2mah
  end
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end  
  end
  setTelemetryValue(Fuel_ID, Fuel_SUBID, Fuel_INSTANCE, perc, 13 , Fuel_PRECISION , Fuel_NAME)
  setTelemetryValue(VFAS_ID, VFAS_SUBID, VFAS_INSTANCE, calcCellMin(batt1volt,batt2volt)*10, 1 , VFAS_PRECISION , VFAS_NAME)
  setTelemetryValue(CURR_ID, CURR_SUBID, CURR_INSTANCE, batt1current+batt2current, 2 , CURR_PRECISION , CURR_NAME)
  setTelemetryValue(VSpd_ID, VSpd_SUBID, VSpd_INSTANCE, vSpeed, 5 , VSpd_PRECISION , VSpd_NAME)
  setTelemetryValue(GSpd_ID, GSpd_SUBID, GSpd_INSTANCE, hSpeed*0.1, 4 , GSpd_PRECISION , GSpd_NAME)
  setTelemetryValue(Alt_ID, Alt_SUBID, Alt_INSTANCE, homeAlt*10, 9 , Alt_PRECISION , Alt_NAME)
  setTelemetryValue(GAlt_ID, GAlt_SUBID, GAlt_INSTANCE, math.floor(gpsAlt*0.1), 9 , GAlt_PRECISION , GAlt_NAME)
  setTelemetryValue(Hdg_ID, Hdg_SUBID, Hdg_INSTANCE, math.floor(yaw), 20 , Hdg_PRECISION , Hdg_NAME)
  setTelemetryValue(Tmp1_ID, Tmp1_SUBID, Tmp1_INSTANCE, flightMode, 11 , Tmp1_PRECISION , Tmp1_NAME)
  setTelemetryValue(Tmp2_ID, Tmp2_SUBID, Tmp2_INSTANCE, numSats*10+gpsStatus, 11 , Tmp2_PRECISION , Tmp2_NAME)
end
#endif --SENSORS

#ifdef ALERTS

#define ALERTS_LABEL 1
#define ALERTS_TIME 2
#define ALERTS_ICON 3
#define ALERTS_ICONX 4
#define ALERTS_ICONY 5
#define ALERTS_ACK 6
#define ALERTS_FTIME 7
#define ALERTS_VALUE 8
#define ALERTS_UNIT 9
#define ALERTS_FLAGS 10
#define ALERTS_MULTIPLE 11  
  
-- text,time,icon,xIcon,yIcon,ack,ftime,value,unit,prec,multiple
local alerts = {
  {"BATT FAILSAFE", 0, "BF", 0, 0,false,  0,  0,    "V",  PREC2,  false },
  {"EKF FAILSAFE",  0, "EF", 12,0,false,  0,  nil,  nil,  nil,    false },
  {"BATT LEVEL 1",  0, "V1", 24,0,false,  0,  0,    "V",  PREC2,  false },
  {"BATT LEVEL 2",  0, "V2", 36,0,false,  0,  0,    "V",  PREC2,  false },
  {"TIMER ALERT",   0, nil,   0,0,false,  0,  nil,  nil,  nil,    true }
}
 
#ifdef X9
#define ALERT_X 61
#define ALERT_Y 16
#define ALERT_WIDTH 90
#define ALERT_HEIGHT 30
#define ALERTICON_X 84
#define ALERTICON_Y 48
#endif --X9

#ifdef X7
#define ALERT_X 19
#define ALERT_Y 16
#define ALERT_WIDTH 90
#define ALERT_HEIGHT 30
#define ALERTICON_X 9
#define ALERTICON_Y 48
#endif --X7

#define BATTFAILSAFE 1
#define EKFFAILSAFE 2
#define BATTLEVEL1 3
#define BATTLEVEL2 4
#define TIMERALERT 5
#define ALTITUDEALERT 6

#define AUTOACK_SECS 10
#define ALERT_INIT_DELAY 5
--
local currentAlertIdx = 0
--
local function drawAlerts()
  -- search for latest non acked alert and draw acked
  if (not telemetryEnabled()) then
    return
  end
  local lastAlertIdx = 0
  local lastAlertTime = 0
  for a=1,#alerts do
    -- if alerts are acked and an icon is defined then draw an icon on the hud
    if alerts[a][ALERTS_ACK] == true and alerts[a][ALERTS_ICON] ~= nil then
      -- draw alert icon
#ifdef X7
      -- alert icons must be hidden when hud is not visible
      if showDualBattery == false then
        lcd.drawText(ALERTICON_X+alerts[a][ALERTS_ICONX],ALERTICON_Y+alerts[a][ALERTS_ICONY],alerts[a][ALERTS_ICON],SMLSIZE+INVERS)
      end
#endif --X7
#ifdef X9
      lcd.drawText(ALERTICON_X+alerts[a][ALERTS_ICONX],ALERTICON_Y+alerts[a][ALERTS_ICONY],alerts[a][ALERTS_ICON],SMLSIZE+INVERS)
#endif --X9
    elseif alerts[a][ALERTS_ACK] == false and alerts[a][ALERTS_TIME] > lastAlertTime then
      -- else display the latest alert event
      lastAlertTime = alerts[a][ALERTS_TIME]
      lastAlertIdx = a
    end
  end
  currentAlertIdx = lastAlertIdx
  if lastAlertIdx > 0 then
    -- if auto ack is enabled clear the alert after 10secs, good for FPV
    if menuItems[AA][6][menuItems[AA][4]] == true and (getTime() - alerts[lastAlertIdx][ALERTS_TIME])/100 > AUTOACK_SECS then
      -- for recurring alerts clear all to allow for re-trigger
      if alerts[lastAlertIdx][ALERTS_MULTIPLE] == true then
        alerts[lastAlertIdx][ALERTS_ACK] = false
        alerts[lastAlertIdx][ALERTS_FTIME] = 0
        alerts[lastAlertIdx][ALERTS_TIME] = 0
      else
        -- for one shot alerts simply ack'em
        alerts[lastAlertIdx][ALERTS_ACK] = true
      end
    else
      lcd.drawFilledRectangle(ALERT_X,ALERT_Y,ALERT_WIDTH,ALERT_HEIGHT,ERASE)
      lcd.drawRectangle(ALERT_X,ALERT_Y,ALERT_WIDTH,ALERT_HEIGHT,SOLID)
      -- title
      lcd.drawText(ALERT_X+0.4*(ALERT_WIDTH-4*string.len(alerts[lastAlertIdx][ALERTS_LABEL])),ALERT_Y+3,alerts[lastAlertIdx][ALERTS_LABEL],SMLSIZE+BLINK+INVERS)
      if alerts[lastAlertIdx][ALERTS_VALUE] ~= nil then
        -- alert time
        lcd.drawTimer(ALERT_X+5, ALERT_Y+16, alerts[lastAlertIdx][ALERTS_FTIME], MIDSIZE)
        -- alert value
        lcd.drawNumber(ALERT_X+58, ALERT_Y+16, alerts[lastAlertIdx][ALERTS_VALUE], MIDSIZE+alerts[lastAlertIdx][ALERTS_FLAGS])
        lcd.drawText(lcd.getLastRightPos(), ALERT_Y+16, alerts[lastAlertIdx][ALERTS_UNIT], SMLSIZE)
      else
        -- alert time
        lcd.drawTimer(ALERT_X+30, ALERT_Y+16, alerts[lastAlertIdx][ALERTS_FTIME], MIDSIZE)
      end
    end
  end
end

local function ackAlert()
  if currentAlertIdx > 0 then
    -- for recurring alerts clear all to allow for re-trigger
    if alerts[currentAlertIdx][ALERTS_MULTIPLE] == true then
      alerts[currentAlertIdx][ALERTS_ACK] = false
      alerts[currentAlertIdx][ALERTS_FTIME] = 0
      alerts[currentAlertIdx][ALERTS_TIME] = 0
    else
      -- for one shot alerts simply ack'em
      alerts[currentAlertIdx][6] = true
    end
  end
end

local function checkCellVoltage(battsource,cellmin,cellminFC,cellminA2)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  if celm > conf.battAlertLevel2 and celm < conf.battAlertLevel1 and alerts[BATTLEVEL1][ALERTS_ACK] == false and alerts[BATTLEVEL1][ALERTS_TIME] == 0 then
    alerts[BATTLEVEL1][ALERTS_TIME]=getTime()
    alerts[BATTLEVEL1][ALERTS_FTIME]=flightTime
    alerts[BATTLEVEL1][ALERTS_VALUE]=celm
    playSound("batalert1")
  end
  if celm > 320 and celm < conf.battAlertLevel2 and alerts[BATTLEVEL2][ALERTS_ACK] == false and alerts[BATTLEVEL2][ALERTS_TIME] == 0 then
    alerts[BATTLEVEL2][ALERTS_TIME]=getTime()
    alerts[BATTLEVEL2][ALERTS_FTIME]=flightTime
    alerts[BATTLEVEL2][ALERTS_VALUE]=celm
    playSound("batalert2")
  end
end
#endif --ALERTS

---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawBatteryPane(x,battsource,battcurrent,battcapacity,battmah,cellmin,cellminFC,cellminA2,cellsum,cellsumFC,cellsumA2,cellIdx,lipoIdx,currIdx)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  local lipo = getVoltageBySource(battsource,cellsum,cellsumFC,cellsumA2)*10
#ifdef MINMAX
  celm = getMinValue(celm,cellIdx + minmaxOffsets[battsource])
  lipo = getMinValue(lipo,lipoIdx + minmaxOffsets[battsource])
#endif --MINMAX
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
#ifdef MINMAX
  if showMinMaxValues == false then
#endif --MINMAX
#ifdef ALARMS
    if alarms[ALARMS_BATT2][1] == true then
      flags = BLINK
      dimFlags = BLINK
    elseif alarms[ALARMS_BATT1][1] == true then
      dimFlags = BLINK+INVERS
    end
#else
    if celm < conf.battAlertLevel2 then
      flags = BLINK
      dimFlags = BLINK
    elseif celm < conf.battAlertLevel1 then
      dimFlags = BLINK+INVERS
    end
#endif --ALARMS
#ifdef MINMAX
  end
#endif --MINMAX
  drawNumberWithTwoDims(x+BATTCELL_X, BATTCELL_Y, BATTCELL_YV, BATTCELL_YS,celm,"V",battsource,BATTCELL_FLAGS+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(x+BATTVOLT_X,BATTVOLT_Y,BATTVOLT_YV, lipo,"V",BATTVOLT_FLAGS,BATTVOLT_FLAGSV)
  -- battery current
#ifdef MINMAX
  battcurrent = getMaxValue(battcurrent,currIdx)
#endif --MINMAX
  drawNumberWithDim(x+BATTCURR_X,BATTCURR_Y,BATTCURR_YA,battcurrent,"A",BATTCURR_FLAGS,BATTCURR_FLAGSA)
  -- battery percentage
  lcd.drawNumber(x+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
#ifdef X9
  -- display capacity bar %
  lcd.drawFilledRectangle(x+BATTGAUGE_X, BATTGAUGE_Y, 2 + math.floor(perc * 0.01 * (BATTGAUGE_WIDTH - 3)), BATTGAUGE_HEIGHT, SOLID)
  lcd.drawRectangle(x+BATTGAUGE_X, BATTGAUGE_Y, 2 + math.floor(perc * 0.01 * (BATTGAUGE_WIDTH - 3)), BATTGAUGE_HEIGHT, SOLID)
  local step = BATTGAUGE_WIDTH/BATTGAUGE_STEPS
  for s=1,BATTGAUGE_STEPS - 1 do
    lcd.drawLine(x+BATTGAUGE_X + s*step - 1,BATTGAUGE_Y, x+BATTGAUGE_X + s*step - 1, BATTGAUGE_Y + BATTGAUGE_HEIGHT - 1,SOLID,0)
  end
#endif --X9
  -- battery mah
#ifdef X7
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y, "Ah", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y, battmah/100, BATTMAH_FLAGS+RIGHT)
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y+8, "Ah", SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y+8, battcapacity/100, BATTMAH_FLAGS+RIGHT+INVERS)
#endif --X7
#ifdef X9
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y, battmah/100, BATTMAH_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "/", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), BATTMAH_Y, battcapacity/100, BATTMAH_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "Ah", SMLSIZE)
#endif --X9
#ifdef X7
  -- tx voltage
  lcd.drawText(TXVOLTAGE_X, TXVOLTAGE_Y, "Tx", TXVOLTAGE_FLAGS)
  lcd.drawNumber(lcd.getLastRightPos(), TXVOLTAGE_Y, getValue(getFieldInfo("tx-voltage").id)*10, TXVOLTAGE_FLAGS+PREC1)
  lcd.drawText(lcd.getLastRightPos(), TXVOLTAGE_Y, "v", TXVOLTAGE_FLAGS)
#endif --X7
#ifdef MINMAX
#ifdef X9
  if showMinMaxValues == true then
    drawVArrow(x+BATTVOLT_X+27,BATTVOLT_Y + 7, 5,false,true)
    drawVArrow(x+BATTCURR_X+27,BATTCURR_Y + 6,5,true,false)
    drawVArrow(x+BATTCELL_X+37, BATTCELL_Y + 3,6,false,true)
  end
#endif --X9
#ifdef X7
  if showMinMaxValues == true then
    drawVArrow(x+BATTCELL_X+36, BATTCELL_Y+2,6,false,true)
  end
#endif --X7
#endif --MINMAX
end
#ifdef X7
---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawX7BatteryLeftPane(battsource,battcurrent,battcapacity,battmah,cellmin,cellminFC,cellminA2,cellsum,cellsumFC,cellsumA2,cellIdx,lipoIdx,currIdx)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  local lipo = getVoltageBySource(battsource,cellsum,cellsumFC,cellsumA2)*10
#ifdef MINMAX
  celm = getMinValue(celm,cellIdx + minmaxOffsets[battsource])
  lipo = getMinValue(lipo,lipoIdx + minmaxOffsets[battsource])
#endif --MINMAX
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
  else
    perc = 0
  end
  if perc > 99 then
    perc = 99
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
#ifdef MINMAX
  if showMinMaxValues == false then
#endif --MINMAX
    if celm < conf.battAlertLevel2 then
      flags = BLINK
      dimFlags = BLINK
    elseif celm < conf.battAlertLevel1 then
      dimFlags = BLINK+INVERS
    end  
#ifdef MINMAX
  end
#endif --MINMAX
  drawNumberWithTwoDims(0, BATTCELL_Y, BATTCELL_YV, BATTCELL_YS,celm,"V",battsource,BATTCELL_FLAGS+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(41+BATTVOLT_X,BATTVOLT_Y,BATTVOLT_YV, lipo,"V",BATTVOLT_FLAGS,BATTVOLT_FLAGSV)
  -- battery current
#ifdef MINMAX
  battcurrent = getMinValue(battcurrent,currIdx)
#endif --MINMAX
  drawNumberWithDim(41+BATTCURR_X,BATTCURR_Y,BATTCURR_YA,battcurrent,"A",BATTCURR_FLAGS,BATTCURR_FLAGSA)
  -- battery percentage
  lcd.drawNumber(17+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- box
  lcd.drawRectangle(0,BATTMAH_Y + 7,6,7,SOLID)
  lcd.drawFilledRectangle(0,BATTMAH_Y + 7,6,7,SOLID)
  -- battery mah
  lcd.drawText(-35+BATTMAH_X, BATTMAH_Y, "Ah", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y, battmah/100, BATTMAH_FLAGS+RIGHT)
  lcd.drawText(-35+BATTMAH_X, BATTMAH_Y+8, "Ah", SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y+8, battcapacity/100, BATTMAH_FLAGS+RIGHT+INVERS)
#ifdef MINMAX
  if showMinMaxValues == true then
    drawVArrow(36, BATTCELL_Y+2,6,false,true)
  end
#endif --MINAMX
end
#endif --X7

local function drawNoTelemetryData()
  -- no telemetry data
#ifdef X9
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle((212-130)/2,18, 130, 30, SOLID)
    lcd.drawText(60, 29, "no telemetry data", INVERS)
    return
  end
#else
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle(12,18, 105, 30, SOLID)
    lcd.drawText(30, 29, "no telemetry", INVERS)
    return
  end
#endif --X9
end

#ifdef X9
local function getMessage(index)
  local msg = messages[index][3]
  if messages[index][4] > 1 then
    if #msg > 36 then
      msg = string.sub(msg,1,36)
    end
    return string.format("%02d:%s %s (x%d)", messages[index][1], mavSeverity[messages[index][2]], msg, messages[index][4])
  else
    if #msg > 40 then
      msg = string.sub(msg,1,40)
    end
    return string.format("%02d:%s %s", messages[index][1], mavSeverity[messages[index][2]], msg)
  end
end
#endif --X9
#ifdef X7
local function getMessage(index)
  local msg = messages[index][3]
  if messages[index][4] > 1 then
    if #msg > 16 then
      msg = string.sub(msg,1,16)
    end
    return string.format("%d:%s %s (x%d)", messages[index][1], mavSeverity[messages[index][2]], msg, messages[index][4])
  else
    if #msg > 23 then
      msg = string.sub(msg,1,23)
    end
    return string.format("%d:%s %s", messages[index][1], mavSeverity[messages[index][2]], msg)
  end
end
#endif --X7

local function drawTopBar()
  -- black bar
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawRectangle(0, TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  -- flight mode
  if frameTypes[frameType] ~= nil then
    local strMode = flightModes[frameTypes[frameType]][flightMode]
    if strMode ~= nil then
      lcd.drawText(FLIGHTMODE_X, FLIGHTMODE_Y, strMode, FLIGHTMODE_FLAGS)
      if ( simpleMode == 1) then
        lcd.drawText(lcd.getLastRightPos(), 1, "(S)", FLIGHTMODE_FLAGS)
      end
    end  
  end
  -- flight time
  lcd.drawText(FLIGHTTIME_X, FLIGHTTIME_Y, "T:", FLIGHTTIME_FLAGS)
  lcd.drawTimer(lcd.getLastRightPos(), FLIGHTTIME_Y, flightTime, FLIGHTTIME_FLAGS)
  -- RSSI
  lcd.drawText(RSSI_X, RSSI_Y, "RS:", RSSI_FLAGS)
#ifdef DEMO
  lcd.drawText(lcd.getLastRightPos(), RSSI_Y, 87, RSSI_FLAGS)  
#else --DEMO
  lcd.drawText(lcd.getLastRightPos(), RSSI_Y, getRSSI(), RSSI_FLAGS)  
#endif --DEMO
#ifdef X9
  -- tx voltage
  lcd.drawText(TXVOLTAGE_X, TXVOLTAGE_Y, "Tx", TXVOLTAGE_FLAGS)
  lcd.drawNumber(lcd.getLastRightPos(), TXVOLTAGE_Y, getValue(getFieldInfo("tx-voltage").id)*10, TXVOLTAGE_FLAGS+PREC1)
  lcd.drawText(lcd.getLastRightPos(), TXVOLTAGE_Y, "v", TXVOLTAGE_FLAGS)
#endif --X9
end

local function drawBottomBar()
  -- black bar
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  -- message text
  local now = getTime()
  local msg = getMessage(#messages)
#ifdef X9
  if (now - lastMsgTime ) > 150 or conf.disableMsgBlink then
    lcd.drawText(0, BOTTOMBAR_Y+1, msg,SMLSIZE+INVERS)
  else
    lcd.drawText(0, BOTTOMBAR_Y+1, msg,SMLSIZE+INVERS+BLINK)
  end
#endif --X9
#ifdef X7
  if (now - lastMsgTime ) > 150 or conf.disableMsgBlink then
    lcd.drawText(0, BOTTOMBAR_Y + 1,  msg,SMLSIZE+INVERS)
  else
    lcd.drawText(0, BOTTOMBAR_Y + 1,  msg,SMLSIZE+INVERS+BLINK)
  end
#endif --X7
end

#ifdef X7
local function drawHomeDist()
  drawHArrow(HOMEDIST_XLABEL,HOMEDIST_YLABEL + 2,HOMEDIST_ARROW_WIDTH,true,true)
  local flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
#ifdef MINMAX
  homeDist = getMaxValue(homeDist,MAX_DIST)
  if showMinMaxValues == true then
    flags = 0
  end
#endif --MINMAX
  lcd.drawNumber(HOMEDIST_X, HOMEDIST_Y, homeDist, HOMEDIST_FLAGS+flags)
  lcd.drawText(lcd.getLastRightPos(), HOMEDIST_Y, "m",HOMEDIST_FLAGS+flags)
#ifdef MINMAX
  if showMinMaxValues == true then
    drawVArrow(lcd.getLastRightPos() + 2, HOMEDIST_Y,6,true,false)
  end
#endif --MINMAX
end
#endif --X7

local function drawAllMessages()
  for i=1,#messages do
    lcd.drawText(1, 1 + 7*(i-1), getMessage(i),SMLSIZE)
  end
end

#ifdef X9
local function drawLeftPane(battcurrent,cellsumFC)
  -- gps status
  local strStatus = gpsStatuses[gpsStatus]
  local flags = BLINK
  local mult = 1
  if gpsStatus  > 2 then
    if homeAngle ~= -1 then
      flags = PREC1
    end
    if gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(GPS_X,GPS_Y + 2, strStatus, SMLSIZE)
    lcd.drawText(GPS_X,GPS_Y + 8, "fix", SMLSIZE)
    lcd.drawNumber(GPS_X + 34, GPS_Y + 2, numSats, MIDSIZE+RIGHT)
    lcd.drawText(GPS_X + 37, GPS_Y + 7 , "Hd", SMLSIZE)
    lcd.drawNumber(GPS_X + 66, GPS_Y + 2, gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(GPS_X + 34,GPS_Y+1,GPS_X+34,GPS_Y + 14,SOLID,FORCE)
  else
    lcd.drawText(GPS_X + 10, GPS_Y + 2, strStatus, MIDSIZE+INVERS+BLINK)
  end  
  lcd.drawLine(GPS_X ,GPS_Y + 15,GPS_X+66,GPS_Y + 15,SOLID,FORCE)
  -- alt asl
  flags = BLINK
  -- always display gps altitude even without 3d lock
  local alt = gpsAlt/10
  if gpsStatus  > 2 then
    flags = 0
#ifdef MINMAX
    -- update max only with 3d or better lock
    alt = getMaxValue(alt,MAX_GPSALT)
#endif --MINMAX
  end
#ifdef MINMAX
  if showMinMaxValues == true then
    flags = 0
  end
#endif --MINMAX
  lcd.drawText(ALTASL_XLABEL + 4, ALTASL_YLABEL, "Asl", SMLSIZE)
  drawVArrow(ALTASL_XLABEL,ALTASL_YLABEL - 1,7,true,true)
  lcd.drawNumber(ALTASL_X, ALTASL_Y-1, alt, SMLSIZE+flags)
  lcd.drawText(lcd.getLastRightPos(), ALTASL_Y-1 , "m", SMLSIZE+flags)
  -- home distance
  drawHomeIcon(HOMEDIST_XLABEL + 1,HOMEDIST_YLABEL,7)
  drawHArrow(HOMEDIST_XLABEL + 10,HOMEDIST_YLABEL + 2,HOMEDIST_ARROW_WIDTH,true,true)
  flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
#ifdef MINMAX
  homeDist = getMaxValue(homeDist,MAX_DIST)
  if showMinMaxValues == true then
    flags = 0
  end
#endif --MINMAX
  lcd.drawNumber(HOMEDIST_X, HOMEDIST_Y-1, homeDist, HOMEDIST_FLAGS+flags)
  lcd.drawText(lcd.getLastRightPos(), HOMEDIST_Y-1, "m",HOMEDIST_FLAGS+flags)
  -- hspeed
#ifdef MINMAX
  hSpeed = getMaxValue(hSpeed,MAX_HSPEED)
#endif  --MINMAX
  drawHArrow(HSPEED_XLABEL + 4,HSPEED_YLABEL,4,false,true)
  drawHArrow(HSPEED_XLABEL + 6,HSPEED_YLABEL + 4,5,false,true)
  lcd.drawPoint(HSPEED_XLABEL + 2,HSPEED_YLABEL)
  lcd.drawPoint(HSPEED_XLABEL,HSPEED_YLABEL)
  lcd.drawPoint(HSPEED_XLABEL + 4,HSPEED_YLABEL + 4)
  lcd.drawPoint(HSPEED_XLABEL + 2,HSPEED_YLABEL + 4)
  lcd.drawNumber(HSPEED_X - 10, HSPEED_Y - 1, hSpeed, HSPEED_FLAGS+RIGHT+PREC1)
  lcd.drawText(HSPEED_XDIM - 4, HSPEED_YDIM - 4, "m",HSPEED_FLAGS+RIGHT)
  lcd.drawText(HSPEED_XDIM + 1, HSPEED_YDIM, "s",HSPEED_FLAGS+RIGHT)
  lcd.drawLine(HSPEED_XDIM -6,HSPEED_YDIM + 3,HSPEED_XDIM -3,HSPEED_YDIM,SOLID,0)
  -- power box
  lcd.drawRectangle(BOX1_X,BOX1_Y,BOX1_WIDTH,BOX1_HEIGHT,FORCE)
  lcd.drawFilledRectangle(BOX1_X,BOX1_Y,BOX1_WIDTH,BOX1_HEIGHT,FORCE)
  lcd.drawLine(BOX1_X+BOX1_WIDTH/2,BOX1_Y,BOX1_X+BOX1_WIDTH/2,BOX1_Y+BOX1_HEIGHT - 1,SOLID,0)
  -- power
  local power = cellsumFC*battcurrent*0.1
#ifdef MINMAX  
  power = getMaxValue(power,MAX_POWER)
#endif --MINMAX
  drawNumberWithDim(BATTPOWER_X,BATTPOWER_Y,BATTPOWER_YW,power,"w",BATTPOWER_FLAGS,BATTPOWER_FLAGSW)
#ifdef MINMAX
  if showMinMaxValues == true then
    drawVArrow(BATTPOWER_X + 28, BATTPOWER_Y, 5,true,false)
    drawVArrow(HOMEDIST_X + 28, HOMEDIST_Y - 2,6,true,false)
    drawVArrow(HSPEED_XDIM + 2,HSPEED_Y - 2 ,6,true,false)
    drawVArrow(ALTASL_X + 26, ALTASL_Y - 2,6,true,false)
  end
#endif --MINMAX
end
#endif --X9

#ifdef X7
local function drawGPSStatus()
  local strStatus = gpsStatuses[gpsStatus]
  local flags = BLINK+PREC1
  local mult = 1
  if gpsStatus  > 2 then
    if homeAngle ~= -1 then
      flags = PREC1
    end
    if gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(GPS_X + 1,GPS_Y + 6, strStatus, SMLSIZE)
    lcd.drawNumber(GPS_X + 34, GPS_Y + 1, numSats, MIDSIZE+RIGHT)
    lcd.drawText(GPS_X + 39, GPS_Y + 6 , "H", SMLSIZE)
    lcd.drawNumber(lcd.getLastRightPos() + 1, GPS_Y + 1, gpsHdopC*mult , MIDSIZE+flags)
    lcd.drawLine(GPS_X + 34,GPS_Y+1,GPS_X+34,GPS_Y+12,SOLID,FORCE)
  else
    lcd.drawText(GPS_X + 9, GPS_Y+1, strStatus, MIDSIZE+INVERS+BLINK)
  end
  lcd.drawLine(GPS_X ,GPS_Y + 13,GPS_X+63,GPS_Y + 13,SOLID,FORCE)
end
#endif --X7

local function drawFailsafe()
#ifdef ALERTS
  if ekfFailsafe > 0 then
    if alerts[EKFFAILSAFE][ALERTS_ACK] == false and alerts[EKFFAILSAFE][ALERTS_TIME] == 0 then
      playSound("ekf")
      alerts[EKFFAILSAFE][ALERTS_FTIME] = flightTime
      alerts[EKFFAILSAFE][ALERTS_TIME] = getTime()
    end
  end
  if battFailsafe > 0 then
    if alerts[BATTFAILSAFE][ALERTS_ACK] == false  and alerts[BATTFAILSAFE][ALERTS_TIME] == 0 then
      playSound("lowbat")
      alerts[BATTFAILSAFE][ALERTS_FTIME] = flightTime
      alerts[BATTFAILSAFE][ALERTS_TIME] = getTime()
    end
  end
#else --ALERTS
  local xoffset = 0
  local yoffset = 0
#ifdef X7
  if showDualBattery == true and (ekfFailsafe > 0 or battFailsafe >0) then
    xoffset = 35
    yoffset = -15
    lcd.drawFilledRectangle(xoffset + 6, 36 + yoffset, 50, 21, ERASE)
    lcd.drawRectangle(xoffset + 6, 36 + yoffset, 50, 21, SOLID)
  end
#endif --X7
  if ekfFailsafe > 0 then
#ifndef ALARMS    
    if lastEkfFailsafe == 0 then
      playSound("ekf")
    end
#endif --ALARMS
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 6, 39 + yoffset, "EKF", SMLSIZE+INVERS+BLINK)
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 17, 48 + yoffset, "FAILSAFE", SMLSIZE+INVERS+BLINK)
  end
  if battFailsafe > 0 then
#ifndef ALARMS    
    if lastBattFailsafe == 0 then
      playSound("lowbat")
    end
#endif --ALARMS
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 8, 39 + yoffset, "BATT", SMLSIZE+INVERS+BLINK)
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 17, 48 + yoffset, "FAILSAFE", SMLSIZE+INVERS+BLINK)
  end
#endif --ALERTS
#ifndef ALARMS
  lastEkfFailsafe = ekfFailsafe
  lastBattFailsafe = battFailsafe
#endif --ALARMS
end

#define LEFTWIDTH   16
#define RIGHTWIDTH  17

local function drawPitch()
  local y = 0
  local p = pitch
  -- horizon min max +/- 30°
  if ( pitch > 0) then
    if (pitch > 30) then
      p = 30
    end
  else
    if (pitch < -30) then
      p = -30
    end
  end
  -- y normalized at 32 +/-20  (0.75 = 20/32)
  y = 32 + 0.75*p
  -- lets erase to hide the artificial horizon lines
  for ly=0,5 do
    lcd.drawLine(HUD_X,32 - ly,HUD_X + LEFTWIDTH + (5 - ly),32 - ly, SOLID, ERASE)
    lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1 - (5 - ly),32 - ly,HUD_X + HUD_WIDTH - 1,32 - ly,SOLID,ERASE)
  end
  for ly=1,4 do
    lcd.drawLine(HUD_X,32 + ly,HUD_X + LEFTWIDTH + (5 - ly),32 + ly, SOLID, ERASE)
    lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1 - (5 - ly),32 + ly,HUD_X + HUD_WIDTH - 1,32 + ly,SOLID,ERASE)
  end
  --
#ifdef MINMAX
    homeAlt = getMaxValue(homeAlt,MINMAX_ALT)
#endif --MINMAX
  if homeAlt > 0 then
    if homeAlt < 10 then -- 2 digits with decimal
      lcd.drawNumber(HUD_X + HUD_WIDTH,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
    else -- 3 digits
      lcd.drawNumber(HUD_X + HUD_WIDTH,32 - 3,homeAlt,SMLSIZE+RIGHT)
    end
  else
    if homeAlt > -10 then -- 1 digit with sign
      lcd.drawNumber(HUD_X + HUD_WIDTH,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
    else -- 3 digits with sign
      lcd.drawNumber(HUD_X + HUD_WIDTH,32 - 3,homeAlt,SMLSIZE+RIGHT)
    end
  end
  --
  if (vSpeed > 999) then
    lcd.drawNumber(HUD_X + 1,32 - 3,vSpeed*0.1,SMLSIZE)
  elseif (vSpeed < -99) then
    lcd.drawNumber(HUD_X + 1,32 - 3,vSpeed * 0.1,SMLSIZE)
  else
    lcd.drawNumber(HUD_X + 1,32 - 3,vSpeed,SMLSIZE+PREC1)
  end
  -- up pointing center arrow
  local arrowX = math.floor(HUD_X + HUD_WIDTH/2)
  lcd.drawLine(arrowX - 5,34 + 5,arrowX ,34 ,SOLID,FORCE)
  lcd.drawLine(arrowX,34 ,arrowX + 5, 34 + 5,SOLID,FORCE)
  -- vSpeed
  lcd.drawLine(HUD_X,32 - 5,HUD_X + LEFTWIDTH,32 - 5, SOLID, FORCE)
  lcd.drawLine(HUD_X,32 + 4,HUD_X + LEFTWIDTH,32 + 4, SOLID, FORCE)
  lcd.drawLine(HUD_X + LEFTWIDTH + 1,32 - 4,HUD_X + LEFTWIDTH + 5,32, SOLID,  FORCE)
  lcd.drawLine(HUD_X + LEFTWIDTH + 1,32 + 4,HUD_X + LEFTWIDTH + 4,33, SOLID,  FORCE)
  -- altitude
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1,32 - 5,HUD_X + HUD_WIDTH - 1,32 - 5,SOLID,FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1,32 + 4,HUD_X + HUD_WIDTH - 1,32 + 4,SOLID,FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 2,32 + 4,HUD_X + HUD_WIDTH - RIGHTWIDTH - 6,32, SOLID, FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 2,32 - 4,HUD_X + HUD_WIDTH - RIGHTWIDTH - 6,32, SOLID, FORCE)
    --
#ifdef MINMAX
  if showMinMaxValues == true then
    lcd.drawFilledRectangle(HUD_X + HUD_WIDTH - 26,32-5,7,10,ERASE)
    drawVArrow(HUD_X + HUD_WIDTH - 23, 32-4,6,true,false)
  end
#endif --MINMAX
end

-- vertical distance between roll horiz segments
#define R2 10
local function drawRoll()
  local r = -roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( roll == 0) then
    dx=0
    dy=pitch
    cx=0
    cy=R2
    ccx=0
    ccy=2*R2
    cccx=0
    cccy=3*R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -pitch
    dy = math.sin(math.rad(90 - r)) * pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * R2
    cy = math.sin(math.rad(90 - r)) * R2
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * R2
    ccy = math.sin(math.rad(90 - r)) * 2 * R2
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * R2
    cccy = math.sin(math.rad(90 - r)) * 3 * R2
  end
  local rollX = math.floor(HUD_X + HUD_WIDTH/2)
  --local delta = (HUD_WIDTH - 76)
  drawCroppedLine(rollX + dx - cccx,dy + 32 + cccy,r,5,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
  drawCroppedLine(rollX + dx - ccx,dy + 32 + ccy,r,7,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
  drawCroppedLine(rollX + dx - cx,dy + 32 + cy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
#ifdef X9
  drawCroppedLine(rollX + dx,dy + 32,r,54,SOLID,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
#endif --X9
#ifdef X7
  drawCroppedLine(rollX + dx,dy + 32,r,44,SOLID,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
#endif --X7
  drawCroppedLine(rollX + dx + cx,dy + 32 - cy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
  drawCroppedLine(rollX + dx + ccx,dy + 32 - ccy,r,7,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
  drawCroppedLine(rollX + dx + cccx,dy + 32 - cccy,r,5,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y)
end

local yawLabels = {
  {39,47,"NE"},
  {89,92,"E"},
  {129,132,"SE"},
  {179,182,"S"},
  {219,227,"SW"},
  {269,272,"W"},
  {309,317,"NW"},
  {359,2,"N"}
}
--
local function drawYaw()
  local hw = math.floor(HUD_WIDTH/2)
  local ww = hw - 6
  local degL = 0
  local degR = 0
  local steps = 9
  local yawRounded = roundTo(yaw,10)
  local homeRounded = roundTo(homeAngle,10)
  local minY = TOPBAR_Y + TOPBAR_HEIGHT
  --
  local cx = HUD_X + hw
  for step = 0,steps
  do
    --
    degR = (yawRounded + step*10) % 360
    degL = (yawRounded - step*10) % 360
    --
    for l=1,#yawLabels - 1 do
      if degR > yawLabels[l][1] and degR < yawLabels[l][2] then
        lcd.drawText(cx + step/steps*ww, minY+1, yawLabels[l][3], SMLSIZE)
      end
      if degL > yawLabels[l][1] and degL < yawLabels[l][2] then
        lcd.drawText(cx - step/steps*ww - 6, minY+1, yawLabels[l][3], SMLSIZE)
      end
    end
    
    if degR > yawLabels[#yawLabels][1] or degR < yawLabels[#yawLabels][2] then
      lcd.drawText(cx + step/steps*ww, minY+1, yawLabels[#yawLabels][3], SMLSIZE)
    end
    if degL > yawLabels[#yawLabels][1] or degL < yawLabels[#yawLabels][2] then
      lcd.drawText(cx - step/steps*ww - 6, minY+1, yawLabels[#yawLabels][3], SMLSIZE)
    end

    if degR > homeRounded - 5 and degR < homeRounded + 5 and degL > homeRounded - 5  and degL < homeRounded + 5  then
      drawHomeIcon(cx - 2,minY + 10)
    else
      if degR > homeRounded - 5 and degR < homeRounded + 5 then
        drawHomeIcon(cx + step/steps*ww ,minY + 10)
      end
      if degL > homeRounded - 5  and degL < homeRounded + 5 then
        drawHomeIcon(cx - step/steps*ww - 6,minY + 10)
      end
    end
  end

  lcd.drawLine(HUD_X, minY + 7, HUD_X + HUD_WIDTH - 1, minY + 7, SOLID, 0)
  local xx = 0
  if ( yaw < 10) then
    xx = 1
  elseif (yaw < 100) then
    xx = -2
  else
    xx = -5
  end
  lcd.drawRectangle(HUD_X + hw - 6, minY, 12,12, SOLID)
  lcd.drawFilledRectangle(HUD_X + hw - 6, minY, 12,12, SOLID)
  lcd.drawNumber(HUD_X + hw + xx - 4, minY, yaw, MIDSIZE+INVERS)
end

#ifdef DEV
local function clearHud()
  lcd.drawFilledRectangle(HUD_X,TOPBAR_Y + TOPBAR_HEIGHT + 8,HUD_WIDTH,49,ERASE,0)
end

local function clearLeftPane()
#ifdef X9
  lcd.drawFilledRectangle(0,TOPBAR_Y + TOPBAR_HEIGHT,HUD_X - 1,49,ERASE,0)
#endif --X9
end

local function clearRightPane()
#ifdef X7
  lcd.drawFilledRectangle(HUD_X+HUD_WIDTH,TOPBAR_Y + TOPBAR_HEIGHT,128 - HUD_X + HUD_WIDTH,49,ERASE,0)
#endif --X7
--
#ifdef X9
  lcd.drawFilledRectangle(HUD_X+HUD_WIDTH,TOPBAR_Y + TOPBAR_HEIGHT,212 - HUD_X + HUD_WIDTH,49,ERASE,0)
#endif --X9
end
#endif --DEV

local function drawHud()
  drawRoll()
  drawPitch()
  if ekfFailsafe == 0 and battFailsafe == 0 and timerRunning == 0 then
    if (statusArmed == 1) then
      lcd.drawText(HUD_X + HUD_WIDTH/2 - 12, 39, "ARMED", SMLSIZE+INVERS)
    else
      lcd.drawText(HUD_X + HUD_WIDTH/2 - 18, 39, "DISARMED", SMLSIZE+INVERS+BLINK)
    end
  end
end

local function drawGrid()
  lcd.drawLine(HUD_X - 1, 7 ,HUD_X - 1, 57, SOLID, 0)
  lcd.drawLine(HUD_X + HUD_WIDTH, 7, HUD_X + HUD_WIDTH, 57, SOLID, 0)
end

local function drawHomeDirection()
  local angle = math.floor(homeAngle - yaw)
#ifdef X9  
  lcd.drawFilledRectangle(HOMEDIR_X - HOMEDIR_R,HOMEDIR_Y - HOMEDIR_R,2*HOMEDIR_R,2*HOMEDIR_R,ERASE,0)
#endif --X9
  local x1 = HOMEDIR_X + HOMEDIR_R * math.cos(math.rad(angle - 90))
  local y1 = HOMEDIR_Y + HOMEDIR_R * math.sin(math.rad(angle - 90))
  local x2 = HOMEDIR_X + HOMEDIR_R * math.cos(math.rad(angle - 90 + 150))
  local y2 = HOMEDIR_Y + HOMEDIR_R * math.sin(math.rad(angle - 90 + 150))
  local x3 = HOMEDIR_X + HOMEDIR_R * math.cos(math.rad(angle - 90 - 150))
  local y3 = HOMEDIR_Y + HOMEDIR_R * math.sin(math.rad(angle - 90 - 150))
  local x4 = HOMEDIR_X + HOMEDIR_R * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = HOMEDIR_Y + HOMEDIR_R * 0.5 *math.sin(math.rad(angle - 270))
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,1)
  lcd.drawLine(x1,y1,x3,y3,SOLID,1)
  lcd.drawLine(x2,y2,x4,y4,SOLID,1)
  lcd.drawLine(x3,y3,x4,y4,SOLID,1)
end

#ifdef X7  
local function drawCustomBoxes()
  lcd.drawRectangle(BOX1_X,BOX1_Y,BOX1_WIDTH,BOX1_HEIGHT,SOLID)
  lcd.drawFilledRectangle(BOX1_X,BOX1_Y,BOX1_WIDTH,BOX1_HEIGHT,SOLID)
end
#endif --X7

---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms
  if timerRunning == 0 then
    if alarms[idx][4] == ALARM_TYPE_MIN then
      alarms[idx] = { false, 0, false, ALARM_TYPE_MIN} 
    elseif  alarms[idx][4] == ALARM_TYPE_MAX then
      alarms[idx] = { false, 0, true, ALARM_TYPE_MAX}
    else
      alarms[idx] = { false, 0, true, ALARM_TYPE_TIMER}
    end
  end
  -- for minimum type alarms, arm the alarm only after value has reached level  
  if alarms[idx][3] == false and timerRunning == 1 and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][3] = true
  end
  -- if alarm is armed and value is "outside" level
  if alarms[idx][3] == true and timerRunning == 1 and level > 0 and sign*value > sign*level then
    -- for timer alarms trigger when flighttime is a multiple of delay
    if alarms[idx][4] == ALARM_TYPE_TIMER then
      if math.floor(flightTime) %  delay == 0 then
        if alarms[idx][1] == false then 
          alarms[idx][1] = true
          playSound(sound)
        end
      else
          alarms[idx][1] = false
      end
    else
      -- fire once
      if alarms[idx][2] == 0 then
        alarms[idx][1] = true
        alarms[idx][2] = flightTime
        playSound(sound)
      end
      -- ...and then fire every conf secs after the first shot
      if math.floor(flightTime - alarms[idx][2]) %  delay == 0 then
        if alarms[idx][1] == false then 
          alarms[idx][1] = true
          playSound(sound)
        end
      else
          alarms[idx][1] = false
      end
    end
  elseif alarms[idx][3] == true then
    alarms[idx][2] = 0
  end
end

local function checkEvents()
#ifdef ALERTS
  if timerRunning == 1 and flightTime > 1 and math.floor(flightTime) % conf.timerAlert == 0 and alerts[TIMERALERT][ALERTS_ACK] == false and alerts[TIMERALERT][ALERTS_TIME] == 0 then
    alerts[TIMERALERT][ALERTS_TIME]=getTime()
    alerts[TIMERALERT][ALERTS_FTIME]=flightTime
    playSound("timealert")
  end
#endif --ALERTS
#ifdef ALARMS
  -- silence alarms when showing min/max values
  if showMinMaxValues == false then
    -- vocal fence alarms
    checkAlarm(conf.minAltitudeAlert,homeAlt,ALARMS_MIN_ALT,-1,"minalt",menuItems[T2][4])
    checkAlarm(conf.maxAltitudeAlert,homeAlt,ALARMS_MAX_ALT,1,"maxalt",menuItems[T2][4])  
    checkAlarm(conf.maxDistanceAlert,homeDist,ALARMS_MAX_DIST,1,"maxdist",menuItems[T2][4])  
    checkAlarm(1,2*ekfFailsafe,ALARMS_EKF,1,"ekf",menuItems[T2][4])  
    checkAlarm(1,2*battFailsafe,ALARMS_BATT,1,"lowbat",menuItems[T2][4])  
    checkAlarm(conf.timerAlert,flightTime,ALARMS_TIMER,1,"timealert",conf.timerAlert)
  end
#endif --ALARMS

  local capacity = getBatt1Capacity() + getBatt2Capacity()
  local mah = batt1mah + batt2mah
  if (capacity > 0) then
    batLevel = (1 - (mah/capacity))*100
  else
    batLevel = 99
  end

  if batLevel < (batLevels[lastBattLevel] + 1) and lastBattLevel <= 11 then
    playSound("bat"..batLevels[lastBattLevel])
    lastBattLevel = lastBattLevel + 1
  end

  if statusArmed == 1 and lastStatusArmed == 0 then
    lastStatusArmed = statusArmed
    playSound("armed")
  elseif statusArmed == 0 and lastStatusArmed == 1 then
    lastStatusArmed = statusArmed
    playSound("disarmed")
  end

  if gpsStatus > 2 and lastGpsStatus <= 2 then
    lastGpsStatus = gpsStatus
    playSound("gpsfix")
  elseif gpsStatus <= 2 and lastGpsStatus > 2 then
    lastGpsStatus = gpsStatus
    playSound("gpsnofix")
  end

  if frameType ~= -1 and flightMode ~= lastFlightMode then
    lastFlightMode = flightMode
    playSoundByFrameTypeAndFlightMode(frameType,flightMode)
  end
end

local function cycleBatteryInfo()
  if showDualBattery == false and batt2volt > 0 then
    showDualBattery = true
    return
  end
  if battsource == "vs" then
    battsource = "fc"
  elseif battsource == "fc" then
    battsource = "a2"
  elseif battsource == "a2" then
    battsource = "vs"
  end
end
--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
local showMessages = false
local showConfigMenu = false
local bgclock = 0
#ifdef BGRATE
local counter = 0
local bgrate = 0
local bgstart = 0
#endif --BGRATE
#ifdef FGRATE
local fgcounter = 0
local fgrate = 0
local fgstart = 0
#endif --FGRATE
#ifdef HUDRATE
local hudcounter = 0
local hudrate = 0
local hudstart = 0
#endif --HUDRATE
#ifdef BGTELERATE
local bgtelecounter = 0
local bgtelerate = 0
local bgtelestart = 0
#endif --BGTELERATE

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
#ifdef BGRATE
  ------------------------
  -- CALC BG LOOP RATE
  ------------------------
  -- skip first iteration
  local now = getTime()/100
  if counter == 0 then
    bgstart = now
  else
    bgrate = counter / (now - bgstart)
  end
  --
  counter=counter+1
#endif --BGRATE
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,3
  do
    processTelemetry()
#ifdef BGTELERATE
    ------------------------
    -- CALC BG TELE PROCESSING RATE
    ------------------------
    -- skip first iteration
    local now = getTime()/100
    if bgtelecounter == 0 then
      bgtelestart = now
    else
      bgtelerate = bgtelecounter / (now - bgtelestart)
    end
    --
    bgtelecounter=bgtelecounter+1
#endif --BGTELERATE
  end
  -- NORMAL: this runs at 20Hz (every 50ms)
  setTelemetryValue(VSpd_ID, VSpd_SUBID, VSpd_INSTANCE, vSpeed, 5 , VSpd_PRECISION , VSpd_NAME)
  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
#ifdef SENSORS  
    setSensorValues()
#endif --SENSORS
  end
  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    calcBattery()
    calcFlightTime()
    checkEvents()
    checkLandingStatus()
    checkCellVoltage(battsource,calcCellMin(cell1min,cell2min),calcCellMin(cell1minFC,cell2minFC),cellminA2)
#ifdef MINMAX
    minmaxValues[MAX_CURR1] = math.max(batt1current,minmaxValues[MAX_CURR1])
    minmaxValues[MAX_CURR2] = math.max(batt2current,minmaxValues[MAX_CURR2])
#endif --MINMAX
    bgclock = 0
  end
  bgclock = bgclock+1
end
--
local function run(event)
  lcd.clear()
#ifdef FGRATE
  ------------------------
  -- CALC FG LOOP RATE
  ------------------------
  -- skip first iteration
  local now = getTime()/100
  if fgcounter == 0 then
    fgstart = now
  else
    fgrate = fgcounter / (now - fgstart)
  end
  --
  fgcounter=fgcounter+1
#endif --FGRATE
  ---------------------
  -- SHOW MESSAGES
  ---------------------
  if showConfigMenu == false and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT) then
    showMessages = true
  end
  ---------------------
  -- SHOW CONFIG MENU
  ---------------------
  if showMessages == false and (event == EVT_MENU_LONG) then
    showConfigMenu = true
  end
  if showMessages then
    ---------------------
    -- MESSAGES
    ---------------------
    if event == EVT_EXIT_BREAK or event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT then
      showMessages = false
    end
    drawAllMessages()
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    drawConfigMenu(event)
    --
    if event == EVT_EXIT_BREAK then
      menu.editSelected = false
#ifdef MENUEX
      editComboValue = false
#endif --MENUEX
      showConfigMenu = false
      saveConfig()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if event == EVT_ENTER_BREAK then
      cycleBatteryInfo()
    end
#ifdef MINMAX
    if event == EVT_MENU_BREAK then
      showMinMaxValues = not showMinMaxValues
    end
#endif --MINMAX
#ifdef ALERTS
    -- when alerts are showed the press of exit always closes the alert window
    if currentAlertIdx > 0 and event == EVT_EXIT_BREAK then
      ackAlert()
    elseif showDualBattery == true and event == EVT_EXIT_BREAK then
      showDualBattery = false
    end
#else --ALERTS
    if showDualBattery == true and event == EVT_EXIT_BREAK then
      showDualBattery = false
    end
#endif --ALERTS
#ifdef TESTMODE
      symMode()
#endif --TESTMODE
#ifdef HUDRATE
    ------------------------
    -- CALC HUD REFRESH RATE
    ------------------------
    -- skip first iteration
    local hudnow = getTime()/100
    if hudcounter == 0 then
      hudstart = hudnow
    else
      hudrate = hudcounter / (hudnow - hudstart)
    end
    --
    hudcounter=hudcounter+1
#endif --HUDRATE
#ifdef X9
    drawHud()
#endif --X9
#ifdef X7
    -- on X7 the HUD is replaced with 2nd battery details
    if showDualBattery == false then
      drawHud()
    end
#endif --X7
    drawYaw()
    drawGrid()
#ifdef X7    
    drawCustomBoxes()
#endif --X7
    -- with dual battery default is to show aggregate view
    if batt2sources.fc or batt2sources.vs or batt2sources.a2 then
      if showDualBattery == false then
        -- dual battery: aggregate view
#ifdef X9
        lcd.drawText(HUD_X+HUD_WIDTH+1,TOPBAR_HEIGHT,"B1+B2",SMLSIZE+INVERS)
#endif --X9
#ifdef X7
        lcd.drawText(HUD_X+1,BOTTOMBAR_Y - 8,"2B",SMLSIZE+INVERS)
#endif --X7
        drawBatteryPane(HUD_X+HUD_WIDTH+1,battsource,batt1current+batt2current,getBatt1Capacity()+getBatt2Capacity(),batt1mah+batt2mah,calcCellMin(cell1min,cell2min),calcCellMin(cell1minFC,cell2minFC),cellminA2,calcCellMin(cell1sum,cell2sum),calcCellMin(cell1sumFC,cell2sumFC),cellsumA2,MIN_CELL_FC,MIN_BATT_FC,MAX_CURR)
      else
        -- dual battery:battery 1 right pane
#ifdef X9
        lcd.drawText(HUD_X+HUD_WIDTH+1,TOPBAR_HEIGHT,"B1",SMLSIZE+INVERS)
#endif --X9
        drawBatteryPane(HUD_X+HUD_WIDTH+1,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,MIN_CELL1_FC,MIN_BATT1_FC,MAX_CURR1)
        -- dual battery:battery 2 left pane
#ifdef X9
        lcd.drawText(0,TOPBAR_HEIGHT,"B2",SMLSIZE+INVERS)
        drawBatteryPane(0,battsource,batt2current,getBatt2Capacity(),batt2mah,cell2min,cell2minFC,0,cell2sum,cell2sumFC,0,MIN_CELL2_FC,MIN_BATT2_FC,MAX_CURR2)
#endif --X9
#ifdef X7
        drawX7BatteryLeftPane(battsource,batt2current,getBatt2Capacity(),batt2mah,cell2min,cell2minFC,0,cell2sum,cell2sumFC,0,MIN_CELL2_FC,MIN_BATT2_FC,MAX_CURR2)
#endif --X7
      end
    else
#ifdef X9      
      -- battery 1 right pane in single battery mode
      drawBatteryPane(HUD_X+HUD_WIDTH+1,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,MIN_CELL1_FC,MIN_BATT1_FC,MAX_CURR1)
    end
    -- left pane info when not in dual battery mode
    if showDualBattery == false then
      -- power is always based on flight controller values
      drawLeftPane(batt1current+batt2current,calcCellMin(cell1sumFC,cell2sumFC))
    end
#endif --X9
#ifdef X7
      --- battery 1 right pane in single battery mode
      drawBatteryPane(HUD_X+HUD_WIDTH+1,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,MIN_CELL1_FC,MIN_BATT1_FC,MAX_CURR1)
    end
    if showDualBattery == false then
      drawHomeDirection()
    end
    drawHomeDist()
    drawGPSStatus()
#ifdef MINMAX
    if showMinMaxValues == true then
      drawVArrow(HSPEED_XDIM + 2,HSPEED_Y - 2 ,6,true,false)
      drawVArrow(ALTASL_X + 26, ALTASL_Y - 1,6,true,false)
    end
#endif --MINMAX
#endif --X7
#ifdef X9
    drawHomeDirection()
#endif --X9
    drawTopBar()
    drawBottomBar()
    drawFailsafe()
#ifdef ALERTS
    drawAlerts()
#endif --ALERTS
#ifdef DEBUG    
    lcd.drawNumber(0,40,cell1maxFC,SMLSIZE+PREC1)
    lcd.drawNumber(25,40,calcCellCount(cell1maxFC),SMLSIZE)
#endif --DEBUG
#ifdef BGRATE    
    lcd.drawNumber(0,39,bgrate*10,PREC1+SMLSIZE+INVERS)
    lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --BGRATE
#ifdef FGRATE    
    lcd.drawNumber(0,39,fgrate*10,PREC1+SMLSIZE+INVERS)
    lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --FGRATE
#ifdef HUDRATE    
    lcd.drawNumber(0,39,hudrate*10,PREC1+SMLSIZE+INVERS)
    lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --HUDRATE
#ifdef TELERATE    
    lcd.drawNumber(0,39,telerate,SMLSIZE+INVERS)
#endif --TELERATE
#ifdef BGTELERATE    
    lcd.drawNumber(20,39,bgtelerate,SMLSIZE+INVERS)
#endif --BGTELERATE
#ifdef FRAMETYPE
    local fn = frameNames[frameType]
--    if fn ~= nil then
    lcd.drawNumber(0,39,frameType,SMLSIZE+INVERS)
    if fn ~= nil then
      lcd.drawText(lcd.getLastRightPos() + 1,39,fn,SMLSIZE+INVERS)
    else
      lcd.drawText(lcd.getLastRightPos() + 1,39,"N/A",SMLSIZE+INVERS)
    end
#endif --FRAMETYPE
    drawNoTelemetryData()
  end
end

local function init()
  loadConfig()
#ifdef X9
  pushMessage(6,VERSION)
#endif --X9
#ifdef X7
  pushMessage(6,VERSION)
#endif --X7
#ifdef TESTMODE
#ifdef DEMO
  pushMessage(7,"APM:Copter V3.5.4 (284349c3) QUAD")
  pushMessage(7,"Calibrating barometer")
  pushMessage(6,"Initialising APM")
  pushMessage(7,"Barometer calibration complete")
  pushMessage(7,"EKF2 IMU0 initial yaw alignment complete")
  pushMessage(7,"EKF2 IMU1 initial yaw alignment complete")
  pushMessage(7,"GPS 1: detected as u-blox at 115200 baud")
  pushMessage(6,"EKF2 IMU0 tilt alignment complete")
  pushMessage(6,"EKF2 IMU1 tilt alignment complete")
  pushMessage(7,"u-blox 1 HW: 00080000 SW: 2.01 (75331)")
  pushMessage(4,"Bad AHRS")
#endif --DEMO
#endif --TESTMODE
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}
