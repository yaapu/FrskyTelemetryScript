--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for Taranis X9D+
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

local frameTypes = {}
	frameTypes[0] = "copter"
	frameTypes[1] = "plane"
	frameTypes[2] = "copter"
	frameTypes[3] = "copter"
	frameTypes[4] = "copter"
	frameTypes[5] = ""
	frameTypes[6] = ""
	frameTypes[7] = ""
	frameTypes[8] = ""
	frameTypes[9] = ""
	frameTypes[10] = "rover"
	frameTypes[11] = "boat"
	frameTypes[12] = ""
	frameTypes[13] = "copter"
	frameTypes[14] = "copter"
	frameTypes[15] = "copter"
	frameTypes[16] = "plane"
	frameTypes[17] = ""
	frameTypes[18] = ""
	frameTypes[19] = "plane"
	frameTypes[20] = "plane"
	frameTypes[21] = "plane"
	frameTypes[22] = "plane"
	frameTypes[23] = "plane"
	frameTypes[24] = "plane"
	frameTypes[25] = "plane"
	frameTypes[26] = ""
	frameTypes[27] = ""
	frameTypes[28] = "plane"
	frameTypes[29] = "copter"
	frameTypes[30] = ""

local flightModes = {}
	flightModes["copter"] = {}
	flightModes["plane"] = {}
	flightModes["rover"] = {}	
	-- copter flight modes
	flightModes["copter"][0]=""
	flightModes["copter"][1]="Stabilize"
	flightModes["copter"][2]="Acro"
	flightModes["copter"][3]="AltHold"
	flightModes["copter"][4]="Auto"
	flightModes["copter"][5]="Guided"
	flightModes["copter"][6]="Loiter"
	flightModes["copter"][7]="RTL"
	flightModes["copter"][8]="Circle"
	flightModes["copter"][9]=""
	flightModes["copter"][10]="Land"
	flightModes["copter"][11]=""
	flightModes["copter"][12]="Drift"
	flightModes["copter"][13]=""
	flightModes["copter"][14]="Sport"
	flightModes["copter"][15]="Flip"
	flightModes["copter"][16]="AutoTune"
	flightModes["copter"][17]="PosHold"
	flightModes["copter"][18]="Brake"
	flightModes["copter"][19]="Throw"
	flightModes["copter"][20]="Avoid ADSB"
	flightModes["copter"][21]="Guided NO GPS"
	flightModes["copter"][22]="Smart RTL"
	-- plane flight modes
	flightModes["plane"][0]=""
	flightModes["plane"][1]="Manual"
	flightModes["plane"][2]="Circle"
	flightModes["plane"][3]="Stabilize"
	flightModes["plane"][4]="Training"
	flightModes["plane"][5]="Acro"
	flightModes["plane"][6]="FlyByWireA"
	flightModes["plane"][7]="FlyByWireB"
	flightModes["plane"][8]="Cruise"
	flightModes["plane"][9]="Autotune"
	flightModes["plane"][10]=""
	flightModes["plane"][11]="Auto"
	flightModes["plane"][12]="RTL"
	flightModes["plane"][13]="Loiter"
	flightModes["plane"][14]=""
	flightModes["plane"][15]="Avoid ADSB"
	flightModes["plane"][16]="Guided"
	flightModes["plane"][17]="Initializing"
	flightModes["plane"][18]="QStabilize"
	flightModes["plane"][19]="QHover"
	flightModes["plane"][20]="QLoiter"
	flightModes["plane"][21]="Qland"
	flightModes["plane"][22]="QRTL"
	-- rover flight modes
	flightModes["rover"][0]=""
	flightModes["rover"][1]="Manual"
	flightModes["rover"][2]="Acro"
	flightModes["rover"][3]=""
	flightModes["rover"][4]="Steering"
	flightModes["rover"][5]="Hold"
	flightModes["rover"][6]=""
	flightModes["rover"][7]=""
	flightModes["rover"][8]=""
	flightModes["rover"][9]=""
	flightModes["rover"][10]=""
	flightModes["rover"][11]="Auto"
	flightModes["rover"][12]="RTL"
	flightModes["rover"][13]="SmartRTL"
	flightModes["rover"][14]=""
	flightModes["rover"][15]=""
	flightModes["rover"][16]="Guided"
	flightModes["rover"][17]="Initializing"
	flightModes["rover"][18]=""
	flightModes["rover"][19]=""
	flightModes["rover"][20]=""
	flightModes["rover"][21]=""
	flightModes["rover"][22]=""

local soundFileBasePath = "/SOUNDS/yaapu0/en"
local sounds = {}
	-- battery
	sounds["bat5"] = "bat5.wav"
	sounds["bat10"] = "bat10.wav"
	sounds["bat15"] = "bat15.wav"
	sounds["bat20"] = "bat20.wav"
	sounds["bat25"] = "bat25.wav"
	sounds["bat30"] = "bat30.wav"
	sounds["bat40"] = "bat40.wav"
	sounds["bat50"] = "bat50.wav"
	sounds["bat60"] = "bat60.wav"	
	sounds["bat70"] = "bat70.wav"
	sounds["bat80"] = "bat80.wav"
	sounds["bat90"] = "bat90.wav"	
	-- gps
	sounds["gpsfix"] = "gpsfix.wav"
	sounds["gpsnofix"] = "gpsnofix.wav"
	-- failsafe
	sounds["lowbat"] = "lowbat.wav"
	sounds["ekf"] = "ekf.wav"
	-- events
	sounds["yaapu"] = "yaapu.wav"
	sounds["landing"] = "landing.wav"
	sounds["armed"] = "armed.wav"
	sounds["disarmed"] = "disarmed.wav"

local soundByFrameAndMode = {}
	soundByFrameAndMode["copter"] = {}
	soundByFrameAndMode["plane"] = {}
	soundByFrameAndMode["rover"] = {}
	-- Copter
	soundByFrameAndMode["copter"][0]=""
	soundByFrameAndMode["copter"][1]="stabilize.wav"	
	soundByFrameAndMode["copter"][2]="acro.wav"
	soundByFrameAndMode["copter"][3]="althold.wav"
	soundByFrameAndMode["copter"][4]="auto.wav"
	soundByFrameAndMode["copter"][5]="guided.wav"
	soundByFrameAndMode["copter"][6]="loiter.wav"
	soundByFrameAndMode["copter"][7]="rtl.wav"
	soundByFrameAndMode["copter"][8]="circle.wav"
	soundByFrameAndMode["copter"][9]=""
	soundByFrameAndMode["copter"][10]="land.wav"
	soundByFrameAndMode["copter"][11]=""
	soundByFrameAndMode["copter"][12]="drift.wav"
	soundByFrameAndMode["copter"][13]=""
	soundByFrameAndMode["copter"][14]="sport.wav"
	soundByFrameAndMode["copter"][15]="flip.wav"
	soundByFrameAndMode["copter"][16]="loiter.wav"
	soundByFrameAndMode["copter"][17]="poshold.wav"
	soundByFrameAndMode["copter"][18]="brake"
	soundByFrameAndMode["copter"][19]="throw.wav"
	soundByFrameAndMode["copter"][20]="avoidadbs"
	soundByFrameAndMode["copter"][21]="guidednogps"
	-- Plane
	soundByFrameAndMode["plane"][0]=""
  soundByFrameAndMode["plane"][1]="manual.wav"
	soundByFrameAndMode["plane"][2]="circle.wav"
	soundByFrameAndMode["plane"][3]="stabilize.wav"
	soundByFrameAndMode["plane"][4]="training.wav"
	soundByFrameAndMode["plane"][5]="acro.wav"
	soundByFrameAndMode["plane"][6]="flybywirea.wav"
	soundByFrameAndMode["plane"][7]="flybywireb.wav"
	soundByFrameAndMode["plane"][8]="cruise.wav"
	soundByFrameAndMode["plane"][9]="autotune.wav"
	soundByFrameAndMode["plane"][10]=""
	soundByFrameAndMode["plane"][11]="auto.wav"
	soundByFrameAndMode["plane"][12]="rtl.wav"
	soundByFrameAndMode["plane"][13]="loiter.wav"
	soundByFrameAndMode["plane"][14]=""
	soundByFrameAndMode["plane"][15]="avoidadbs"
	soundByFrameAndMode["plane"][16]="guided.wav"
	soundByFrameAndMode["plane"][17]="initializing.wav"
	soundByFrameAndMode["plane"][18]="qstabilize.wav"
	soundByFrameAndMode["plane"][19]="qhover.wav"
	soundByFrameAndMode["plane"][20]="qloiter.wav"
	soundByFrameAndMode["plane"][21]="qland.wav"
	soundByFrameAndMode["plane"][22]="qrtl.wav"
	-- Rover
	soundByFrameAndMode["rover"][0]=""
	soundByFrameAndMode["rover"][1]="manual_r.wav"
	soundByFrameAndMode["rover"][2]="acro_r.wav"
	soundByFrameAndMode["rover"][3]=""
	soundByFrameAndMode["rover"][4]="steering_r.wav"
	soundByFrameAndMode["rover"][5]="hold_r.wav"
	soundByFrameAndMode["rover"][6]=""
	soundByFrameAndMode["rover"][7]=""
	soundByFrameAndMode["rover"][8]=""
	soundByFrameAndMode["rover"][9]=""
	soundByFrameAndMode["rover"][10]=""
	soundByFrameAndMode["rover"][11]="auto_r.wav"
	soundByFrameAndMode["rover"][12]="rtl_r.wav"
	soundByFrameAndMode["rover"][13]="smartrtl_r.wav"
	soundByFrameAndMode["rover"][14]=""
	soundByFrameAndMode["rover"][15]=""
	soundByFrameAndMode["rover"][16]="guided_r.wav"
	soundByFrameAndMode["rover"][17]="initializing.wav"
	soundByFrameAndMode["rover"][18]=""
	soundByFrameAndMode["rover"][19]=""
	soundByFrameAndMode["rover"][20]=""
	soundByFrameAndMode["rover"][21]=""
	soundByFrameAndMode["rover"][22]=""


local gpsStatuses = {}
  gpsStatuses[0]="NoGPS"
  gpsStatuses[1]="NoLock"
  gpsStatuses[2]="2D"
  gpsStatuses[3]="3D"

local mavSeverity = {}
  mavSeverity[0]="EMR"
  mavSeverity[1]="ALR"
  mavSeverity[2]="CRT"
  mavSeverity[3]="ERR"
  mavSeverity[4]="WRN"
  mavSeverity[5]="NOT"
  mavSeverity[6]="INF"
  mavSeverity[7]="DBG"

-- FLVSS
local cell = {0, 0, 0, 0, 0 ,0}                                                  
local cellsumtype = 0
local cellfull = 4.2
--
local cellmin = 0
local cellsum = 0             
--
local cellminA2 = 0
local cellsumA2 = 0
--
local cellminFC = 0
local cellsumFC = 0
--
local battSources = {
    a2 = false,
    vs = false,
    fc = false
  }
-- STATUS
local flightMode = 0
local simpleMode = 0
local landComplete = 0
local statusArmed = 0
local battFailsafe = 0
local lastBattFailsafe = 0
local ekfFailsafe = 0
local lastEkfFailsafe = 0
local battSource = "na"
-- GPS
local numSats = 0
local gpsStatus = 0
local gpsHdopC = 100
local gpsAlt = 0
-- BATT
local battVolt = 0
local battCurrent = 0
local battMah = 0
-- BATT2
local battVolt2 = 0
local battCurrent2 = 0
local battMah2 = 0
local LIPObatt = 0
local LIPOcelm = 0
-- HOME
local homeDist = 0
local homeAlt = 0
local homeAngle = -1
-- MESSAGES
local msgBuffer = "" 
local msgHistory = {}
local msgIdx = 1
local msgDuplicate = 1
local lastMsg = ""
local lastMsgValue = 0
local lastMsgTime = 0
-- VELANDYAW
local vSpeed = 0
local hSpeed = 0
local yaw = 0
-- ROLLPITCH
local roll = 0
local pitch = 0
-- TELEMETRY
local SENSOR_ID,FRAME_ID,DATA_ID,VALUE
local c1,c2,c3,c4
-- PARAMS
local paramId,paramValue
local frameType = 2
local battFailsafeVoltage = 0
local battFailsafeCapacity = 0
local battCapacity = 0
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
-- DISPLAY mix
--
local noTelemetryData = 1
--
local radioModel = "x9"
-- TEST MODE
local flagSim = false
local thrOut = 0

--[[]]--
-- DEFAULT YAAPU LAYOUT
local hudPos = {
	x = 68,
	width = 76
}

local leftPanePos = {
	x = 68,
}

local rightPanePos = {
	x = 68,
}


local topBarPos = {
	y = 0,
  height = 7,
  width = 212
}

local bottomBarPos = {
	y = 57,
  height = 7,
  width = 212
}

local box1Pos = {
	x = 61,
	y = 17,
	width = 28,
	height = 16
}

local box2Pos = {
	x = 61,
	y = 46,
	width = 17,
	height = 12
}

local battVoltPos = {
  x = 212 - 65,
  y = 44,
  yV = 44,
  flags = MIDSIZE+PREC1,
  flagsV = SMLSIZE
}

local battCellPos = {
  x = 212 - 39,
  y = 7,
  yV = 9,
  yS = 17,
  flags = DBLSIZE+PREC2
}

local battCurrPos = {
  x = 212 - 29,
  y = 44,
  yA = 44,
  flags = MIDSIZE+PREC1,
  flagsA = SMLSIZE
}

local battPercPos = {
  x = 147,
  y = 11,
  yPerc = 16,
  flags = MIDSIZE,
  flagsPerc = SMLSIZE
}

local battGaugePos = {
  x = 150,
  y = 26,
  width = 59, -- must be multiple of 4
  height = 5,
  steps = 10
}

local battMahPos = {
  x = 212 - 55,
  y = 34,
  flags = SMLSIZE+PREC1
}

local flightModePos = {
  x = 1,
  y = 0,
  flags = SMLSIZE+INVERS
}

local homeAnglePos = {
  x = 60, -- right aligned
  y = 27,
  xLabel = 3,
  yLabel = 27,
  flags = SMLSIZE
}

local hSpeedPos = {
  x = 44, -- right aligned
  y = 50,
  xLabel = 2,
  yLabel = 49,
  xDim = 45,
  yDim = 49, 
  flags = SMLSIZE,
  arrowWidth = 10
}

local gpsStatusPos = {
	x = 0,
	y = 6,
	border = 0
}

local altAslPos = {
	x = 2, -- right aligned
	y = 32,
	xLabel = 3,
	yLabel = 24
}

local homeDistPos = {
  x = 35, --right aligned
  y = 32,
  xLabel = 34,
  yLabel = 25,
  flags = SMLSIZE,
  arrowWidth = 8
}

local homeDirectionPos = {
	x = 75,
	y = 49,
	r = 7
}

local flightTimePos = {
	x = 180,
	y = 0,
	flags = SMLSIZE+INVERS
}

local rssiPos = {
	x = 69,
	y = 0,
	flags = SMLSIZE+INVERS
}

local txVoltagePos = {
	x = 106 - 40 + 50,
	y = 0,
	flags = SMLSIZE+INVERS
}

--
local function playSound(soundFile)
	playFile(soundFileBasePath .. "/" .. sounds[soundFile])
end

local function playSoundByFrameTypeAndFlightMode(frameType,flightMode)
	playFile(soundFileBasePath .. "/" .. soundByFrameAndMode[frameTypes[frameType]][flightMode])
end

local function roundTo(val,int)
	return math.floor(val/int) * int
end

local function drawRightArrow(x,y,width)
	lcd.drawLine(x, y, x + width,y, SOLID, 0)
	lcd.drawLine(x + width - 1,y  - 1,x + width - 2,y  - 2, SOLID, 0)
	lcd.drawLine(x + width - 1,y  + 1,x + width - 2,y  + 2, SOLID, 0)
end

local function drawHArrow(x,y,width)
	lcd.drawLine(x, y, x + width,y, SOLID, 0)
	lcd.drawLine(x + 1,y  - 1,x + 2,y  - 2, SOLID, 0)
	lcd.drawLine(x + 1,y  + 1,x + 2,y  + 2, SOLID, 0)
	lcd.drawLine(x + width - 1,y  - 1,x + width - 2,y  - 2, SOLID, 0)
	lcd.drawLine(x + width - 1,y  + 1,x + width - 2,y  + 2, SOLID, 0)
end

local function drawVArrow(x,y,h)
	lcd.drawLine(x,y,x,y + h, SOLID, 0)
	lcd.drawLine(x - 1,y + 1,x - 2,y  + 2, SOLID, 0)
	lcd.drawLine(x + 1,y + 1,x + 2,y  + 2, SOLID, 0)
	lcd.drawLine(x - 1,y  + h - 1,x - 2,y + h - 2, SOLID, 0)
	lcd.drawLine(x + 1,y  + h - 1,x + 2,y + h - 2, SOLID, 0)
end

local function drawHomeIcon(x,y,size)
	lcd.drawLine(x,y,x + size,y, SOLID, 0)
	lcd.drawLine(x + size,y - 1,x + size,y - size, SOLID, 0)
	lcd.drawLine(x,y - 1,x,y - size, SOLID, 0)
	lcd.drawLine(x-1,y-size+1,x + size/2,y-size - size/4,SOLID,0)
	lcd.drawLine(x + size + 1,y-size+1,x + size/2 + 1,y-size - size/4 + 1,SOLID,0)
	lcd.drawRectangle(x + size/2 - 1,y - size/2,size/2,size/2,SOLID)
	lcd.drawFilledRectangle(x + size/2 - 1,y - size/2,size/2,size/2,SOLID)		
end

local function drawHomeMiniIcon(x,y)
	lcd.drawLine(x,y,x + 4,y, SOLID, 0)
	lcd.drawLine(x + 4,y - 1,x + 4,y - 4, SOLID, 0)
	lcd.drawLine(x,y - 1,x,y - 4, SOLID, 0)
	lcd.drawLine(x-1,y-4+1,x + 2,y-4 - 1,SOLID,0)
	lcd.drawLine(x + 4 + 1,y - 4 + 1,x + 2 + 1,y-4 - 4/4 + 1,SOLID,0)
	lcd.drawLine(x + 2,y - 2,x + 2,y-1,SOLID,0)
end

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

local function pushMessage(severity, msg)
	if ( severity < 4) then
		playTone(400,300,0)
	else
		playTone(600,300,0)
	end
	local mm = msg
	if msg == lastMsg then
		msgDuplicate = msgDuplicate + 1
		if msgDuplicate > 1 then
			if string.len(mm) > 33 then
				mm = string.sub(mm,1,33)
				msgHistory[msgIdx - 1] = string.format("%02d:%s %-33s (x%d)", msgIdx - 1, mavSeverity[severity], mm, msgDuplicate)
			else
				msgHistory[msgIdx - 1] = string.format("%02d:%s %s (x%d)", msgIdx - 1, mavSeverity[severity], msg, msgDuplicate)
			end
		end
	else
		msgHistory[msgIdx] = string.format("%02d:%s %s", msgIdx, mavSeverity[severity], msg)
		msgIdx = msgIdx + 1
    lastMsg = msg
		msgDuplicate = 1
	end
	lastMsgTime = getTime() 
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
--
local function startTimer()
	lastTimerStart = getTime()/100
end

local function stopTimer()
	seconds = seconds + getTime()/100 - lastTimerStart
	lastTimerStart = 0
end

local function symTimer()
	seconds = 60 * 9 + 30
	thrOut = getValue("thr")
	if (thrOut > -500 ) then
		landComplete = 1
	else
		landComplete = 0
	end
end

local function symGPS()
	thrOut = getValue("thr")
	if (thrOut > 0 ) then
		numSats = 17
		gpsStatus = 3
		gpsHdopC = 6
		ekfFailsafe = 0
		battFailsafe = 0
		noTelemetryData = 0
		statusArmed = 1
	elseif thrOut > -500  then
		numSats = 6
		gpsStatus = 3
		gpsHdopC = 17
		ekfFailsafe = 1
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
	if (ch11 < -300) then
		frameType = 2
	elseif ch11 < 300 then
		frameType = 1
	else
		frameType = 10
	end
end

local function symBatt()
	thrOut = getValue("thr")
	if (thrOut > 0 ) then
		LIPObatt = 1350 + ((thrOut)*0.01 * 30)
		LIPOcelm = LIPObatt/4
		battCurrent = 100 +  ((thrOut)*0.01 * 30)
		battVolt = LIPObatt*0.1
		battCapacity = 5200
		battMah = math.abs(1000*(thrOut/200))
		flightMode = math.floor(20 * math.abs(thrOut)*0.001)
		gpsAlt = math.floor(10 * math.abs(thrOut)*0.1)
		homeDist = math.floor(10 * math.abs(thrOut)*0.1)
  else
		battMah = 0
	end
end

-- simulates attitude by using channel 1 for roll, channel 2 for pitch and channel 4 for yaw
local function symAttitude()
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
end

local function symHome()
	local yawCh = 0
	local S2Ch = 0
	-- home angle in deg [0-360]
	S2Ch = getValue("ch12")
	yawCh = getValue("ch4")
	homeAlt = yawCh
	vSpeed = yawCh * 0.1
	hSpeed = vSpeed
	if ( yawCh >= 0) then
		yawCh = yawCh * 0.175
	else
		yawCh = 360 + (yawCh * 0.175)
	end
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
	yaw = yawCh
end

local function processTelemetry()
  SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
	if ( FRAME_ID == 0x10) then
-- >> DEBUG 
--		logTelemetryToFile(SENSOR_ID,FRAME_ID,DATA_ID,VALUE)
-- << DEBUG
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
			gpsStatus = bit32.extract(VALUE,4,2)
			gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
			gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) -- dm
			if (bit32.extract(VALUE,31,1) == 1) then
				gpsAlt = gpsAlt * -1
			end
		elseif ( DATA_ID == 0x5003) then -- BATT 
			battVolt = bit32.extract(VALUE,0,9)
			battCurrent = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
			battMah = bit32.extract(VALUE,17,15)
		elseif ( DATA_ID == 0x5008) then -- BATT2 
			battVolt2 = bit32.extract(VALUE,0,9)
			battCurrent2 = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
			battMah2 = bit32.extract(VALUE,17,15)
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
				battCapacity = paramValue
			end
		end
	end
end

local function telemetryEnabled()
	if flagSim then
		return true
	end
	if getValue("RxBt") == 0 then
		noTelemetryData = 1
	end
	return noTelemetryData == 0
end

local function calcBattery()
	local battA2 = 0
	local cellCount = 3;
	--
	cellResult = getValue("Cels")                          

	if type(cellResult) == "table" then                     
    cellmin = cellfull
		cellsum = 0                                         
		for i = 1, #cell do cell[i] = 0 end                 
			cellsumtype = #cellResult                           
		for i, v in pairs(cellResult) do                    
			cellsum = cellsum + v                             
			cell[i] = v                                       
			if cellmin > v then                               
				cellmin = v
			end
		end -- end for
    -- it was not connected at boot
    if battSources.vs == false then
      battSource = "na"
    end
    if battSource == "na" then
      battSource = "vs"
    end
    battSources.vs = true
	else
    battSources.vs = false
    cellmin = 0
    cellsum = 0
  end
  
	-- let's check if A2 is defined
	battA2 = getValue("A2")
		--
  if battA2 > 0 then
      if battA2 > 21 then
        cellCount = 6
      elseif battA2 > 17 then
        cellCount = 5
      elseif battA2 > 13 then
        cellCount = 4
      else
        cellCount = 3
      end
    --
    cellminA2 = battA2/cellCount
    cellsumA2 = battA2
    
    battSources.a2 = true
    
    if battSource == "na" then
      battSource = "a2"
    end
  else
    battSources.a2 = false
    cellminA2 = 0
    cellsumA2 = 0
  end
  
	-- A2 is not defined, last chance is battVolt
  if battVolt > 0 then
    cellsumFC = battVolt*0.1
    if cellsumFC > 21 then
      cellCount = 6
    elseif cellsumFC > 17 then
      cellCount = 5
    elseif cellsumFC > 13 then
      cellCount = 4
    else
      cellCount = 3
    end
    --
    cellminFC = cellsumFC/cellCount
    
    if battSource == "na" then
      battSource = "fc"
    end
    battSources.fc = true
  else
    battSources.fc = false
    cellminFC = 0
    cellsumFC = 0
  end
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

local function drawCellVoltage()
 	
  if battSource == "vs" then
    LIPOcelm = cellmin*100
  elseif battSource == "fc" then
    LIPOcelm = cellminFC*100
  elseif battSource == "a2" then
    LIPOcelm = cellminA2*100
  end
  --
	if LIPOcelm < 350 then
		drawNumberWithTwoDims(battCellPos.x, battCellPos.y, battCellPos.yV, battCellPos.yS,LIPOcelm,"V",battSource,battCellPos.flags+BLINK,SMLSIZE+BLINK,SMLSIZE+BLINK)
	else
		drawNumberWithTwoDims(battCellPos.x, battCellPos.y, battCellPos.yV, battCellPos.yS,LIPOcelm,"V",battSource,battCellPos.flags,SMLSIZE,SMLSIZE)
	end
end

local function drawBatteryVoltage()
	--
	if battSource == "vs" then
    LIPObatt = cellsum*100
  elseif battSource == "fc" then
    LIPObatt = cellsumFC*100
  elseif battSource == "a2" then
    LIPObatt = cellsumA2*100
  end
  --
	drawNumberWithDim(battVoltPos.x,battVoltPos.y,battVoltPos.yV,LIPObatt/10,"V",battVoltPos.flags,battVoltPos.flagsV)
end

local function drawBatteryCurrent()
	drawNumberWithDim(battCurrPos.x,battCurrPos.y,battCurrPos.yA,battCurrent,"A",battCurrPos.flags,battCurrPos.flagsA)
end

local function drawBatteryPerc()
	if (battCapacity > 0) then
		LIPOperc = (1 - (battMah/battCapacity))*100
	else
		LIPOperc = 0
	end

	lcd.drawNumber(battPercPos.x, battPercPos.y, LIPOperc, battPercPos.flags)       
	lcd.drawText(lcd.getLastRightPos(), battPercPos.yPerc, "%", battPercPos.flagsPerc)
end

local function drawBatteryGauge()
	-- display capacity bar %
	local perc = 0
	if (battCapacity > 0) then
		perc = (1 - (battMah/battCapacity))*100
		if (perc) < 0 then
			perc = 1
		end
		if perc > 100 then
			perc = 99
		end
	else
		perc = 0
	end
	--
	lcd.drawFilledRectangle(battGaugePos.x, battGaugePos.y, 2 + math.floor(perc * 0.01 * (battGaugePos.width - 3)), battGaugePos.height, SOLID)
	lcd.drawRectangle(battGaugePos.x, battGaugePos.y, 2 + math.floor(perc * 0.01 * (battGaugePos.width - 3)), battGaugePos.height, SOLID)
	--
	local step = battGaugePos.width/battGaugePos.steps
	-- 75 - 50 - 30 - 20 - 10
  for s=1,battGaugePos.steps - 1 do
		lcd.drawLine(battGaugePos.x + s*step - 1,battGaugePos.y, battGaugePos.x + s*step - 1, battGaugePos.y + battGaugePos.height - 1,SOLID,0)
	end

	--lcd.drawRectangle(battGaugePos.x, battGaugePos.y, battGaugePos.width, battGaugePos.height, ERASE)
	--lcd.drawRectangle(battGaugePos.x, battGaugePos.y, battGaugePos.width, battGaugePos.height, SOLID)
end

local function drawBatteryMah()
  if battMahPos.vert then
    lcd.drawText(battMahPos.x, battMahPos.y, "Ah", SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), battMahPos.y, battMah/100, battMahPos.flags+RIGHT)
    lcd.drawText(battMahPos.x, battMahPos.y+8, "Ah", SMLSIZE+RIGHT+INVERS)
    lcd.drawNumber(lcd.getLastLeftPos(), battMahPos.y+8, battCapacity/100, battMahPos.flags+RIGHT+INVERS)  
  else
    lcd.drawNumber(battMahPos.x, battMahPos.y, battMah/100, battMahPos.flags)
    lcd.drawText(lcd.getLastRightPos(), battMahPos.y, "/", SMLSIZE)
    lcd.drawNumber(lcd.getLastRightPos(), battMahPos.y, battCapacity/100, battMahPos.flags)  
    lcd.drawText(lcd.getLastRightPos(), battMahPos.y, "Ah", SMLSIZE)
  end
end

local function drawTopBar()
	lcd.drawFilledRectangle(0,topBarPos.y, topBarPos.width, 7, SOLID)
	lcd.drawRectangle(0, topBarPos.y, topBarPos.width, 7, SOLID)
end

local function drawBottomBar()
	lcd.drawFilledRectangle(0,bottomBarPos.y, bottomBarPos.width, 7, SOLID)
	lcd.drawRectangle(0, bottomBarPos.y, bottomBarPos.width, 7, SOLID)
end

local function drawFlightMode()
	if (not telemetryEnabled()) then
		lcd.drawFilledRectangle((212-150)/2,18, 150, 30, SOLID)
		lcd.drawText(60, 29, "no telemetry data", INVERS)
		return
	end

	local strMode = flightModes[frameTypes[frameType]][flightMode]
	--
	lcd.drawText(flightModePos.x, flightModePos.y, strMode, flightModePos.flags)

	if ( simpleMode == 1) then
		lcd.drawText(lcd.getLastRightPos(), 1, "(S)", flightModePos.flags)
	end
end

local function drawHomeAngle()
	drawHomeIcon(homeAnglePos.xLabel + 1,homeAnglePos.yLabel + 6,6)
	lcd.drawText(homeAnglePos.xLabel + 10, homeAnglePos.yLabel, "Angle",homeAnglePos.flags)

	if homeAngle == -1 then
		lcd.drawNumber(homeAnglePos.x, homeAnglePos.y, 0, homeAnglePos.flags+RIGHT+BLINK)
	else
		lcd.drawNumber(homeAnglePos.x, homeAnglePos.y, homeAngle, homeAnglePos.flags+RIGHT)
	end
end

local function drawHomeDist()
	if radioModel == "x7" then
    drawHArrow(homeDistPos.xLabel,homeDistPos.yLabel + 2,homeDistPos.arrowWidth)
  else
    drawHomeIcon(homeDistPos.xLabel + 1,homeDistPos.yLabel + 5,6)
    drawHArrow(homeDistPos.xLabel + 10,homeDistPos.yLabel + 2,homeDistPos.arrowWidth)
  end
	if homeAngle == -1 then
		lcd.drawNumber(homeDistPos.x, homeDistPos.y, homeDist, homeDistPos.flags+BLINK)
		lcd.drawText(lcd.getLastRightPos(), homeDistPos.y, "m",homeDistPos.flags+BLINK)
	else
		lcd.drawNumber(homeDistPos.x, homeDistPos.y, homeDist, homeDistPos.flags)
		lcd.drawText(lcd.getLastRightPos(), homeDistPos.y, "m",homeDistPos.flags)
	end
end

local function drawHSpeed()
	drawRightArrow(hSpeedPos.xLabel + 4,hSpeedPos.yLabel,4)
	drawRightArrow(hSpeedPos.xLabel + 6,hSpeedPos.yLabel + 4,5)
	lcd.drawPoint(hSpeedPos.xLabel + 2,hSpeedPos.yLabel)
	lcd.drawPoint(hSpeedPos.xLabel,hSpeedPos.yLabel)
	lcd.drawPoint(hSpeedPos.xLabel + 4,hSpeedPos.yLabel + 4)
	lcd.drawPoint(hSpeedPos.xLabel + 2,hSpeedPos.yLabel + 4)
	
  lcd.drawNumber(hSpeedPos.x - 10, hSpeedPos.y - 1, hSpeed, hSpeedPos.flags+RIGHT+PREC1)
  
  lcd.drawText(hSpeedPos.xDim - 4, hSpeedPos.yDim - 4, "m",hSpeedPos.flags+RIGHT)
	lcd.drawText(hSpeedPos.xDim + 1, hSpeedPos.yDim, "s",hSpeedPos.flags+RIGHT)
	lcd.drawLine(hSpeedPos.xDim -6,hSpeedPos.yDim + 3,hSpeedPos.xDim -3,hSpeedPos.yDim,SOLID,0)
end

local function drawMessage()
	local now = getTime()
	if (now - lastMsgTime ) > 150 then
		lcd.drawText(1, 58, msgHistory[msgIdx-1],SMLSIZE+INVERS)
	else
		lcd.drawText(1, 58, msgHistory[msgIdx-1],SMLSIZE+INVERS+BLINK)
	end
end

local function drawAllMessages()
	local idx = 1
	if (msgIdx <= 8) then
		for i = 1, msgIdx - 1 do
			lcd.drawText(1, 8*(idx - 1), msgHistory[i],SMLSIZE)
			idx = idx+1
		end
	else
		for i = msgIdx - 8,msgIdx - 1 do
			lcd.drawText(1, 8*(idx-1), msgHistory[i],SMLSIZE)
			idx = idx+1
		end
	end
end

local function drawAltAsl()
	lcd.drawText(altAslPos.xLabel + 4, altAslPos.yLabel, "Asl", SMLSIZE)
	drawVArrow(altAslPos.xLabel,altAslPos.yLabel - 1,7)
	if gpsStatus  > 2 then
		lcd.drawNumber(altAslPos.x, altAslPos.y, gpsAlt/10, SMLSIZE)
		lcd.drawText(lcd.getLastRightPos(), altAslPos.y , "m", SMLSIZE)
  else
		lcd.drawNumber(altAslPos.x, altAslPos.y, 0, SMLSIZE+BLINK)
		lcd.drawText(lcd.getLastRightPos(), altAslPos.y , "m", SMLSIZE+BLINK)
  end
end

local function drawGPSStatus()
	local xx = gpsStatusPos.x
	local yy = gpsStatusPos.y
	--
  --if radioModel == "x7" then
  lcd.drawLine(xx ,yy + 13,xx+66,yy + 13,SOLID,0)
  --else
  --  lcd.drawLine(xx ,yy,xx+66,yy,SOLID,0)
	--end
    lcd.drawLine(xx + 34,yy+1,xx+34,yy+12,SOLID,0)
	local strStatus = gpsStatuses[gpsStatus] 
	--
	local flags = BLINK
	if gpsStatus  > 2 then
		if homeAngle ~= -1 then
			flags = 0
		end
		lcd.drawText(xx + 4,yy + 6, strStatus, SMLSIZE)
		lcd.drawNumber(lcd.getLastRightPos() + 1, yy + 1, numSats, MIDSIZE)
		
    lcd.drawText(xx + 39, yy + 6 , "H", SMLSIZE)
		--
		if gpsHdopC > 100 then
			lcd.drawNumber(lcd.getLastRightPos() + 1, yy + 1, gpsHdopC , MIDSIZE+PREC1+flags)
		else
			lcd.drawNumber(lcd.getLastRightPos() + 1, yy + 1, gpsHdopC , MIDSIZE+PREC1+flags)
		end
	else
		lcd.drawText(xx + 5, yy + 4, strStatus, SMLSIZE+INVERS+BLINK)
	end
end

local function drawFailsafe()
	if ekfFailsafe > 0 then
		if lastEkfFailsafe == 0 then
			playSound("ekf")
		end
		lcd.drawText(hudPos.x + hudPos.width/2 - 6, 40, "EKF", SMLSIZE+INVERS+BLINK)
		lcd.drawText(hudPos.x + hudPos.width/2 - 17, 49, "FAILSAFE", SMLSIZE+INVERS+BLINK)
	end
	if battFailsafe > 0 then
		if lastBattFailsafe == 0 then
			playSound("lowbat")
		end
		lcd.drawText(hudPos.x + hudPos.width/2 - 8, 40, "BATT", SMLSIZE+INVERS+BLINK)
		lcd.drawText(hudPos.x + hudPos.width/2 - 17, 49, "FAILSAFE", SMLSIZE+INVERS+BLINK)
	end
	lastEkfFailsafe = ekfFailsafe
	lastBattFailsafe = battFailsafe
end

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
	-- center indicators for vSpeed and alt
	local leftIndicatorWidth = 15
	local rightIndicatorWidth = 17
	
  -- lets erase to hide the artificial horizon lines
  for ly=0,5 do
    lcd.drawLine(hudPos.x,32 - ly,hudPos.x + leftIndicatorWidth + (5 - ly),32 - ly, SOLID, ERASE)
    lcd.drawLine(hudPos.x + hudPos.width - rightIndicatorWidth - 1 - (5 - ly),32 - ly,hudPos.x + hudPos.width - 1,32 - ly,SOLID,ERASE)
  end
  for ly=1,4 do
    lcd.drawLine(hudPos.x,32 + ly,hudPos.x + leftIndicatorWidth + (5 - ly),32 + ly, SOLID, ERASE)
    lcd.drawLine(hudPos.x + hudPos.width - rightIndicatorWidth - 1 - (5 - ly),32 + ly,hudPos.x + hudPos.width - 1,32 + ly,SOLID,ERASE)
  end
  --
  --
	lcd.drawLine(hudPos.x,32 - 5,hudPos.x + leftIndicatorWidth,32 - 5, SOLID, 0)
	lcd.drawLine(hudPos.x,32 + 4,hudPos.x + leftIndicatorWidth,32 + 4, SOLID, 0)
	lcd.drawLine(hudPos.x + leftIndicatorWidth + 1,32 + 4,hudPos.x + leftIndicatorWidth + 5,32, SOLID, 0)
	lcd.drawLine(hudPos.x + leftIndicatorWidth + 1,32 - 4,hudPos.x + leftIndicatorWidth + 5,32, SOLID, 0)
	lcd.drawPoint(hudPos.x + leftIndicatorWidth + 5,32)
	--
	lcd.drawLine(hudPos.x + hudPos.width - rightIndicatorWidth - 1,32 - 5,hudPos.x + hudPos.width - 1,32 - 5,SOLID,0)
	lcd.drawLine(hudPos.x + hudPos.width - rightIndicatorWidth - 1,32 + 4,hudPos.x + hudPos.width - 1,32 + 4,SOLID,0)
	lcd.drawLine(hudPos.x + hudPos.width - rightIndicatorWidth - 2,32 + 4,hudPos.x + hudPos.width - rightIndicatorWidth - 6,32, SOLID, 0)
	lcd.drawLine(hudPos.x + hudPos.width - rightIndicatorWidth - 2,32 - 4,hudPos.x + hudPos.width - rightIndicatorWidth - 6,32, SOLID, 0)
	lcd.drawPoint(hudPos.x + hudPos.width - rightIndicatorWidth - 6,32)
	--
	local xx = hudPos.x + hudPos.width - rightIndicatorWidth - 2
	
	if homeAlt > 0 then
		if homeAlt < 10 then -- 2 digits with decimal
			lcd.drawNumber(hudPos.x + hudPos.width,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
		else -- 3 digits
			lcd.drawNumber(hudPos.x + hudPos.width,32 - 3,homeAlt,SMLSIZE+RIGHT)
		end
	else
		if homeAlt > -10 then -- 1 digit with sign
			lcd.drawNumber(hudPos.x + hudPos.width,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
		else -- 3 digits with sign
			lcd.drawNumber(hudPos.x + hudPos.width,32 - 3,homeAlt,SMLSIZE+RIGHT)
		end
	end
	--
	if (vSpeed > 999) then
		lcd.drawNumber(hudPos.x + 1,32 - 3,vSpeed*0.1,SMLSIZE)
	elseif (vSpeed < -99) then
		lcd.drawNumber(hudPos.x + 1,32 - 3,vSpeed * 0.1,SMLSIZE)
	else
		lcd.drawNumber(hudPos.x + 1,32 - 3,vSpeed,SMLSIZE+PREC1)
	end
	-- up pointing center arrow
	local arrowX = math.floor(hudPos.x + hudPos.width/2)
 	lcd.drawLine(arrowX - 5,34 + 5,arrowX ,34 ,SOLID,ERASE)
	lcd.drawLine(arrowX - 5,34 + 5,arrowX ,34 ,SOLID,0)
 	lcd.drawLine(arrowX,34 ,arrowX + 5, 34 + 5,SOLID,ERASE)
	lcd.drawLine(arrowX,34 ,arrowX + 5, 34 + 5,SOLID,0)
end

local function drawRoll()
	local r = -roll
	local r2 = 10 --vertical distance between roll horiz segments
	local cx,cy,dx,dy,ccx,ccy,cccx,cccy
	local yPos = topBarPos.y + topBarPos.height + 8
  -- no roll ==> segments are vertical, offsets are multiples of r2
	if ( roll == 0) then
		dx=0
		dy=pitch
		cx=0
		cy=r2
		ccx=0
		ccy=2*r2
		cccx=0
		cccy=3*r2
	else
		-- center line offsets
		dx = math.cos(math.rad(90 - r)) * -pitch 
		dy = math.sin(math.rad(90 - r)) * pitch
		-- 1st line offsets
		cx = math.cos(math.rad(90 - r)) * r2
		cy = math.sin(math.rad(90 - r)) * r2
		-- 2nd line offsets
		ccx = math.cos(math.rad(90 - r)) * 2 * r2
		ccy = math.sin(math.rad(90 - r)) * 2 * r2
		-- 3rd line offsets
		cccx = math.cos(math.rad(90 - r)) * 3 * r2
		cccy = math.sin(math.rad(90 - r)) * 3 * r2
	end
	local rollX = math.floor(hudPos.x + hudPos.width/2)
	--local delta = (hudPos.width - 76)
	drawCroppedLine(rollX + dx - cccx,dy + 32 + cccy,r,5,DOTTED,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
	drawCroppedLine(rollX + dx - ccx,dy + 32 + ccy,r,7,DOTTED,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
	drawCroppedLine(rollX + dx - cx,dy + 32 + cy,r,16,DOTTED,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
	drawCroppedLine(rollX + dx,dy + 32,r,54,SOLID,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
	drawCroppedLine(rollX + dx + cx,dy + 32 - cy,r,16,DOTTED,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
	drawCroppedLine(rollX + dx + ccx,dy + 32 - ccy,r,7,DOTTED,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
	drawCroppedLine(rollX + dx + cccx,dy + 32 - cccy,r,5,DOTTED,hudPos.x,hudPos.x + hudPos.width,yPos,bottomBarPos.y)
end

local function drawYaw()
	local hw = math.floor(hudPos.width/2)
  local ww = hw - 6
  local degL = 0
  local degR = 0
  local steps = 9
  local flags=INVERS
  local yawRounded = roundTo(yaw,10)
  local homeRounded = roundTo(homeAngle,10)
  local minY = topBarPos.y + topBarPos.height
  --
  local cx = hudPos.x + hw
  for step = 0,steps
  do
      --
      degR = (yawRounded + step*10) % 360
      degL = (yawRounded - step*10) % 360
      --
      if degR > 39 and degR < 47 then
        lcd.drawText(cx + step/steps*ww, minY+1, "NE", SMLSIZE)
      elseif degR > 89 and degR < 92 then
        lcd.drawText(cx + step/steps*ww, minY, "E", SMLSIZE+INVERS)
      elseif degR > 129 and degR < 132 then
        lcd.drawText(cx + step/steps*ww, minY+1, "SE", SMLSIZE)
      elseif degR > 179 and degR < 182 then
        lcd.drawText(cx + step/steps*ww, minY, "S", SMLSIZE+INVERS)
      elseif degR > 219 and degR < 227 then
        lcd.drawText(cx + step/steps*ww, minY+1, "SW", SMLSIZE)
      elseif degR > 269 and degR < 272 then
        lcd.drawText(cx + step/steps*ww, minY, "W", SMLSIZE+INVERS)
      elseif degR > 309 and degR < 317 then
        lcd.drawText(cx + step/steps*ww, minY+1, "NW", SMLSIZE)
      elseif degR > 359 or degR < 2 then
        lcd.drawText(cx + step/steps*ww, minY, "N", SMLSIZE+INVERS)
      end
      --    
      if degL > 39 and degL < 47 then
        lcd.drawText(cx - step/steps*ww - 6, minY+1, "NE", SMLSIZE)
      elseif degL > 89 and degL < 92 then
        lcd.drawText(cx - step/steps*ww - 4, minY, "E", SMLSIZE+INVERS)
      elseif degL > 129 and degL < 137 then
        lcd.drawText(cx - step/steps*ww - 6, minY+1, "SE", SMLSIZE)
      elseif degL > 179 and degL < 182 then
        lcd.drawText(cx - step/steps*ww - 4, minY, "S", SMLSIZE+INVERS)
      elseif degL > 219 and degL < 227 then
        lcd.drawText(cx - step/steps*ww - 6, minY+1, "SW", SMLSIZE)
      elseif degL > 269 and degL < 272 then
        lcd.drawText(cx - step/steps*ww - 4, minY, "W", SMLSIZE+INVERS)
      elseif degL > 309 and degL < 317 then
        lcd.drawText(cx - step/steps*ww - 6, minY+1, "NW", SMLSIZE)
      elseif degL > 359 or degL < 2 then
        lcd.drawText(cx - step/steps*ww - 4, minY, "N", SMLSIZE+INVERS)
      end
  
      
      if degR > homeRounded - 5 and degR < homeRounded + 5 and degL > homeRounded - 5  and degL < homeRounded + 5  then
        drawHomeMiniIcon(cx - 2,minY + 1 + 12)
      else
        if degR > homeRounded - 5 and degR < homeRounded + 5 then
          drawHomeMiniIcon(cx + step/steps*ww ,minY + 1 + 12)
        end

        if degL > homeRounded - 5  and degL < homeRounded + 5 then
          drawHomeMiniIcon(cx - step/steps*ww - 6,minY + 1 + 12)
        end
      end
  end
  --[[
  lcd.drawNumber(cx - 10,minY+20,yawRounded,0)
  lcd.drawNumber(cx - 10,minY+28,homeRounded,0)
  lcd.drawNumber(cx - 10,minY+36,yawRounded - homeRounded,0)
  
  local angle = yawRounded - homeRounded
  
  if angle > 90 and angle < 180 then
    drawHomeMiniIcon(cx - ww - 6,minY + 10 + 12)
  end
  ]]--
  
 	lcd.drawLine(hudPos.x, minY + 7, hudPos.x + hudPos.width - 1, minY + 7, SOLID, 0)
	local xx = 0
	if ( yaw < 10) then
		xx = 1
	elseif (yaw < 100) then
		xx = -2
	else
		xx = -5
	end
	lcd.drawRectangle(hudPos.x + hw - 6, minY, 12,12, SOLID)
	lcd.drawFilledRectangle(hudPos.x + hw - 6, minY, 12,12, SOLID)
  lcd.drawNumber(hudPos.x + hw + xx - 4, minY, yaw, MIDSIZE+INVERS)
end

local function clearHud()
	lcd.drawFilledRectangle(hudPos.x,topBarPos.y + topBarPos.height + 8,hudPos.width,49,ERASE,0)  
end

local function clearLeftPane()
  if radioModel == "x9" then
    lcd.drawFilledRectangle(0,topBarPos.y + topBarPos.height,hudPos.x - 1,49,ERASE,0)  
  end
end

local function clearRightPane()
  if radioModel == "x7" then
    lcd.drawFilledRectangle(hudPos.x+hudPos.width,topBarPos.y + topBarPos.height,128 - hudPos.x + hudPos.width,49,ERASE,0)
  else
    lcd.drawFilledRectangle(hudPos.x+hudPos.width,topBarPos.y + topBarPos.height,212 - hudPos.x + hudPos.width,49,ERASE,0)
  end
end


local function drawHud()
	drawRoll()
  drawPitch()
  if ekfFailsafe == 0 and battFailsafe == 0 then
    if (statusArmed == 1) then
      lcd.drawText(hudPos.x + hudPos.width/2 - 12, 49, "ARMED", SMLSIZE+INVERS)
    else
      lcd.drawText(hudPos.x + hudPos.width/2 - 18, 49, "DISARMED", SMLSIZE+INVERS+BLINK)
    end
  end
end

local function drawGrid()
	lcd.drawLine(hudPos.x - 1, 7 ,hudPos.x - 1, 57, SOLID, 0)
	lcd.drawLine(hudPos.x + hudPos.width, 7, hudPos.x + hudPos.width, 57, SOLID, 0)
end

local function drawHomeDirection()
	local ox = homeDirectionPos.x
	local oy = homeDirectionPos.y
	--
	local angle = math.floor(yaw - homeAngle)
	local r1 = homeDirectionPos.r
  lcd.drawFilledRectangle(ox - r1,oy - r1,2*r1,2*r1,ERASE,0)
  
	local x1 = ox + r1 * math.cos(math.rad(angle - 90)) 
	local y1 = oy + r1 * math.sin(math.rad(angle - 90))
	local x2 = ox + r1 * math.cos(math.rad(angle - 90 + 150)) 
	local y2 = oy + r1 * math.sin(math.rad(angle - 90 + 150))
	local x3 = ox + r1 * math.cos(math.rad(angle - 90 - 150)) 
	local y3 = oy + r1 * math.sin(math.rad(angle - 90 - 150))
	local x4 = ox + r1 * 0.5 * math.cos(math.rad(angle - 270)) 
	local y4 = oy + r1 * 0.5 *math.sin(math.rad(angle - 270))
	--
  lcd.drawLine(x1,y1,x2,y2,SOLID,1)
	lcd.drawLine(x1,y1,x3,y3,SOLID,1)
	lcd.drawLine(x2,y2,x4,y4,SOLID,1)
	lcd.drawLine(x3,y3,x4,y4,SOLID,1)
end

local function drawFlightTime()
	lcd.drawText(flightTimePos.x, flightTimePos.y, "T:", flightTimePos.flags)
	lcd.drawTimer(lcd.getLastRightPos(), flightTimePos.y, flightTime, flightTimePos.flags)
end

local function drawRSSI()
	local rssi = getRSSI()
  local label = "Rssi"
  if radioModel == "x7" then
    label = "RS:"
  end
	lcd.drawText(rssiPos.x, rssiPos.y, label, rssiPos.flags)
	lcd.drawText(lcd.getLastRightPos(), rssiPos.y, rssi, rssiPos.flags)
end

local function drawTxVoltage()
	local txVId=getFieldInfo("tx-voltage").id
	local txV = getValue(txVId)*10  

	lcd.drawText(txVoltagePos.x, txVoltagePos.y, "Tx", txVoltagePos.flags)
	lcd.drawNumber(lcd.getLastRightPos(), txVoltagePos.y, txV, txVoltagePos.flags+PREC1)
	lcd.drawText(lcd.getLastRightPos(), txVoltagePos.y, "v", txVoltagePos.flags)
end

local function drawCustomBoxes()
	if radio == "x7" then
		lcd.drawRectangle(box1Pos.x,box1Pos.y,box1Pos.width,box1Pos.height,SOLID)
		lcd.drawFilledRectangle(box1Pos.x,box1Pos.y,box1Pos.width,box1Pos.height,SOLID)
		--
		lcd.drawRectangle(box2Pos.x,box2Pos.y,box2Pos.width,box2Pos.height,SOLID)
		lcd.drawFilledRectangle(box2Pos.x,box2Pos.y,box2Pos.width,box2Pos.height,SOLID)
	end
end

local function checkSoundEvents()
	if (battCapacity > 0) then
		batLevel = (1 - (battMah/battCapacity))*100
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

	if flightMode ~= lastFlightMode then
		lastFlightMode = flightMode
		playSoundByFrameTypeAndFlightMode(frameType,flightMode)
	end
end

local function symMode()
	symAttitude()
	symTimer()
	symHome()
	symGPS()
	symBatt()
	symFrameType()
end

local function cycleBatterySource()
  if battSource == "vs" then
    battSource = "fc"
  elseif battSource == "fc" then
    battSource = "a2"
  elseif battSource == "a2" then
    battSource = "vs"
  end
end
--------------------------------------------------------------------------------
-- loop FUNCTIONS
--------------------------------------------------------------------------------
local showMessages = false
--
local function background()
	processTelemetry()
end
--
local clock = 0
--
local function run(event) 
	processTelemetry()
  --
	if event == EVT_PLUS_FIRST or event == EVT_MINUS_FIRST then
		showMessages = not showMessages
	end
	if showMessages then
    processTelemetry()
    lcd.clear()
		drawAllMessages()
	else
    lcd.clear()
    if event == EVT_ENTER_BREAK then
      cycleBatterySource()
    end
    if flagSim then
      symMode()
    end
    -- very slow loop
    if (clock % 8 == 0) then
      calcBattery()
      calcFlightTime()
      checkSoundEvents()
      checkLandingStatus()
      clock = 0
    end
    -- fast loop, telemetry and hud
		for r=1,4
		do
			processTelemetry()
      clearHud()
			drawHud()
    end
    -- slow loop
   	drawYaw()
    --
    clearLeftPane()
    clearRightPane()
    drawGrid()
		drawCustomBoxes()
    drawBottomBar()
    drawTopBar()
    drawCellVoltage()
    drawBatteryVoltage()
    drawBatteryCurrent()
    drawBatteryPerc()
    drawBatteryGauge()
    drawBatteryMah()
    drawAltAsl()
    drawMessage()
    drawHomeDirection()
    drawHomeDist()
    drawHSpeed()
    drawGPSStatus()
    drawFlightMode()
    drawFlightTime()
    drawTxVoltage()
    drawRSSI()
    drawFailsafe()
	end
	clock = clock + 1
end

local function init()
	pushMessage(6,"Yaapu X9D+ telemetry script v1.2.3")
  playSound("yaapu")
	--
	local ver, radio, maj, minor, rev = getVersion()
	if string.find(radio,"-simu") then
		flagSim = true
	end
	--
	if string.find(radio,"x9") then
		radio = "x9"
	elseif string.find(radio,"x7") then
		radio = "x7"
	end
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}