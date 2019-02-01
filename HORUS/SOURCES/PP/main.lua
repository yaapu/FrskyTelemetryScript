--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Horus X10 and X12 radios
--
-- Copyright (C) 2018. Alessandro Apostoli
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
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
-- Borrowed some code from the LI-xx BATTCHECK v3.30 script
--  http://frskytaranis.forumactif.org/t2800-lua-download-un-testeur-de-batterie-sur-la-radio

---------------------
-- script version 
---------------------

-- 480x272 LCD_WxLCD_H
--#define WIDGETDEBUG
--#define COMPILE
--#define SPLASH
--#define MEMDEBUG
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764
--#define LOAD_LUA
---------------------
-- features
---------------------
--#define HUD_ALGO1
--#define BATTPERC_BY_VOLTAGE
--#define COMPASS_ROSE
---------------------
-- dev features
---------------------
--#define LOGTELEMETRY
--#define DEBUG
--#define DEBUGEVT
--#define TESTMODE
--#define DEV
--#define DEBUGHUD

-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE

-- calc and show hud refresh rate
-- default for beta
--#define HUDRATE

--#define HUDTIMER

-- calc and show telemetry process rate
-- default for beta
--#define BGTELERATE

-- calc and show actual incoming telemetry rate
--#define TELERATE

--











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
]]
-------------------------------------
-- UNITS Scales from Ardupilot OSD code /ardupilot/libraries/AP_OSD/AP_OSD_Screen.cpp
-------------------------------------
--[[
    static const float scale_metric[UNIT_TYPE_LAST] = {
        1.0,       //ALTITUDE m
        3.6,       //SPEED km/hr
        1.0,       //VSPEED m/s
        1.0,       //DISTANCE m
        1.0/1000,  //DISTANCE_LONG km
        1.0,       //TEMPERATURE C
    };
    static const float scale_imperial[UNIT_TYPE_LAST] = {
        3.28084,     //ALTITUDE ft
        2.23694,     //SPEED mph
        3.28084,     //VSPEED ft/s
        3.28084,     //DISTANCE ft
        1.0/1609.34, //DISTANCE_LONG miles
        1.8,         //TEMPERATURE F
    };
    static const float scale_SI[UNIT_TYPE_LAST] = {
        1.0,       //ALTITUDE m
        1.0,       //SPEED m/s
        1.0,       //VSPEED m/s
        1.0,       //DISTANCE m
        1.0/1000,  //DISTANCE_LONG km
        1.0,       //TEMPERATURE C
    };
    static const float scale_aviation[UNIT_TYPE_LAST] = {
        3.28084,   //ALTITUDE Ft
        1.94384,   //SPEED Knots
        196.85,    //VSPEED ft/min
        3.28084,   //DISTANCE ft
        0.000539957,  //DISTANCE_LONG Nm
        1.0,       //TEMPERATURE C
    };
--]]local frameNames = {}
-- copter
frameNames[0]   = "GEN"
frameNames[2]   = "QUAD"
frameNames[3]   = "COAX"
frameNames[4]   = "HELI"
frameNames[13]  = "HEX"
frameNames[14]  = "OCTO"
frameNames[15]  = "TRI"
frameNames[29]  = "DODE"

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

-- rover
frameNames[10]  = "ROV"
-- boat
frameNames[11]  = "BOAT"

local currentModel = nil
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

-- rover
frameTypes[10]  = "r"
-- boat
frameTypes[11]  = "b"

-- flightmodes are loaded at run time
local soundFileBasePath = "/SOUNDS/yaapu0"
local gpsStatuses = {}

gpsStatuses[0]="NoGPS"
gpsStatuses[1]="NoLock"
gpsStatuses[2]="2D"
gpsStatuses[3]="3D"
gpsStatuses[4]="DGPS"
gpsStatuses[5]="RTK"
gpsStatuses[6]="RTK"

--[[
0	MAV_SEVERITY_EMERGENCY	System is unusable. This is a "panic" condition.
1	MAV_SEVERITY_ALERT	Action should be taken immediately. Indicates error in non-critical systems.
2	MAV_SEVERITY_CRITICAL	Action must be taken immediately. Indicates failure in a primary system.
3	MAV_SEVERITY_ERROR	Indicates an error in secondary/redundant systems.
4	MAV_SEVERITY_WARNING	Indicates about a possible future error if this is not resolved within a given timeframe. Example would be a low battery warning.
5	MAV_SEVERITY_NOTICE	An unusual event has occured, though not an error condition. This should be investigated for the root cause.
6	MAV_SEVERITY_INFO	Normal operational messages. Useful for logging. No action is required for these messages.
7	MAV_SEVERITY_DEBUG	Useful non-operational messages that can assist in debugging. These should not occur during normal operation.
--]]
local mavSeverity = {}
mavSeverity[0]="EMR"
mavSeverity[1]="ALR"
mavSeverity[2]="CRT"
mavSeverity[3]="ERR"
mavSeverity[4]="WRN"
mavSeverity[5]="NOT"
mavSeverity[6]="INF"
mavSeverity[7]="DBG"

--------------------------------
local status = {
  -- FLVSS 1
  cell1min = 0,
  cell1sum = 0,
  -- FLVSS 2
  cell2min = 0,
  cell2sum = 0,
  -- FC 1
  cell1sumFC = 0,
  -- used to calculate cellcount
  cell1maxFC = 0,
  -- FC 2
  cell2sumFC = 0,
  -- A2
  cellsumA2 = 0,
  -- used to calculate cellcount
  cellmaxA2 = 0,
  --------------------------------
  -- AP STATUS
  flightMode = 0,
  simpleMode = 0,
  landComplete = 0,
  statusArmed = 0,
  battFailsafe = 0,
  ekfFailsafe = 0,
  imuTemp = 0,
  -- GPS
  numSats = 0,
  gpsStatus = 0,
  gpsHdopC = 100,
  gpsAlt = 0,
  -- BATT
  cellcount = 0,
  battsource = "na",
  -- BATT 1
  batt1volt = 0,
  batt1current = 0,
  batt1mah = 0,
  batt1sources = {
    a2 = false,
    vs = false,
    fc = false
  },
  -- BATT 2
  batt2volt = 0,
  batt2current = 0,
  batt2mah = 0,
  batt2sources = {
    a2 = false,
    vs = false,
    fc = false
  },
  -- TELEMETRY
  noTelemetryData = 1,
  -- HOME
  homeDist = 0,
  homeAlt = 0,
  homeAngle = -1,
  -- MESSAGES
  msgBuffer = "",
  lastMsgValue = 0,
  lastMsgTime = 0,
  -- VELANDYAW
  vSpeed = 0,
  hSpeed = 0,
  yaw = 0,
  -- SYNTH VSPEED SUPPORT
  vspd = 0,
  synthVSpeedTime = 0,
  prevHomeAlt = 0,
  -- ROLLPITCH
  roll = 0,
  pitch = 0,
  range = 0,
  -- PARAMS
  frameType = -1,
  batt1Capacity = 0,
  batt2Capacity = 0,
  -- FLIGHT TIME
  lastTimerStart = 0,
  timerRunning = 0,
  flightTime = 0,
  -- EVENTS
  lastStatusArmed = 0,
  lastGpsStatus = 0,
  lastFlightMode = 0,
  lastSimpleMode = 0,
  -- battery levels
  batLevel = 99,
  battLevel1 = false,
  battLevel2 = false,
  lastBattLevel = 14,
  -- messages
  lastMessage = nil,
  lastMessageSeverity = 0,
  lastMessageCount = 1,
  messageCount = 0,
  messages = {}
}
local frame = {}
--
local backlightLastTime = 0
--
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
local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , true, 1 , 0, false, 0 }, --MAX_ALT
    { false, 0 , true, 1 , 0, false, 0 }, --MAX_DIST
    { false, 0 , true, 1 , 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1 , 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 4, 4, false, 0 } --BATT L2
}

--
local  paramId,paramValue
--
local batLevels = {0,5,10,15,20,25,30,40,50,60,70,80,90}
-- dual battery
local showDualBattery = false
--
local bitmaps = {}
local blinktime = getTime()
local blinkon = false
-- GPS
local function getTelemetryId(name)
  local field = getFieldInfo(name)
  return field and field.id or -1
end
--
local gpsDataId = getTelemetryId("GPS")
--
--
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
-- max
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

local showMinMaxValues = false
--

--



























-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
-----------------------------
-- clears the loaded table 
-- and recovers memory
-----------------------------
local function clearTable(t)
  if type(t)=="table" then
    for i,v in pairs(t) do
      if type(v) == "table" then
        clearTable(v)
      end
      t[i] = nil
    end
  end
  collectgarbage()
  maxmem = 0
end  
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
  maxDistanceAlert = 0,
  cellCount = 0,
  enableBattPercByVoltage = false,
  rangeMax=0,
  enableSynthVSpeed=false,
  horSpeedMultiplier=1,
  vertSpeedMultiplier=1
}
--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

  
local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}



-- max 4 extra sensors
local customSensors = {
    -- {label,name,prec:0,1,2,unit,stype:I,E,1}
}

local menuItems = {}
 -- label, type, alias, currval, min, max, label, flags, increment 
menuItems[1] = {"voice language:", 1, "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} }
menuItems[2] = {"batt alert level 1:", 0, "V1", 375, 0,5000,"V", PREC2 ,5 }
menuItems[3] = {"batt alert level 2:", 0, "V2", 350, 0,5000,"V", PREC2 ,5 }
menuItems[4] = {"batt[1] capacity override:", 0, "B1", 0, 0,5000,"Ah",PREC2 ,10 }
menuItems[5] = {"batt[2] capacity override:", 0, "B2", 0, 0,5000,"Ah",PREC2 ,10 }
menuItems[6] = {"disable all sounds:", 1, "S1", 1, { "no", "yes" }, { false, true } }
menuItems[7] = {"disable msg beep:", 1, "S2", 1, { "no", "yes" }, { false, true } }
menuItems[8] = {"disable msg blink:", 1, "S3", 1, { "no", "yes" }, { false, true } }
menuItems[9] = {"default voltage source:", 1, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } }
menuItems[10] = {"timer alert every:", 0, "T1", 0, 0,600,"min",PREC1,5 }
menuItems[11] = {"min altitude alert:", 0, "A1", 0, 0,500,"m",PREC1,5 }
menuItems[12] = {"max altitude alert:", 0, "A2", 0, 0,10000,"m",0,1 }
menuItems[13] = {"max distance alert:", 0, "D1", 0, 0,100000,"m",0,10 }
menuItems[14] = {"repeat alerts every:", 0, "T2", 10, 5,600,"sec",0,5 }
menuItems[15] = {"cell count override:", 0, "CC", 0, 0,12,"cells",0,1 }
menuItems[16] = {"rangefinder max:", 0, "RM", 0, 0,10000," cm",0,10 }
menuItems[17] = {"enable synthetic vspeed:", 1, "SVS", 1, { "no", "yes" }, { false, true } }
menuItems[18] = {"air/groundspeed unit:", 1, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} }
menuItems[19] = {"vertical speed unit:", 1, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} }
--


local unitScale, unitlabel



local currentPage = 0

local function getConfigFilename()
  local info = model.getInfo()
  return "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function getBitmap(name)
  if bitmaps[name] == nil then
    bitmaps[name] = Bitmap.open("/SCRIPTS/YAAPU/IMAGES/"..name..".png")
  end
  return bitmaps[name]
end

local function applyConfigValues()
  conf.language = menuItems[1][6][menuItems[1][4]]
  conf.battAlertLevel1 = menuItems[2][4]
  conf.battAlertLevel2 = menuItems[3][4]
  conf.battCapOverride1 = menuItems[4][4]*0.1
  conf.battCapOverride2 = menuItems[5][4]*0.1
  conf.disableAllSounds = menuItems[6][6][menuItems[6][4]]
  conf.disableMsgBeep = menuItems[7][6][menuItems[7][4]]
  conf.disableMsgBlink = menuItems[8][6][menuItems[8][4]]  
  conf.defaultBattSource = menuItems[9][6][menuItems[9][4]]
  conf.timerAlert = math.floor(menuItems[10][4]*0.1*60)
  conf.minAltitudeAlert = menuItems[11][4]*0.1
  conf.maxAltitudeAlert = menuItems[12][4]
  conf.maxDistanceAlert = menuItems[13][4]
  conf.cellCount = menuItems[15][4]
  conf.rangeMax = menuItems[16][4]
  conf.enableSynthVSpeed = menuItems[17][6][menuItems[17][4]]
  conf.horSpeedMultiplier = menuItems[18][6][menuItems[18][4]]
  conf.vertSpeedMultiplier = menuItems[19][6][menuItems[19][4]]
  --
  if conf.defaultBattSource ~= nil then
    status.battsource = conf.defaultBattSource
  end
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

--
local function lcdBacklightOn()
  model.setGlobalVariable(8,0,1)
  backlightLastTime = getTime()/100 -- seconds
end
--
local function playSound(soundFile)
  if conf.disableAllSounds then
    return
  end
  lcdBacklightOn()
  playFile(soundFileBasePath .."/"..conf.language.."/".. soundFile..".wav")
end

----------------------------------------------
-- sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
local function playSoundByFrameTypeAndFlightMode(flightMode)
  if conf.disableAllSounds then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      lcdBacklightOn()
      playFile(soundFileBasePath.."/"..conf.language.."/".. string.lower(frame.flightModes[flightMode])..".wav")
    end
  end
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
--
local function drawBlinkBitmap(bitmap,x,y)
  if blinkon == true then
      lcd.drawBitmap(getBitmap(bitmap),x,y)
  end
end
--
local function drawVArrow(x,y,h,top,bottom)
  if top == true then
    drawBlinkBitmap("uparrow",x,y)
  else
    drawBlinkBitmap("downarrow",x,y)
  end
end

local function drawHomeIcon(x,y)
  lcd.drawBitmap(getBitmap("minihomeorange"),x,y)
end

local function drawLine(x1,y1,x2,y2,flags1,flags2)
    -- if lines are hor or ver do not fix
--if string.find(radio, "x10") and rev < 2 and x1 ~= x2 and y1 ~= y2 then
    if string.find(radio, "x10") and rev < 2 then
      lcd.drawLine(LCD_W-x1,LCD_H-y1,LCD_W-x2,LCD_H-y2,flags1,flags2)
    else
      lcd.drawLine(x1,y1,x2,y2,flags1,flags2)
    end
end


local function computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = 0; --initialised as being inside of hud
    --
    if x < xmin then --to the left of hud
        code = bit32.bor(code,1);
    elseif x > xmax then --to the right of hud
        code = bit32.bor(code,2);
    end
    if y < ymin then --below the hud
        code = bit32.bor(code,4);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,8);
    end
    --
    return code;
end

-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function drawLineWithClipping(ox,oy,angle,len,style,xmin,xmax,ymin,ymax,color)
  --
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  --
  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy    
  -- compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
  local outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax);
  local outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax);
  local accept = false;

  while (true) do
    if ( bit32.bor(outcode0,outcode1) == 0) then
      -- bitwise OR is 0: both points inside window; trivially accept and exit loop
      accept = true;
      break;
    elseif (bit32.band(outcode0,outcode1) ~= 0) then
      -- bitwise AND is not 0: both points share an outside zone (LEFT, RIGHT, TOP, BOTTOM)
      -- both must be outside window; exit loop (accept is false)
      break;
    else
      -- failed both tests, so calculate the line segment to clip
      -- from an outside point to an intersection with clip edge
      local x = 0
      local y = 0
      -- At least one endpoint is outside the clip rectangle; pick it.
      local outcodeOut = outcode0 ~= 0 and outcode0 or outcode1
      -- No need to worry about divide-by-zero because, in each case, the
      -- outcode bit being tested guarantees the denominator is non-zero
      if bit32.band(outcodeOut,8) ~= 0 then --point is above the clip window
        x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
        y = ymax
      elseif bit32.band(outcodeOut,4) ~= 0 then --point is below the clip window
        x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
        y = ymin
      elseif bit32.band(outcodeOut,2) ~= 0 then --point is to the right of clip window
        y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
        x = xmax
      elseif bit32.band(outcodeOut,1) ~= 0 then --point is to the left of clip window
        y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
        x = xmin
      end
      -- Now we move outside point to intersection point to clip
      -- and get ready for next pass.
      if outcodeOut == outcode0 then
        x0 = x
        y0 = y
        outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax)
      else
        x1 = x
        y1 = y
        outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax)
      end
    end
  end
  if accept then
    drawLine(x0,y0,x1,y1, style,color)
  end
end


local function drawNumberWithTwoDims(x,y,xDim,yTop,yBottom,number,topDim,bottomDim,flags,topFlags,bottomFlags)
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  lcd.drawNumber(x, y, number + 0.5, flags)
  local lx = xDim
  lcd.drawText(lx, yTop, topDim, topFlags)
  lcd.drawText(lx, yBottom, bottomDim, bottomFlags)
end

local function drawNumberWithDim(x,y,xDim,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(xDim, yDim, dim, dimFlags)
end

--
--
local function formatMessage(severity,msg)
  if status.lastMessageCount > 1 then
    return string.format("%02d:%s (x%d) %s", status.messageCount, mavSeverity[severity], status.lastMessageCount, msg)
  else
    return string.format("%02d:%s %s", status.messageCount, mavSeverity[severity], msg)
  end
end

local function pushMessage(severity, msg)
  if  conf.disableMsgBeep == false and conf.disableAllSounds == false then
    if ( severity < 5) then
      playSound("../err")
    else
      playSound("../inf")
    end
  end
  -- check if wrapping is needed
  if #status.messages == 17 and msg ~= status.lastMessage then
    for i=1,17-1 do
      status.messages[i]=status.messages[i+1]
    end
    -- trunc at 9
    status.messages[17] = nil
  end
  -- is it a duplicate?
  if msg == status.lastMessage then
    status.lastMessageCount = status.lastMessageCount + 1
    status.messages[#status.messages] = formatMessage(severity,msg)
  else  
    status.lastMessageCount = 1
    status.messageCount = status.messageCount + 1
    status.messages[#status.messages+1] = formatMessage(severity,msg)
  end
  status.lastMessage = msg
  status.lastMessageSeverity = severity
end

--
local function startTimer()
  status.lastTimerStart = getTime()/100
  model.setTimer(2,{mode=1})
end

local function stopTimer()
  model.setTimer(2,{mode=0})
  status.lastTimerStart = 0
end


-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
--
local function processTelemetry()
  local SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
  if ( FRAME_ID == 0x10) then
    status.noTelemetryData = 0
    if ( DATA_ID == 0x5006) then -- ROLLPITCH
      -- roll [0,1800] ==> [-180,180]
      status.roll = (math.min(bit32.extract(VALUE,0,11),1800) - 900) * 0.2
      -- pitch [0,900] ==> [-90,90]
      status.pitch = (math.min(bit32.extract(VALUE,11,10),900) - 450) * 0.2
      -- #define ATTIANDRNG_RNGFND_OFFSET    21
      -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
      status.range = bit32.extract(VALUE,22,10) * (10^bit32.extract(VALUE,21,1)) -- cm
    elseif ( DATA_ID == 0x5005) then -- VELANDYAW
      status.vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1)) * (bit32.extract(VALUE,8,1) == 1 and -1 or 1)-- dm/s 
      status.hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1)) -- dm/s
      status.yaw = bit32.extract(VALUE,17,11) * 0.2
    elseif ( DATA_ID == 0x5001) then -- AP STATUS
      status.flightMode = bit32.extract(VALUE,0,5)
      status.simpleMode = bit32.extract(VALUE,5,2)
      status.landComplete = bit32.extract(VALUE,7,1)
      status.statusArmed = bit32.extract(VALUE,8,1)
      status.battFailsafe = bit32.extract(VALUE,9,1)
      status.ekfFailsafe = bit32.extract(VALUE,10,2)
      -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
      status.imuTemp = bit32.extract(VALUE,26,6) + 19 -- C° 
    elseif ( DATA_ID == 0x5002) then -- GPS STATUS
      status.numSats = bit32.extract(VALUE,0,4)
      -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
      -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
      status.gpsStatus = bit32.extract(VALUE,4,2) + bit32.extract(VALUE,14,2)
      status.gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
      status.gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1)-- dm
    elseif ( DATA_ID == 0x5003) then -- BATT
      status.batt1volt = bit32.extract(VALUE,0,9)
      status.batt1current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      status.batt1mah = bit32.extract(VALUE,17,15)
    elseif ( DATA_ID == 0x5008) then -- BATT2
      status.batt2volt = bit32.extract(VALUE,0,9)
      status.batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      status.batt2mah = bit32.extract(VALUE,17,15)
    elseif ( DATA_ID == 0x5004) then -- HOME
      status.homeDist = bit32.extract(VALUE,2,10) * (10^bit32.extract(VALUE,0,2))
      status.homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1 * (bit32.extract(VALUE,24,1) == 1 and -1 or 1)
      status.homeAngle = bit32.extract(VALUE, 25,  7) * 3
    elseif ( DATA_ID == 0x5000) then -- MESSAGES
      if (VALUE ~= status.lastMsgValue) then
        status.lastMsgValue = VALUE
        local c1 = bit32.extract(VALUE,0,7)
        local c2 = bit32.extract(VALUE,8,7)
        local c3 = bit32.extract(VALUE,16,7)
        local c4 = bit32.extract(VALUE,24,7)
        --
        local msgEnd = false
        --
        if (c4 ~= 0) then
          status.msgBuffer = status.msgBuffer .. string.char(c4)
        else
          msgEnd = true;
        end
        if (c3 ~= 0 and not msgEnd) then
          status.msgBuffer = status.msgBuffer .. string.char(c3)
        else
          msgEnd = true;
        end
        if (c2 ~= 0 and not msgEnd) then
          status.msgBuffer = status.msgBuffer .. string.char(c2)
        else
          msgEnd = true;
        end
        if (c1 ~= 0 and not msgEnd) then
          status.msgBuffer = status.msgBuffer .. string.char(c1)
        else
          msgEnd = true;
        end
        --_msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x4)<<21;
        --_msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x2)<<14;
        --_msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x1)<<7;
        if (msgEnd) then
          local severity = (bit32.extract(VALUE,7,1) * 1) + (bit32.extract(VALUE,15,1) * 2) + (bit32.extract(VALUE,23,1) * 4)
          pushMessage( severity, status.msgBuffer)
          status.msgBuffer = ""
        end
      end
    elseif ( DATA_ID == 0x5007) then -- PARAMS
      paramId = bit32.extract(VALUE,24,4)
      paramValue = bit32.extract(VALUE,0,24)
      if paramId == 1 then
        status.frameType = paramValue
      elseif paramId == 4 then
        status.batt1Capacity = paramValue
      elseif paramId == 5 then
        status.batt2Capacity = paramValue
      end 
    end
  end
end

local function telemetryEnabled()
  if getRSSI() == 0 then
    status.noTelemetryData = 1
  end
  return status.noTelemetryData == 0
end

local function getMaxValue(value,idx)
  minmaxValues[idx] = math.max(value,minmaxValues[idx])
  return showMinMaxValues == true and minmaxValues[idx] or value
end

local function calcMinValue(value,min)
  return min == 0 and value or math.min(value,min)
end

-- returns the actual minimun only if both are > 0
local function getNonZeroMin(v1,v2)
  return v1 == 0 and v2 or ( v2 == 0 and v1 or math.min(v1,v2))
end



local function calcCellCount()
  -- cellcount override from menu
  if conf.cellCount ~= nil and conf.cellCount > 0 then
    return conf.cellCount
  end
  -- cellcount is cached only for FLVSS
  if status.batt1sources.vs == true and status.cellcount > 1 then
    return status.cellcount
  end
  -- round in excess and return
  -- Note: cellcount is not cached because max voltage can rise during initialization)
  return math.floor( (( math.max(status.cell1maxFC,status.cellmaxA2)*0.1 ) / 4.35) + 1)
end

local function calcBattery()
  ------------
  -- FLVSS 1
  ------------
  local cellResult = getValue("Cels")
  if type(cellResult) == "table" then
    status.cell1min = 4.35
    status.cell1sum = 0
    -- cellcount is global and shared
    status.cellcount = #cellResult
    for i, v in pairs(cellResult) do
      status.cell1sum = status.cell1sum + v
      if status.cell1min > v then
        status.cell1min = v
      end
    end
    -- if connected after scritp started
    if status.batt1sources.vs == false then
      status.battsource = "na"
    end
    if status.battsource == "na" then
      status.battsource = "vs"
    end
    status.batt1sources.vs = true
  else
    status.batt1sources.vs = false
    status.cell1min = 0
    status.cell1sum = 0
  end
  ------------
  -- FLVSS 2
  ------------
  cellResult = getValue("Cel2")
  if type(cellResult) == "table" then
    status.cell2min = 4.35
    status.cell2sum = 0
    -- cellcount is global and shared
    status.cellcount = #cellResult
    for i, v in pairs(cellResult) do
      status.cell2sum = status.cell2sum + v
      if status.cell2min > v then
        status.cell2min = v
      end
    end
    -- if connected after scritp started
    if status.batt2sources.vs == false then
      status.battsource = "na"
    end
    if status.battsource == "na" then
      status.battsource = "vs"
    end
    status.batt2sources.vs = true
  else
    status.batt2sources.vs = false
    status.cell2min = 0
    status.cell2sum = 0
  end
  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if status.batt1volt > 0 then
    status.cell1sumFC = status.batt1volt*0.1
    status.cell1maxFC = math.max(status.batt1volt,status.cell1maxFC)
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    status.batt1sources.fc = true
  else
    status.batt1sources.fc = false
    status.cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if status.batt2volt > 0 then
    status.cell2sumFC = status.batt2volt*0.1
    if status.battsource == "na" then
      status.battsource = "fc"
    end
    status.batt2sources.fc = true
  else
    status.batt2sources.fc = false
    status.cell2sumFC = 0
  end
  ----------------------------------
  -- 12 analog voltage only 1 supported
  ----------------------------------
  local battA2 = getValue("A2")
  --
  if battA2 > 0 then
    status.cellsumA2 = battA2
    status.cellmaxA2 = math.max(battA2*10,status.cellmaxA2)
    status.batt1sources.a2 = true
  else
    status.batt1sources.a2 = false
    status.cellsumA2 = 0
  end
  -- batt fc
  minmaxValues[1] = calcMinValue(status.cell1sumFC,minmaxValues[1])
  minmaxValues[2] = calcMinValue(status.cell2sumFC,minmaxValues[2])
  -- cell flvss
  minmaxValues[3] = calcMinValue(status.cell1min,minmaxValues[3])
  minmaxValues[4] = calcMinValue(status.cell2min,minmaxValues[4])
  -- batt flvss
  minmaxValues[5] = calcMinValue(status.cell1sum,minmaxValues[5])
  minmaxValues[6] = calcMinValue(status.cell2sum,minmaxValues[6])
  -- batt 12
  minmaxValues[7] = calcMinValue(status.cellsumA2,minmaxValues[7])
end

local function checkLandingStatus()
  if ( status.timerRunning == 0 and status.landComplete == 1 and status.lastTimerStart == 0) then
    startTimer()
  end
  if (status.timerRunning == 1 and status.landComplete == 0 and status.lastTimerStart ~= 0) then
    stopTimer()
    if status.statusArmed == 1 then
      playSound("landing")
    end
  end
  status.timerRunning = status.landComplete
end

local initLib = {}
local initFile = "/SCRIPTS/YAAPU/LIB/init.luac"

local function reset()
  -- initialize status
  if initLib.resetWidget == nil then
    initLib = dofile(initFile)
  end
  -- reset frame
  clearTable(frame.frameTypes)
  -- reset widget pages
  currentPage = 0
  showMinMaxValues = false
  showDualBattery = false
  --
  frame = {}
  -- reset all
  initLib.resetTelemetry(status,alarms,pushMessage,clearTable)
  -- release resources
  clearTable(initLib)
  -- load model config
  loadConfig()
  -- done
  playSound("yaapu")
end

local function calcFlightTime()
  -- update local variable with timer 3 value
  if ( model.getTimer(2).value < status.flightTime and status.statusArmed == 0) then
    reset()
  end
  if (model.getTimer(2).value < status.flightTime and status.statusArmed == 1) then
    model.setTimer(2,{value=status.flightTime})
    pushMessage(3,"timer reset ignored while armed")
  end
  status.flightTime = model.getTimer(2).value
end

local function getBatt1Capacity()
  return conf.battCapOverride1 > 0 and conf.battCapOverride1*100 or status.batt1Capacity
end

local function getBatt2Capacity()
  return conf.battCapOverride2 > 0 and conf.battCapOverride2*100 or status.batt2Capacity
end

-- gets the voltage based on source and min value, battId = [1|2]
local function getMinVoltageBySource(source,cell,cellFC,cellA2,battId,count)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > 4.35*2 or cellFC > 4.35*2 or cellA2 > 4.35*2 then
    offset = 2
  end
  --
  if source == "vs" then
    return showMinMaxValues == true and minmaxValues[2+offset+battId] or cell
  elseif source == "fc" then
      -- FC only tracks batt1 and batt2 no cell voltage tracking
      local minmax = (offset == 2 and minmaxValues[battId] or minmaxValues[battId]/count)
      return showMinMaxValues == true and minmax or cellFC
  elseif source == "a2" then
      -- 12 does not depend on battery id
      local minmax = (offset == 2 and minmaxValues[7] or minmaxValues[7]/count)
      return showMinMaxValues == true and minmax or cellA2
  end
  --
  return 0
end

local sensors = {
  {0x060F, 0, 0,0, 13 , 0 , "Fuel" },
  {0x021F, 0, 0,0, 1 , 2 , "VFAS"},
  {0x020F, 0, 0,0, 2 , 1 , "CURR"},
  {0x011F, 0, 0,0, 5 , 1 , "VSpd"},
  {0x083F, 0, 0,0, 5 , 0 , "GSpd"},
  {0x010F, 0, 0,0, 9 , 1 , "Alt"},
  {0x082F, 0, 0,0, 9 , 0 , "GAlt"},
  {0x084F, 0, 0,0, 20 , 0 , "Hdg"},
  {0x041F, 0, 0,0, 11 , 0 , "IMUt"},
  {0x060F, 0, 1,0, 0 , 0 , "ARM"}
}

local function setSensorValues()
  if (not telemetryEnabled()) then
    return
  end
  local battmah = status.batt1mah
  local battcapacity = getBatt1Capacity()
  if status.batt2mah > 0 then
    battcapacity =  getBatt1Capacity() + getBatt2Capacity()
    battmah = status.batt1mah + status.batt2mah
  end
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    elseif perc < 0 then
      perc = 0
    end  
  end
  --
  sensors[1][4] = perc;
  sensors[2][4] = getNonZeroMin(status.batt1volt,status.batt2volt)*10;
  sensors[3][4] = status.batt1current+status.batt2current;
  sensors[4][4] = status.vSpeed;
  sensors[5][4] = status.hSpeed*0.1;
  sensors[6][4] = status.homeAlt*10;
  sensors[7][4] = math.floor(status.gpsAlt*0.1);
  sensors[8][4] = math.floor(status.yaw);
  sensors[9][4] = status.imuTemp;
  sensors[10][4] = status.statusArmed*100;
  --
  for s=1,#sensors
  do
    setTelemetryValue(sensors[s][1], sensors[s][2], sensors[s][3], sensors[s][4], sensors[s][5] , sensors[s][6] , sensors[s][7])
  end
end

--------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawBatteryPane(x,battVolt,cellVolt,current,battmah,battcapacity)
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    elseif perc < 0 then
      perc = 0
    end
  end
  --  battery min cell
  local flags = 0
  --
  if showMinMaxValues == false then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255)) -- white
    if status.battLevel2 == false and alarms[8][2] > 0 then
      drawBlinkBitmap("cell_red",x+33 - 4,13 + 8)
      lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(getBitmap("cell_red"),x+33 - 4,13 + 8)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      drawBlinkBitmap("cell_orange",x+33 - 4,13 + 8)
      lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(getBitmap("cell_orange"),x+33 - 4,13 + 8)
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 0, 0)) -- black
    end
      flags = CUSTOM_COLOR
  end
  drawNumberWithTwoDims(x+33, 13,x+171, 23, 60,cellVolt,"V",status.battsource,XXLSIZE+PREC2+flags,flags,flags)
  -- battery voltage
  drawNumberWithDim(x+100,164,x+95, 159, battVolt,"V",DBLSIZE+PREC1+RIGHT,SMLSIZE)
  -- battery current
  drawNumberWithDim(x+192,164,x+186,159,current,"A",DBLSIZE+PREC1+RIGHT,SMLSIZE)
  -- display capacity bar %
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawBitmap(getBitmap("gauge_bg"),x+29-2,109-2)
  lcd.drawGauge(x+29, 109,160,23,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 0, 0)) -- black
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+90, 108, strperc, MIDSIZE+CUSTOM_COLOR)
  -- battery mah
  local strmah = string.format("%.02f/%.01f",battmah/1000,battcapacity/1000)
  lcd.drawText(x+185, 136+6, "Ah", RIGHT)
  lcd.drawText(x+185 - 22, 136, strmah, MIDSIZE+RIGHT)
  if showMinMaxValues == true then
    drawVArrow(x+33+140, 13 + 27,6,false,true)
    drawVArrow(x+100-2,164 + 10, 5,false,true)
    drawVArrow(x+192-5,164 + 10,5,true,false)
  end
end

local function drawNoTelemetryData()
  -- no telemetry data
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle(75,90, 330, 100, TITLE_BGCOLOR)
    lcd.drawText(140, 120, "no telemetry data", MIDSIZE+INVERS)
    lcd.drawText(130, 160, "Yaapu Telemetry Script 1.7.4", SMLSIZE+INVERS)
  end
end

local function drawFlightMode()
  -- flight mode
  if frame.flightModes then
    local strMode = frame.flightModes[status.flightMode]
    if strMode ~= nil then
      if ( status.simpleMode > 0 ) then
        local strSimpleMode = status.simpleMode == 1 and "(S)" or "(SS)"
        strMode = string.format("%s%s",strMode,strSimpleMode)
      end
      lcd.drawText(2 + 2, 218, strMode, MIDSIZE)
    end
  end
  lcd.drawLine(2 + 2,218, 2 + 150,218, SOLID,0)
  lcd.drawText(2 + 2,218 - 16,"Flight Mode",SMLSIZE)
end

local function drawTopBar()
  -- black bar
  lcd.drawFilledRectangle(0,0, LCD_W, 20, TITLE_BGCOLOR)
  -- frametype and model name
  local info = model.getInfo()
  -- model change event
  if currentModel ~= info.name then
    currentModel = info.name
    reset()
  end
  local fn = frameNames[status.frameType]
  local strmodel = info.name
  if fn ~= nil then
    strmodel = fn..": "..info.name
  end
  lcd.drawText(2, 0, strmodel, MENU_TITLE_COLOR)
  -- flight time
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, 0+4, strtime, SMLSIZE+RIGHT+MENU_TITLE_COLOR)
  -- RSSI
  lcd.drawText(265, 0, "RS:", 0 +MENU_TITLE_COLOR)
  lcd.drawText(265 + 30,0, getRSSI(), 0 +MENU_TITLE_COLOR)  
  -- tx voltage
  local vtx = string.format("Tx:%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(330,0, vtx, 0+MENU_TITLE_COLOR)
end

local function drawFlightTime()
  -- flight time
  lcd.drawText(330, 202, "Flight Time", SMLSIZE)
  lcd.drawLine(330,202 + 16, 330 + 140,202 + 16, SOLID,0)
  lcd.drawTimer(330, 202 + 14, model.getTimer(2).value, DBLSIZE)
end

local function drawScreenTitle(title,page, pages)
  lcd.drawFilledRectangle(0, 0, LCD_W, 30, TITLE_BGCOLOR)
  lcd.drawText(1, 5, title, MENU_TITLE_COLOR)
  lcd.drawText(LCD_W-40, 5, page.."/"..pages, MENU_TITLE_COLOR)
end

local function drawBottomBar()
  -- black bar
  lcd.drawFilledRectangle(0,LCD_H - 20, LCD_W, 20, TITLE_BGCOLOR)
  -- message text
  local now = getTime()
  local msg = status.messages[#status.messages]
  if (now - status.lastMsgTime ) > 150 or conf.disableMsgBlink then
    lcd.drawText(2, LCD_H - 20 + 1, msg,MENU_TITLE_COLOR)
  else
    lcd.drawText(2, LCD_H - 20 + 1, msg,INVERS+BLINK+MENU_TITLE_COLOR)
  end
end

local function drawAllMessages()
  for i=1,#status.messages do
    lcd.drawText(1,16*(i-1), status.messages[i],SMLSIZE)
  end
end

local function drawGPSStatus()
  -- gps status
  local strStatus = gpsStatuses[status.gpsStatus]
  local flags = BLINK
  local mult = 1
  local gpsData = nil
  local hdop = status.gpsHdopC
  if status.gpsStatus  > 2 then
    if status.homeAngle ~= -1 then
      flags = PREC1
    end
    if hdop > 999 then
      hdop = 999
      flags = 0
      mult=0.1
    elseif hdop > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(2 -1,22 - 3, strStatus, SMLSIZE)
    lcd.drawText(2 -1,22 + 16 - 3, "fix", 0)
    if status.numSats == 15 then
      lcd.drawNumber(2 + 80, 22 + 4 , status.numSats, DBLSIZE+RIGHT)
      lcd.drawText(2 + 89, 22 + 19, "+", RIGHT)
    else
      lcd.drawNumber(2 + 87, 22 + 4 , status.numSats, DBLSIZE+RIGHT)
    end
    --
    lcd.drawText(2 + 94, 22-3, "hd", SMLSIZE)
    lcd.drawNumber(2 + 166, 22 + 4, hdop*mult , DBLSIZE+flags+RIGHT)
    --
    lcd.drawLine(2 + 91,22 ,2+91,22 + 36,SOLID,0)
    --
    gpsData = getValue("GPS")
    --
    if type(gpsData) == "table" and gpsData.lat ~= nil and gpsData.lon ~= nil then
      lcd.drawText(2 ,22 + 38,math.floor(gpsData.lat * 100000) / 100000,SMLSIZE)
      lcd.drawText(165 ,22 + 38,math.floor(gpsData.lon * 100000) / 100000,SMLSIZE+RIGHT)
    end
    lcd.drawLine(2 ,22 + 37,2+160,22 + 37,SOLID,0)
    lcd.drawLine(2 ,22 + 54,2+160,22 + 54,SOLID,0)
  elseif status.gpsStatus == 0 then
    drawBlinkBitmap("nogpsicon",4,24)
  else
    drawBlinkBitmap("nolockicon",4,24)
  end  
end

local function drawLeftPane(battcurrent,cellsumFC)
  if conf.rangeMax > 0 then
    flags = 0
    local rng = status.range
    if rng > conf.rangeMax then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,17)
    if showMinMaxValues == true then
      flags = 0
    end
    lcd.drawText(10, 95, "Range("..unitLabel..")", SMLSIZE)
    lcd.drawText(75, 112, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+flags+RIGHT)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = status.gpsAlt/10
    if status.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,13)
    end
    if showMinMaxValues == true then
      flags = 0
    end
    lcd.drawText(10, 95, "AltAsl("..unitLabel..")", SMLSIZE)
    local stralt = string.format("%d",alt*unitScale)
    lcd.drawText(75, 112, stralt, MIDSIZE+flags+RIGHT)
  end
  -- home distance
  drawHomeIcon(91,95,7)
  lcd.drawText(165, 95, "Dist("..unitLabel..")", SMLSIZE+RIGHT)
  flags = 0
  if status.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(status.homeDist,16)
  if showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*unitScale)
  lcd.drawText(165, 112, strdist, MIDSIZE+flags+RIGHT)
  -- hspeed
  local speed = getMaxValue(status.hSpeed,15)
  lcd.drawText(81, 152, "Spd("..menuItems[18][5][menuItems[18][4]]..")", SMLSIZE+RIGHT)
  lcd.drawNumber(80,170,speed * menuItems[18][6][menuItems[18][4]],MIDSIZE+RIGHT+PREC1)
  -- power
  --[[
  local power = cellsumFC*battcurrent*0.1
  power = getMaxValue(power,MAX_POWER)
  lcd.drawText(BATTPOWER_X, BATTPOWER_Y, "Power(W)", BATTPOWER_FLAGS+RIGHT)
  lcd.drawNumber(BATTPOWER_X,BATTPOWER_YW,power,BATTPOWER_FLAGSW+RIGHT)
  --]]  --
  local eff = speed > 2 and battcurrent*1000/(speed*menuItems[18][6][menuItems[18][4]]) or 0
  lcd.drawText(165, 152, "Eff(mAh)", SMLSIZE+RIGHT)
  lcd.drawNumber(165,170,eff,MIDSIZE+RIGHT)
  --
  if showMinMaxValues == true then
    drawVArrow(75-81, 112,6,true,false)
    drawVArrow(165-78, 112 ,6,true,false)
    drawVArrow(55-60,170,6,true,false)
    drawVArrow(165-78, 170, 5,true,false)
  end
end

local function drawFailsafe()
  if status.ekfFailsafe > 0 then
    drawBlinkBitmap("ekffailsafe",LCD_W/2 - 90,180)
  end
  if status.battFailsafe > 0 then
    drawBlinkBitmap("battfailsafe",LCD_W/2 - 90,180)
  end
end

local function drawArmStatus()
  -- armstatus
  if status.ekfFailsafe == 0 and status.battFailsafe == 0 and status.timerRunning == 0 then
    if (status.statusArmed == 1) then
      lcd.drawBitmap(getBitmap("armed"),LCD_W/2 - 90,180)
    else
      drawBlinkBitmap("disarmed",LCD_W/2 - 90,180)
    end
  end
end

-- vertical distance between roll horiz segments


local yawRibbonPoints = {}
--
yawRibbonPoints[0]={"N",2}
yawRibbonPoints[1]={"NE",-5}
yawRibbonPoints[2]={"E",2}
yawRibbonPoints[3]={"SE",-5}
yawRibbonPoints[4]={"S",2}
yawRibbonPoints[5]={"SW",-5}
yawRibbonPoints[6]={"W",2}
yawRibbonPoints[7]={"NW",-5}

-- optimized yaw ribbon drawing
local function drawCompassRibbon()
  -- ribbon centered +/- 90 on yaw
  local centerYaw = (status.yaw+270)%360
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = math.floor(centerYaw/45) * 45
  -- distance in degrees between leftmost ribbon point and first 45° multiple normalized to 120/8
  local yawMinX = (LCD_W - 120)/2
  local yawMaxX = (LCD_W + 120)/2
  -- x coord of first ribbon letter
  local nextPointX = yawMinX + (nextPoint - centerYaw)/45 * 28
  local yawY = 140
  --
  local i = (nextPoint / 45) % 8
  for idx=1,6
  do
      if nextPointX >= yawMinX - 3 and nextPointX < yawMaxX then
        lcd.drawText(nextPointX+yawRibbonPoints[i][2],yawY,yawRibbonPoints[i][1],SMLSIZE)
      end
      i = (i + 1) % 8
      nextPointX = nextPointX + 28
  end
  -- home icon
  local leftYaw = (status.yaw + 180)%360
  local rightYaw = status.yaw%360
  local centerHome = (status.homeAngle+270)%360
  --
  local homeIconX = yawMinX
  local homeIconY = yawY + 25
  if rightYaw >= leftYaw then
    if centerHome > leftYaw and centerHome < rightYaw then
      drawHomeIcon(yawMinX + ((centerHome - leftYaw)/180)*120 - 5,homeIconY)
    end
  else
    if centerHome < rightYaw then
      drawHomeIcon(yawMinX + (((360-leftYaw) + centerHome)/180)*120 - 5,homeIconY)
    elseif centerHome >= leftYaw then
      drawHomeIcon(yawMinX + ((centerHome-leftYaw)/180)*120 - 5,homeIconY)
    end
  end
  -- when abs(home angle) > 90 draw home icon close to left/right border
  local angle = status.homeAngle - status.yaw
  local cos = math.cos(math.rad(angle - 90))    
  local sin = math.sin(math.rad(angle - 90))    
  if cos > 0 and sin > 0 then
    drawHomeIcon(yawMaxX - 5, homeIconY)
  elseif cos < 0 and sin > 0 then
    drawHomeIcon(yawMinX - 5, homeIconY)
  end
  --
  lcd.drawLine(yawMinX, yawY + 16, yawMaxX, yawY + 16, SOLID, 0)
  local xx = 0
  if ( status.yaw < 10) then
    xx = 0
  elseif (status.yaw < 100) then
    xx = -8
  else
    xx = -14
  end
  lcd.drawNumber(LCD_W/2 + xx - 6, yawY, status.yaw, MIDSIZE+INVERS)
end





local function fillTriangle(ox, oy, x1, x2, roll, angle,color)
  local step = 2
  --
  local y1 = (oy - ox*angle) + x1*angle
  local y2 = (oy - ox*angle) + x2*angle
  --
  local steps = math.abs(y2-y1) / step
  --
  if (0 < roll and roll <= 90) then
    for s=0,steps
    do
      yy = y1 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(x1,yy,xx - x1,step,color)
    end
  elseif (90 < roll and roll <= 180) then
    for s=0,steps
    do
      yy = y2 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(x1,yy,xx - x1,step,color)
    end
  elseif (-90 < roll and roll < 0) then
    for s=0,steps
    do
      yy = y2 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(xx,yy,x2-xx+1,step,color)
    end
  elseif (-180 < roll and roll <= -90) then
    for s=0,steps
    do
      yy = y1 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(xx,yy,x2-xx+1,step,color)
    end
  end
end

-------------------------------------------

local function drawHud(myWidget)

  local r = -status.roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = 0 + 20 + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 10
  if ( status.roll == 0) then
    dx=0
    dy=status.pitch
    cx=0
    cy=10
    ccx=0
    ccy=2*10
    cccx=0
    cccy=3*10
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -status.pitch
    dy = math.sin(math.rad(90 - r)) * status.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 10
    cy = math.sin(math.rad(90 - r)) * 10
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * 10
    ccy = math.sin(math.rad(90 - r)) * 2 * 10
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * 10
    cccy = math.sin(math.rad(90 - r)) * 3 * 10
  end
  local rollX = math.floor((LCD_W-92)/2 + 92/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 90x70
  local minY = 44
  local maxY = 114
  local minX = (LCD_W-92)/2 + 1
  local maxX = (LCD_W-92)/2 + 92
  --
  local ox = (LCD_W-92)/2 + 92/2 + dx
  --
  local oy = 79 + dy
  local yy = 0
  
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(179, 204, 255))
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7a, 0x9c, 0xff))
  
  lcd.drawFilledRectangle(minX,minY,92,maxY - minY,CUSTOM_COLOR)
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-status.roll))
  -- for each pixel of the hud base/top draw vertical black 
  -- lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(77, 153, 0))
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(102, 51, 0))
  --
  --
  local minxY = (oy - ox * angle) + minX * angle;
  local maxxY = (oy - ox * angle) + maxX * angle;
  local maxyX = (maxY - (oy - ox * angle)) / angle;
  local minyX = (minY - (oy - ox * angle)) / angle;
  --        
  if ( 0 <= -status.roll and -status.roll <= 90 ) then
      if (minxY > minY and maxxY < maxY) then
        -- 5
        lcd.drawFilledRectangle(minX, maxxY, maxX - minX, maxY - maxxY,CUSTOM_COLOR)
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle, CUSTOM_COLOR)
      elseif (minxY < minY and maxxY < maxY and maxxY > minY) then
        -- 6
        lcd.drawFilledRectangle(minX, minY, minyX - minX, maxxY - minY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(minX, maxxY, maxX - minX, maxY - maxxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle, CUSTOM_COLOR)
      elseif (minxY < minY and maxxY > maxY) then
        -- 7
        lcd.drawFilledRectangle(minX, minY, minyX - minX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle, CUSTOM_COLOR)
      elseif (minxY < maxY and minxY > minY) then
        -- 8
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle, CUSTOM_COLOR)
      elseif (minxY < minY and maxxY < minY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
  elseif (90 < -status.roll and -status.roll <= 180) then
      if (minxY < maxY and maxxY > minY) then
        -- 9
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY > minY and maxxY < maxY) then
        -- 10
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxxY - minY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(minX, maxxY, maxyX - minX, maxY - maxxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxyX < maxX) then
        -- 11
        lcd.drawFilledRectangle(minX, minY, maxyX - minX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY < maxY and minxY > minY) then
        -- 12
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY > maxY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
      -- 9,10,11,12
  elseif (-90 < -status.roll and -status.roll < 0) then
      if (minxY < maxY and maxxY > minY) then
        -- 1
        lcd.drawFilledRectangle(minX, minxY, maxX - minX, maxY - minxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY < maxY and maxxY < minY and minxY > minY) then
        -- 2
        lcd.drawFilledRectangle(minX, minxY, maxX - minX, maxY - minxY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(minyX, minY, maxX - minyX, minxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY < minY) then
        -- 3
        lcd.drawFilledRectangle(minyX, minY, maxX - minyX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY > minY and maxxY < maxY) then
        -- 4
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY < minY and maxxY < minY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
  elseif (-180 <= -status.roll and -status.roll <= -90) then
      if (minxY > minY and maxxY < maxY) then
        -- 13
        lcd.drawFilledRectangle(minX, minY, maxX - minX, minxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (maxxY > maxY and minxY > minY and minxY < maxY) then
        -- 14
        lcd.drawFilledRectangle(minX, minY, maxX - minX, minxY - minY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(maxyX, minxY, maxX - maxyX, maxY - minxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY < minY and maxyX < maxX) then
        -- 15
        lcd.drawFilledRectangle(maxyX, minY, maxX - maxyX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY < minY and maxxY > minY) then
        -- 16
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -status.roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY > minY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
  end
  -- parallel lines above and below horizon
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255))
  --
  drawLineWithClipping(rollX + dx - cccx,dy + 79 + cccy,r,40,DOTTED,(LCD_W-92)/2,(LCD_W-92)/2 + 92,minY,maxY,CUSTOM_COLOR)
  drawLineWithClipping(rollX + dx - ccx,dy + 79 + ccy,r,20,DOTTED,(LCD_W-92)/2,(LCD_W-92)/2 + 92,minY,maxY,CUSTOM_COLOR)
  drawLineWithClipping(rollX + dx - cx,dy + 79 + cy,r,40,DOTTED,(LCD_W-92)/2,(LCD_W-92)/2 + 92,minY,maxY,CUSTOM_COLOR)
  drawLineWithClipping(rollX + dx + cx,dy + 79 - cy,r,40,DOTTED,(LCD_W-92)/2,(LCD_W-92)/2 + 92,minY,maxY,CUSTOM_COLOR)
  drawLineWithClipping(rollX + dx + ccx,dy + 79 - ccy,r,20,DOTTED,(LCD_W-92)/2,(LCD_W-92)/2 + 92,minY,maxY,CUSTOM_COLOR)
  drawLineWithClipping(rollX + dx + cccx,dy + 79 - cccy,r,40,DOTTED,(LCD_W-92)/2,(LCD_W-92)/2 + 92,minY,maxY,CUSTOM_COLOR)
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(getBitmap("hud_90x70a"),(LCD_W-106)/2,34) --106x90
  ------------------------------------
  -- synthetic vSpeed based on 
  -- home altitude when EKF is disabled
  -- updated at 1Hz (i.e every 1000ms)
  -------------------------------------
  if conf.enableSynthVSpeed == true then
    if (status.synthVSpeedTime == 0) then
      -- first time do nothing
      status.synthVSpeedTime = getTime()
      status.prevHomeAlt = status.homeAlt -- dm
    elseif (getTime() - status.synthVSpeedTime > 100) then
      -- calc vspeed
      status.vspd = 1000*(status.homeAlt-status.prevHomeAlt)/(getTime()-status.synthVSpeedTime) -- m/s
      -- update counters
      status.synthVSpeedTime = getTime()
      status.prevHomeAlt = status.homeAlt -- m
    end
  else
    status.vspd = status.vSpeed
  end

  -------------------------------------
  -- vario bitmap
  -------------------------------------
  local varioMax = math.log(5)
  local varioSpeed = math.log(1 + math.min(math.abs(0.05*status.vspd),4))
  local varioH = 0
  if status.vspd > 0 then
    varioY = math.min(79 - varioSpeed/varioMax*55,125)
  else
    varioY = 78
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0))
  lcd.drawFilledRectangle(172+2, varioY, 7, varioSpeed/varioMax*55, CUSTOM_COLOR, 0)  
  lcd.drawBitmap(getBitmap("variogauge_big"),172,19)
  if status.vSpeed > 0 then
    lcd.drawBitmap(getBitmap("varioline"),172-3,varioY)
  else
    lcd.drawBitmap(getBitmap("varioline"),172-3,77 + varioSpeed/varioMax*55)
  end
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255))
  -- altitude
  local alt = getMaxValue(status.homeAlt,12) * unitScale
  lcd.drawText(275,LCD_H-37,"alt("..unitLabel..")",SMLSIZE)
  if math.abs(alt) >= 10 then
    lcd.drawNumber(310,LCD_H-60,alt,MIDSIZE+RIGHT)
  else
    lcd.drawNumber(310,LCD_H-60,alt*10,MIDSIZE+RIGHT+PREC1)
  end
  -- vertical speed
  local vspd = status.vspd * 0.1 * menuItems[19][6][menuItems[19][4]]
  lcd.drawText(170,LCD_H-37,"vspd("..menuItems[19][5][menuItems[19][4]]..")",SMLSIZE)
  if (math.abs(vspd) >= 10) then
    lcd.drawNumber(180,LCD_H-60, vspd ,MIDSIZE)
  else
    lcd.drawNumber(180,LCD_H-60,vspd*10,MIDSIZE+PREC1)
  end
  -- min/max arrows
  if showMinMaxValues == true then
    drawVArrow(310+3, LCD_H-60 + 2,6,true,false)
  end
end

local function drawHomeDirection()
  local angle = math.floor(status.homeAngle - status.yaw)
  local x1 = (LCD_W/2) + 17 * math.cos(math.rad(angle - 90))
  local y1 = 202 + 17 * math.sin(math.rad(angle - 90))
  local x2 = (LCD_W/2) + 17 * math.cos(math.rad(angle - 90 + 150))
  local y2 = 202 + 17 * math.sin(math.rad(angle - 90 + 150))
  local x3 = (LCD_W/2) + 17 * math.cos(math.rad(angle - 90 - 150))
  local y3 = 202 + 17 * math.sin(math.rad(angle - 90 - 150))
  local x4 = (LCD_W/2) + 17 * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = 202 + 17 * 0.5 *math.sin(math.rad(angle - 270))
  --
  drawLine(x1,y1,x2,y2,SOLID,1)
  drawLine(x1,y1,x3,y3,SOLID,1)
  drawLine(x2,y2,x4,y4,SOLID,1)
  drawLine(x3,y3,x4,y4,SOLID,1)
end

---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms except battery alerts
  if status.timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0, 0, false, 0} 
    elseif alarms[idx][4] == 1  then
      alarms[idx] = { false, 0, true, 1 , 0, false, 0}
    elseif  alarms[idx][4] == 2 then
      alarms[idx] = { false, 0, true, 2, 0, false, 0}
    elseif  alarms[idx][4] == 3 then
      alarms[idx] = { false, 0 , false, 3, 4, false, 0}
    elseif  alarms[idx][4] == 4 then
      alarms[idx] = { false, 0 , false, 4, 4, false, 0}
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level  
  if alarms[idx][3] == false and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][3] = true
  end
  --
  if alarms[idx][4] == 2 then
    if status.flightTime > 0 and math.floor(status.flightTime) %  delay == 0 then
      if alarms[idx][1] == false then 
        alarms[idx][1] = true
        playSound(sound)
         -- flightime is a multiple of 1 minute
        if (status.flightTime % 60 == 0 ) then
          -- minutes
          playNumber(status.flightTime / 60,25) --25=minutes,26=seconds
        else
          -- minutes
          if (status.flightTime > 60) then playNumber(status.flightTime / 60,25) end
          -- seconds
          playNumber(status.flightTime % 60,26)
        end
      end
    else
        alarms[idx][1] = false
    end
  else
    if alarms[idx][3] == true then
      if level > 0 and sign*value > sign*level then
        -- value is outside level 
        if alarms[idx][2] == 0 then
          -- first time outside level after last reset
          alarms[idx][2] = status.flightTime
          -- status: START
        end
      else
        -- value back to normal ==> reset
        alarms[idx][2] = 0
        alarms[idx][1] = false
        alarms[idx][6] = false
        -- status: RESET
      end
      if alarms[idx][2] > 0 and (status.flightTime ~= alarms[idx][2]) and (status.flightTime - alarms[idx][2]) >= alarms[idx][5] then
        -- enough time has passed after START
        alarms[idx][6] = true
        -- status: READY
      end
      --
      if alarms[idx][6] == true and alarms[idx][1] == false then 
        playSound(sound)
        alarms[idx][1] = true
        alarms[idx][7] = status.flightTime
        -- status: BEEP
      end
      -- all but battery alarms
      if alarms[idx][4] ~= 3 then
        if alarms[idx][6] == true and status.flightTime ~= alarms[idx][7] and (status.flightTime - alarms[idx][7]) %  delay == 0 then
          alarms[idx][1] = false
          -- status: REPEAT
        end
      end
    end
  end
end

local function loadFlightModes()
  if frame.flightModes then
    return
  end
  --
  if status.frameType ~= -1 then
    if frameTypes[status.frameType] == "c" then
      frame = dofile("/SCRIPTS/YAAPU/LIB/copter.luac")
    elseif frameTypes[status.frameType] == "p" then
      frame = dofile("/SCRIPTS/YAAPU/LIB/plane.luac")
    elseif frameTypes[status.frameType] == "r" then
      frame = dofile("/SCRIPTS/YAAPU/LIB/rover.luac")
    end
  end
end

local function checkEvents(celm)
  loadFlightModes()
  -- silence alarms when showing min/max values
  if showMinMaxValues == false then
    checkAlarm(conf.minAltitudeAlert,status.homeAlt,1,-1,"minalt",menuItems[14][4])
    checkAlarm(conf.maxAltitudeAlert,status.homeAlt,2,1,"maxalt",menuItems[14][4])  
    checkAlarm(conf.maxDistanceAlert,status.homeDist,3,1,"maxdist",menuItems[14][4])  
    checkAlarm(1,2*status.ekfFailsafe,4,1,"ekf",menuItems[14][4])  
    checkAlarm(1,2*status.battFailsafe,5,1,"lowbat",menuItems[14][4])  
    checkAlarm(conf.timerAlert,status.flightTime,6,1,"timealert",conf.timerAlert)
end
  -- default is use battery 1
  local capacity = getBatt1Capacity()
  local mah = status.batt1mah
  -- only if dual battery has been detected use battery 2
  if status.batt2sources.fc or status.batt2sources.vs then
      capacity = capacity + getBatt2Capacity()
      mah = mah  + status.batt2mah
  end
  --
    if (capacity > 0) then
      status.batLevel = (1 - (mah/capacity))*100
    else
      status.batLevel = 99
    end
  for l=1,13 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    if status.batLevel <= batLevels[l] + 1 and l < status.lastBattLevel then
      status.lastBattLevel = l
      playSound("bat"..batLevels[l])
      break
    end
  end
  
  if status.statusArmed == 1 and status.lastStatusArmed == 0 then
    status.lastStatusArmed = status.statusArmed
    playSound("armed")
  elseif status.statusArmed == 0 and status.lastStatusArmed == 1 then
    status.lastStatusArmed = status.statusArmed
    playSound("disarmed")
  end

  if status.gpsStatus > 2 and status.lastGpsStatus <= 2 then
    status.lastGpsStatus = status.gpsStatus
    playSound("gpsfix")
  elseif status.gpsStatus <= 2 and status.lastGpsStatus > 2 then
    status.lastGpsStatus = status.gpsStatus
    playSound("gpsnofix")
  end

  if status.frameType ~= -1 and status.flightMode ~= status.lastFlightMode then
    status.lastFlightMode = status.flightMode
    playSoundByFrameTypeAndFlightMode(status.flightMode)
  end
  
  if status.simpleMode ~= status.lastSimpleMode then
    if status.simpleMode == 0 then
      playSound( status.lastSimpleMode == 1 and "simpleoff" or "ssimpleoff" )
    else
      playSound( status.simpleMode == 1 and "simpleon" or "ssimpleon" )
    end
    status.lastSimpleMode = status.simpleMode
  end
end

local function checkCellVoltage(celm)
  -- check alarms
  checkAlarm(conf.battAlertLevel1,celm,7,-1,"batalert1",menuItems[14][4])
  checkAlarm(conf.battAlertLevel2,celm,8,-1,"batalert2",menuItems[14][4])
  -- cell bgcolor is sticky but gets triggered with alarms
  if status.battLevel1 == false then status.battLevel1 = alarms[7][1] end
  if status.battLevel2 == false then status.battLevel2 = alarms[8][1] end
end

local function cycleBatteryInfo()
  if showDualBattery == false and (status.batt2sources.fc or status.batt2sources.vs) then
    showDualBattery = true
    return
  end
  if status.battsource == "vs" then
    status.battsource = "fc"
  elseif status.battsource == "fc" then
    status.battsource = "a2"
  elseif status.battsource == "a2" then
    status.battsource = "vs"
  end
end
--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
--
local bgclock = 0

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local bgprocessing = false
local bglockcounter = 0
--
local function backgroundTasks(telemetryLoops)
if bgprocessing == true then
  bglockcounter = bglockcounter + 1
  return 0
end
bgprocessing = true
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,telemetryLoops
  do
    processTelemetry()
  end
  -- NORMAL: this runs at 20Hz (every 50ms)
  calcFlightTime()
  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
    setSensorValues()
    collectgarbage()
  end
  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    -- update battery
    calcBattery()
    -- prepare celm based on battsource
    local count = calcCellCount()
    local cellVoltage = 0
    --
    if status.battsource == "vs" then
      cellVoltage = getNonZeroMin(status.cell1min, status.cell2min)*100 --FLVSS
    elseif status.battsource == "fc" then
      cellVoltage = getNonZeroMin(status.cell1sumFC/count,status.cell2sumFC/count)*100 --FC
    elseif status.battsource == "a2" then
      cellVoltage = (status.cellsumA2/count)*100 --12
    end
    --
    checkEvents(cellVoltage)
    checkLandingStatus()
    -- no need for alarms if reported voltage is 0
    if cellVoltage > 0 then
      checkCellVoltage(cellVoltage)
    end
    -- aggregate value
    minmaxValues[8] = math.max(status.batt1current+status.batt2current,minmaxValues[8])
    -- indipendent values
    minmaxValues[9] = math.max(status.batt1current,minmaxValues[9])
    minmaxValues[10] = math.max(status.batt2current,minmaxValues[10])
    -- reset backlight panel
    if (model.getGlobalVariable(8,0) > 0 and getTime()/100 - backlightLastTime > 5) then
      model.setGlobalVariable(8,0,0)
    end
    bgclock = 0
  end
  bgclock = bgclock+1
  -- blinking support
  if (getTime() - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = getTime()
  end
  bgprocessing = false
  return 0
end

local showSensorPage = false
local showMessages = false

local function init()
  -- initialize flight timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
  currentModel = model.getInfo().name
  loadConfig()
  playSound("yaapu")
  pushMessage(7,"Yaapu Telemetry Script 1.7.4")
  -- load unit definitions
  unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
  unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
-- 4 pages
-- page 1 single battery view
-- page 2 message history
-- page 3 min max
-- page 4 dual battery view
local options = {
  { "page", VALUE, 1, 1, 4},
}

local widgetPages = { 
  {active=false, bgtasks=false, fgtasks=false},
  {active=false, bgtasks=false, fgtasks=false},
  {active=false, bgtasks=false, fgtasks=false},
  {active=false, bgtasks=false, fgtasks=false}
}
---------------------
-- script version 
---------------------
-- shared init flag
local initDone = 0
-- This function is runned once at the creation of the widget
local function create(zone, options)
  -- this vars are widget scoped, each instance has its own set
  local vars = {
  }
  -- all local vars are shared between widget instances
  -- init() needs to be called only once!
  if initDone == 0 then
    init()
    initDone = 1
  end
  -- register current page as active
  widgetPages[options.page].active = true
  --
  return { zone=zone, options=options, vars=vars }
end

-- This function allow updates when you change widgets settings
local function update(myWidget, options)
  myWidget.options = options
  -- register current page as active
  widgetPages[options.page].active = true
  -- reload menu settings
  loadConfig()
end
local function fullScreenRequired(myWidget)
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0, 0))
  lcd.drawText(myWidget.zone.x,myWidget.zone.y,"Yaapu requires",SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(myWidget.zone.x,myWidget.zone.y+16,"full screen",SMLSIZE+CUSTOM_COLOR)
  --[[
  if myWidget.zone.h > 100 then
    local strsize = string.format("%d x %d",myWidget.zone.w,myWidget.zone.h)
    lcd.drawText(myWidget.zone.x,myWidget.zone.y+32,strsize,SMLSIZE+CUSTOM_COLOR)
  end
  --]]end
-- This size is for top bar widgets
local function zoneTiny(myWidget)
  fullScreenRequired(myWidget)
end
--- Size is 160x30 1/8th
local function zoneSmall(myWidget)
  fullScreenRequired(myWidget)
end
--- Size is 180x70 1/4th
local function zoneMedium(myWidget)
  fullScreenRequired(myWidget)
end
--- Size is 190x150
local function zoneLarge(myWidget)
  fullScreenRequired(myWidget)
end
--- Size is 390x170
local function zoneXLarge(myWidget)
  fullScreenRequired(myWidget)
end
--- Size is 480x272
local function zoneFullScreen(myWidget)
  --------------------------
  -- Widget Page 2 is message history
  --------------------------
  if myWidget.options.page == 2 then
    drawAllMessages()
  else
    drawHomeDirection()
    drawHud(myWidget)
    drawCompassRibbon()
    --
    -- Note: these can be calculated. not necessary to track them as min/max 
    -- status.cell1minFC = status.cell1sumFC/calcCellCount()
    -- status.cell2minFC = status.cell2sumFC/calcCellCount()
    -- status.cell1minA2 = status.cell1sumA2/calcCellCount()
    -- 
    local count = calcCellCount()
    local cel1m = getMinVoltageBySource(status.battsource,status.cell1min,status.cell1sumFC/count,status.cellsumA2/count,1,count)*100
    local cel2m = getMinVoltageBySource(status.battsource,status.cell2min,status.cell2sumFC/count,status.cellsumA2/count,2,count)*100
    local batt1 = getMinVoltageBySource(status.battsource,status.cell1sum,status.cell1sumFC,status.cellsumA2,1,count)*10
    local batt2 = getMinVoltageBySource(status.battsource,status.cell2sum,status.cell2sumFC,status.cellsumA2,2,count)*10
    local curr  = getMaxValue(status.batt1current+status.batt2current,8)
    local curr1 = getMaxValue(status.batt1current,9)
    local curr2 = getMaxValue(status.batt2current,10)
    local mah1 = status.batt1mah
    local mah2 = status.batt2mah
    local cap1 = getBatt1Capacity()
    local cap2 = getBatt2Capacity()
    --
    -- with dual battery default is to show aggregate view
    if status.batt2sources.fc or status.batt2sources.vs then
      if showDualBattery == false then
        -- dual battery: aggregate view
        lcd.drawText(285+67,85,"BATTERY: 1+2",SMLSIZE+INVERS)
        drawBatteryPane(285,getNonZeroMin(batt1,batt2),getNonZeroMin(cel1m,cel2m),curr,mah1+mah2,cap1+cap2)
      else
        -- dual battery: do I have also dual current monitor?
        if curr1 > 0 and curr2 == 0 then
          -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
          curr1 = curr1/2
          curr2 = curr1
          --
          mah1 = mah1/2
          mah2 = mah1
          --
          cap1 = cap1/2
          cap2 = cap1
        end
        -- dual battery:battery 1 right pane
        lcd.drawText(285+75,85,"BATTERY: 1",SMLSIZE+INVERS)
        drawBatteryPane(285,batt1,cel1m,curr1,mah1,cap1)
        -- dual battery:battery 2 left pane
        lcd.drawText(50,85,"BATTERY: 2",SMLSIZE+INVERS)
        drawBatteryPane(-24,batt2,cel2m,curr2,mah2,cap2)
      end
    else
      -- battery 1 right pane in single battery mode
      lcd.drawText(285+75,85,"BATTERY: 1",SMLSIZE+INVERS)
      drawBatteryPane(285,batt1,cel1m,curr1,mah1,cap1)
    end
    -- left pane info when not in dual battery mode
    if showDualBattery == false then
      -- power is always based on flight controller values
      drawGPSStatus()
      if showSensorPage then
        drawCustomSensors()
      else
        drawLeftPane(curr1+curr2,getNonZeroMin(status.cell1sumFC,status.cell2sumFC))
      end
    end
    drawFlightMode()
    drawTopBar()
    drawBottomBar()
    drawFlightTime()
    drawFailsafe()
    drawArmStatus()
    if showDualBattery == false and showSensorPage == false then
    end
  end  
  drawNoTelemetryData()
end

-- called when widget instance page changes
local function onChangePage(myWidget)
  -- reset HUD counters
  myWidget.vars.hudcounter = 0
  -- refresh config on page change so it's possible to use menu in one time mode
  loadConfig()
  collectgarbage()
end

-- Called when script is hidden @20Hz
local function background(myWidget)
  -- when page 3 goes to background hide minmax values
  if myWidget.options.page == 3 then
    showMinMaxValues = false
    return
  end
  -- when page 4 goes to background hide dual battery view
  if myWidget.options.page == 4 then
    showDualBattery = false
    return
  end
  -- when page 1 goes to background run bg tasks only if page 2 is not registered
  if myWidget.options.page == 1 and widgetPages[2].active == false then
    -- run bg tasks
    backgroundTasks(6)
    return
  end
  -- when page 2 goes to background always run bg tasks
  if myWidget.options.page == 2 then
    -- run bg tasks
    backgroundTasks(6)
  end
end

-- Called when script is visible
function refresh(myWidget)
  -- check if current widget page changed
  if currentPage ~= myWidget.options.page then
    currentPage = myWidget.options.page
    onChangePage(myWidget)
  end
  -- when page 1 goes to foreground run bg tasks only if page 2 is not registered
  if myWidget.options.page == 1 and widgetPages[2].active == false then
    -- run bg tasks
    backgroundTasks(6)
  end
  -- if widget page 2 is declared then always run bg tasks when in foreground
  if myWidget.options.page == 2 then
    -- run bg tasks
    backgroundTasks(4)
  end
   -- when page 3 goes to foreground show minmax values
  if myWidget.options.page == 3 then
    showMinMaxValues = true
  end
  -- when page 4 goes to foreground show dual battery view
  if myWidget.options.page == 4 then
    showDualBattery = true
  end
  --
  if myWidget.zone.w  > 450 and myWidget.zone.h > 250 then zoneFullScreen(myWidget) 
  elseif myWidget.zone.w  > 380 and myWidget.zone.h > 165 then zoneXLarge(myWidget)
  elseif myWidget.zone.w  > 180 and myWidget.zone.h > 145  then zoneLarge(myWidget)
  elseif myWidget.zone.w  > 170 and myWidget.zone.h > 65 then zoneMedium(myWidget)
  elseif myWidget.zone.w  > 150 and myWidget.zone.h > 28 then zoneSmall(myWidget)
  elseif myWidget.zone.w  > 65 and myWidget.zone.h > 35 then zoneTiny(myWidget)
  end
end

return { name="Yaapu", options=options, create=create, update=update, background=background, refresh=refresh } 
