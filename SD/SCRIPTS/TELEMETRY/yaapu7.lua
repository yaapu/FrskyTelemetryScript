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
--#define X9

---------------------
-- script version 
---------------------

---------------------
-- frame types: copter always enabled
---------------------

---------------------
-- features
---------------------
-- check events in the background
-- process telemetry in the background @60Hz
--#define RESETBATTALARMS
--#define MENUEX
--#define ALERTS

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
--
local flightModes = {}
flightModes["c"] = {}
flightModes["p"] = {}
flightModes["r"] = {}
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
local frameType = 2
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
--


  






















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
--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

  
local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}


local menuItems = {
  {"voice language:", 1, "L1", 1, { "eng", "ita", "fre" } , {"en","it","fr"} },
  {"batt alert level 1:", 0, "V1", 350, 320,420,"V",PREC2,5 },
  {"batt alert level 2:", 0, "V2", 350, 320,420,"V",PREC2,5 },
  {"batt[1] mAh override:", 0, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] mAh override:", 0, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", 1, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", 1, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", 1, "S3", 1, { "no", "yes" }, { false, true } },
  {"def voltage source:", 1, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", 0, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", 0, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", 0, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", 0, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", 0, "T2", 10, 10,600,"sec",0,5 },
}

local function getConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
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
  lcd.drawFilledRectangle(0,0, 128, 7, SOLID)
  lcd.drawRectangle(0, 0, 128, 7, SOLID)
  lcd.drawText(0,0,"Yaapu X7 1.5.0-rc1",SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,57-2, 128, 9, SOLID)
  lcd.drawRectangle(0, 57-2, 128, 9, SOLID)
  lcd.drawText(0,57-1,string.sub(getConfigFilename(),8),SMLSIZE+INVERS)
  lcd.drawNumber(128,57-1,#menuItems,SMLSIZE+INVERS+RIGHT)
  lcd.drawText(lcd.getLastLeftPos(),57-1,"/",SMLSIZE+INVERS+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(),57-1,menu.selectedItem,SMLSIZE+INVERS+RIGHT)
end

local function incMenuItem(idx)
  if menuItems[idx][2] == 0 then
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
  if menuItems[idx][2] == 0 then
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
  if menuItems[idx][2] == 0 then
    if menuItems[idx][4] == 0 then
      lcd.drawText(102,7 + (idx-menu.offset-1)*7, "---",0+SMLSIZE+flags+menuItems[idx][8])
    else
      lcd.drawNumber(102,7 + (idx-menu.offset-1)*7, menuItems[idx][4],0+SMLSIZE+flags+menuItems[idx][8])
      lcd.drawText(lcd.getLastRightPos(),7 + (idx-menu.offset-1)*7, menuItems[idx][7],SMLSIZE+flags+menuItems[idx][8])
    end
  else
    lcd.drawText(102,7 + (idx-menu.offset-1)*7, menuItems[idx][5][menuItems[idx][4]],SMLSIZE+flags)
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
  if menu.selectedItem > 7 then
    menu.offset = menu.selectedItem - 7
  elseif menu.selectedItem <= 7 then
    menu.offset = 0
  end
  --
  for m=1+menu.offset,math.min(#menuItems,7+menu.offset) do
    lcd.drawText(2,7 + (m-menu.offset-1)*7, menuItems[m][1],0+SMLSIZE)
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
  if flightModes[frameTypes[frameType]][flightMode] ~= nil then
    playFile(soundFileBasePath.."/"..conf.language.."/".. string.lower(flightModes[frameTypes[frameType]][flightMode])..".wav")
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
  if #messages == 9 and messages[#messages][3] ~= msg then
    for i=1,9-1 do
      messages[i]=messages[i+1]
    end
    -- trunk at 9
    messages[9] = nil
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


-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
--
local function processTelemetry()
  SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
  if ( FRAME_ID == 0x10) then
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
      elseif paramId == 5 then
        batt2Capacity = paramValue
      end
    end
  end
end

local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end

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


local function calcMinValue(value,min)
  if min == 0 then
    return value
  else
    return math.min(value,min)
  end
end

local function calcBattery()
  local battA2 = 0
  local cell = {0, 0, 0, 0, 0 ,0}
  ------------
  -- FLVSS 1
  ------------
  local cellResult = getValue("Cels")
  if type(cellResult) == "table" then
    cell1min = 4.35
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
  cellResult = getValue("Cel2")
  if type(cellResult) == "table" then
    cell2min = 4.35
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
  -- 12 analog voltage only 1 supported
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
  -- cell fc
  minmaxValues[1] = calcMinValue(calcCellMin(cell1minFC,cell2minFC)*100,minmaxValues[1])
  minmaxValues[2] = calcMinValue(cell1minFC*100,minmaxValues[2])
  minmaxValues[3] = calcMinValue(cell2minFC*100,minmaxValues[3])
  -- cell flvss
  minmaxValues[4] = calcMinValue(calcCellMin(cell1min,cell2min)*100,minmaxValues[4])
  minmaxValues[5] = calcMinValue(cell1min*100,minmaxValues[5])
  minmaxValues[6] = calcMinValue(cell2min*100,minmaxValues[6])
  -- cell 12
  minmaxValues[7] = calcMinValue(cellminA2*100,minmaxValues[7])
  minmaxValues[8] = minmaxValues[7]
  minmaxValues[9] = 0
  -- batt fc
  minmaxValues[10] = calcMinValue(calcCellMin(cell1sumFC,cell2sumFC)*10,minmaxValues[10])
  minmaxValues[11] = calcMinValue(cell1sumFC*10,minmaxValues[11])
  minmaxValues[12] = calcMinValue(cell2sumFC*10,minmaxValues[12])
  -- batt flvss
  minmaxValues[13] = calcMinValue(calcCellMin(cell1sum,cell2sum)*10,minmaxValues[13])
  minmaxValues[14] = calcMinValue(cell1sum*10,minmaxValues[14])
  minmaxValues[15] = calcMinValue(cell2sum*10,minmaxValues[15])
  -- batt 12
  minmaxValues[16] = calcMinValue(cellsumA2*10,minmaxValues[16])
  minmaxValues[17] = minmaxValues[16]
  minmaxValues[18] = 0
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



--[[
  min alarms need to be armed, i.e since values start at 0 in order to avoid
  immediate triggering upon start, the value must first reach the treshold
  only then will it trigger the alarm
]]local alarms = {
  --{ triggered, time, armed, type(0=min,1=max,2=timer,3=batt),  }  
    { false, 0 , false, 0},
    { false, 0 , true, 1 },
    { false, 0 , true, 1 },
    { false, 0 , true, 1 },
    { false, 0 , true, 1 },
    { false, 0 , true, 2 },
    { false, 0 , true, 3 },
    { false, 0 , true, 3 },
}

local function checkCellVoltage(battsource,cellmin,cellminFC,cellminA2)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  -- trigger batt1 and batt2
  if celm > conf.battAlertLevel2 and celm < conf.battAlertLevel1 and alarms[7][1] == false then
    alarms[7][1] = true
    playSound("batalert1")
  end
  if celm > 320 and celm < conf.battAlertLevel2 and alarms[8][1] == false then
    alarms[8][1] = true
    playSound("batalert2")
  end
end


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
  setTelemetryValue(0x0600, 0, 0, perc, 13 , 0 , "Fuel")
  setTelemetryValue(0x0210, 0, 2, calcCellMin(batt1volt,batt2volt)*10, 1 , 2 , "VFAS")
  setTelemetryValue(0x0200, 0, 3, batt1current+batt2current, 2 , 1 , "CURR")
  setTelemetryValue(0x0110, 0, 1, vSpeed, 5 , 1 , "VSpd")
  setTelemetryValue(0x0830, 0, 4, hSpeed*0.1, 4 , 0 , "GSpd")
  setTelemetryValue(0x0100, 0, 1, homeAlt*10, 9 , 1 , "Alt")
  setTelemetryValue(0x0820, 0, 4, math.floor(gpsAlt*0.1), 9 , 0 , "GAlt")
  setTelemetryValue(0x0840, 0, 4, math.floor(yaw), 20 , 0 , "Hdg")
  setTelemetryValue(0x0400, 0, 0, flightMode, 11 , 0 , "Tmp1")
  setTelemetryValue(0x0410, 0, 0, numSats*10+gpsStatus, 11 , 0 , "Tmp2")
end


---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawBatteryPane(x,battsource,battcurrent,battcapacity,battmah,cellmin,cellminFC,cellminA2,cellsum,cellsumFC,cellsumA2,cellIdx,lipoIdx,currIdx)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  local lipo = getVoltageBySource(battsource,cellsum,cellsumFC,cellsumA2)*10
  celm = getMinValue(celm,cellIdx + minmaxOffsets[battsource])
  lipo = getMinValue(lipo,lipoIdx + minmaxOffsets[battsource])
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
  if showMinMaxValues == false then
    if alarms[8][1] == true then
      flags = BLINK
      dimFlags = BLINK
    elseif alarms[7][1] == true then
      dimFlags = BLINK+INVERS
    end
  end
  drawNumberWithTwoDims(x+24, 27, 28, 36,celm,"V",battsource,DBLSIZE+PREC2+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(x+1,29,29, lipo,"V",INVERS+PREC1+SMLSIZE,INVERS+SMLSIZE)
  -- battery current
  battcurrent = getMaxValue(battcurrent,currIdx)
  drawNumberWithDim(x+1,36,36,battcurrent,"A",INVERS+SMLSIZE+PREC1,INVERS+SMLSIZE)
  -- battery percentage
  lcd.drawNumber(x+16, 44, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos(), 48, "%", SMLSIZE)
  -- battery mah
  lcd.drawText(x+64, 43, "Ah", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 43, battmah/100, SMLSIZE+PREC1+RIGHT)
  lcd.drawText(x+64, 43+8, "Ah", SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 43+8, battcapacity/100, SMLSIZE+PREC1+RIGHT+INVERS)
  -- tx voltage
  lcd.drawText(104, 21, "Tx", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), 21, getValue(getFieldInfo("tx-voltage").id)*10, SMLSIZE+PREC1)
  lcd.drawText(lcd.getLastRightPos(), 21, "v", SMLSIZE)
  if showMinMaxValues == true then
    drawVArrow(x+24+36, 27+2,6,false,true)
  end
end
---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawX7BatteryLeftPane(battsource,battcurrent,battcapacity,battmah,cellmin,cellminFC,cellminA2,cellsum,cellsumFC,cellsumA2,cellIdx,lipoIdx,currIdx)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  local lipo = getVoltageBySource(battsource,cellsum,cellsumFC,cellsumA2)*10
  celm = getMinValue(celm,cellIdx + minmaxOffsets[battsource])
  lipo = getMinValue(lipo,lipoIdx + minmaxOffsets[battsource])
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
  if showMinMaxValues == false then
    if celm < conf.battAlertLevel2 then
      flags = BLINK
      dimFlags = BLINK
    elseif celm < conf.battAlertLevel1 then
      dimFlags = BLINK+INVERS
    end  
  end
  drawNumberWithTwoDims(0, 27, 28, 36,celm,"V",battsource,DBLSIZE+PREC2+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(41+1,29,29, lipo,"V",INVERS+PREC1+SMLSIZE,INVERS+SMLSIZE)
  -- battery current
  battcurrent = getMinValue(battcurrent,currIdx)
  drawNumberWithDim(41+1,36,36,battcurrent,"A",INVERS+SMLSIZE+PREC1,INVERS+SMLSIZE)
  -- battery percentage
  lcd.drawNumber(17+16, 44, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos(), 48, "%", SMLSIZE)
  -- box
  lcd.drawRectangle(0,43 + 7,6,7,SOLID)
  lcd.drawFilledRectangle(0,43 + 7,6,7,SOLID)
  -- battery mah
  lcd.drawText(-35+64, 43, "Ah", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 43, battmah/100, SMLSIZE+PREC1+RIGHT)
  lcd.drawText(-35+64, 43+8, "Ah", SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 43+8, battcapacity/100, SMLSIZE+PREC1+RIGHT+INVERS)
  if showMinMaxValues == true then
    drawVArrow(36, 27+2,6,false,true)
  end
end

local function drawNoTelemetryData()
  -- no telemetry data
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle(12,18, 105, 30, SOLID)
    lcd.drawText(30, 29, "no telemetry", INVERS)
    return
  end
end

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

local function drawTopBar()
  -- black bar
  lcd.drawFilledRectangle(0,0, 128, 7, SOLID)
  lcd.drawRectangle(0, 0, 128, 7, SOLID)
  -- flight mode
  local strMode = flightModes[frameTypes[frameType]][flightMode]
  if strMode ~= nil then
    lcd.drawText(1, 0, strMode, SMLSIZE+INVERS)
    if ( simpleMode == 1) then
      lcd.drawText(lcd.getLastRightPos(), 1, "(S)", SMLSIZE+INVERS)
    end
  end  
  -- flight time
  lcd.drawText(96, 0, "T:", SMLSIZE+INVERS)
  lcd.drawTimer(lcd.getLastRightPos(), 0, flightTime, SMLSIZE+INVERS)
  -- RSSI
  lcd.drawText(60, 0, "RS:", SMLSIZE+INVERS )
  lcd.drawText(lcd.getLastRightPos(), 0, getRSSI(), SMLSIZE+INVERS )  
end

local function drawBottomBar()
  -- black bar
  lcd.drawFilledRectangle(0,57, 128, 8, SOLID)
  lcd.drawRectangle(0, 57, 128, 8, SOLID)
  -- message text
  local now = getTime()
  local msg = getMessage(#messages)
  if (now - lastMsgTime ) > 150 or conf.disableMsgBlink then
    lcd.drawText(0, 57 + 1,  msg,SMLSIZE+INVERS)
  else
    lcd.drawText(0, 57 + 1,  msg,SMLSIZE+INVERS+BLINK)
  end
end

local function drawHomeDist()
  drawHArrow(66,21 + 2,7,true,true)
  local flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
  homeDist = getMaxValue(homeDist,27)
  if showMinMaxValues == true then
    flags = 0
  end
  lcd.drawNumber(76, 21, homeDist, SMLSIZE+flags)
  lcd.drawText(lcd.getLastRightPos(), 21, "m",SMLSIZE+flags)
  if showMinMaxValues == true then
    drawVArrow(lcd.getLastRightPos() + 2, 21,6,true,false)
  end
end

local function drawAllMessages()
  for i=1,#messages do
    lcd.drawText(1, 1 + 7*(i-1), getMessage(i),SMLSIZE)
  end
end


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
    lcd.drawText(65 + 1,6 + 6, strStatus, SMLSIZE)
    lcd.drawNumber(65 + 34, 6 + 1, numSats, MIDSIZE+RIGHT)
    lcd.drawText(65 + 39, 6 + 6 , "H", SMLSIZE)
    lcd.drawNumber(lcd.getLastRightPos() + 1, 6 + 1, gpsHdopC*mult , MIDSIZE+flags)
    lcd.drawLine(65 + 34,6+1,65+34,6+12,SOLID,FORCE)
  else
    lcd.drawText(65 + 9, 6+1, strStatus, MIDSIZE+INVERS+BLINK)
  end
  lcd.drawLine(65 ,6 + 13,65+63,6 + 13,SOLID,FORCE)
end

local function drawFailsafe()
  local xoffset = 0
  local yoffset = 0
  if showDualBattery == true and (ekfFailsafe > 0 or battFailsafe >0) then
    xoffset = 35
    yoffset = -15
    lcd.drawFilledRectangle(xoffset + 6, 36 + yoffset, 50, 21, ERASE)
    lcd.drawRectangle(xoffset + 6, 36 + yoffset, 50, 21, SOLID)
  end
  if ekfFailsafe > 0 then
    lcd.drawText(xoffset + 0 + 64/2 - 6, 39 + yoffset, "EKF", SMLSIZE+INVERS+BLINK)
    lcd.drawText(xoffset + 0 + 64/2 - 17, 48 + yoffset, "FAILSAFE", SMLSIZE+INVERS+BLINK)
  end
  if battFailsafe > 0 then
    lcd.drawText(xoffset + 0 + 64/2 - 8, 39 + yoffset, "BATT", SMLSIZE+INVERS+BLINK)
    lcd.drawText(xoffset + 0 + 64/2 - 17, 48 + yoffset, "FAILSAFE", SMLSIZE+INVERS+BLINK)
  end
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
  -- lets erase to hide the artificial horizon lines
  for ly=0,5 do
    lcd.drawLine(0,32 - ly,0 +   16 + (5 - ly),32 - ly, SOLID, ERASE)
    lcd.drawLine(0 + 64 -  17 - 1 - (5 - ly),32 - ly,0 + 64 - 1,32 - ly,SOLID,ERASE)
  end
  for ly=1,4 do
    lcd.drawLine(0,32 + ly,0 +   16 + (5 - ly),32 + ly, SOLID, ERASE)
    lcd.drawLine(0 + 64 -  17 - 1 - (5 - ly),32 + ly,0 + 64 - 1,32 + ly,SOLID,ERASE)
  end
  --
    homeAlt = getMaxValue(homeAlt,23)
  if homeAlt > 0 then
    if homeAlt < 10 then -- 2 digits with decimal
      lcd.drawNumber(0 + 64,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
    else -- 3 digits
      lcd.drawNumber(0 + 64,32 - 3,homeAlt,SMLSIZE+RIGHT)
    end
  else
    if homeAlt > -10 then -- 1 digit with sign
      lcd.drawNumber(0 + 64,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
    else -- 3 digits with sign
      lcd.drawNumber(0 + 64,32 - 3,homeAlt,SMLSIZE+RIGHT)
    end
  end
  --
  if (vSpeed > 999) then
    lcd.drawNumber(0 + 1,32 - 3,vSpeed*0.1,SMLSIZE)
  elseif (vSpeed < -99) then
    lcd.drawNumber(0 + 1,32 - 3,vSpeed * 0.1,SMLSIZE)
  else
    lcd.drawNumber(0 + 1,32 - 3,vSpeed,SMLSIZE+PREC1)
  end
  -- up pointing center arrow
  local arrowX = math.floor(0 + 64/2)
  lcd.drawLine(arrowX - 5,34 + 5,arrowX ,34 ,SOLID,FORCE)
  lcd.drawLine(arrowX,34 ,arrowX + 5, 34 + 5,SOLID,FORCE)
  -- vSpeed
  lcd.drawLine(0,32 - 5,0 +   16,32 - 5, SOLID, FORCE)
  lcd.drawLine(0,32 + 4,0 +   16,32 + 4, SOLID, FORCE)
  lcd.drawLine(0 +   16 + 1,32 - 4,0 +   16 + 5,32, SOLID,  FORCE)
  lcd.drawLine(0 +   16 + 1,32 + 4,0 +   16 + 4,33, SOLID,  FORCE)
  -- altitude
  lcd.drawLine(0 + 64 -  17 - 1,32 - 5,0 + 64 - 1,32 - 5,SOLID,FORCE)
  lcd.drawLine(0 + 64 -  17 - 1,32 + 4,0 + 64 - 1,32 + 4,SOLID,FORCE)
  lcd.drawLine(0 + 64 -  17 - 2,32 + 4,0 + 64 -  17 - 6,32, SOLID, FORCE)
  lcd.drawLine(0 + 64 -  17 - 2,32 - 4,0 + 64 -  17 - 6,32, SOLID, FORCE)
    --
  if showMinMaxValues == true then
    lcd.drawFilledRectangle(0 + 64 - 26,32-5,7,10,ERASE)
    drawVArrow(0 + 64 - 23, 32-4,6,true,false)
  end
end

-- vertical distance between roll horiz segments
local function drawRoll()
  local r = -roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = 0 + 7 + 8
  -- no roll ==> segments are vertical, offsets are multiples of 10
  if ( roll == 0) then
    dx=0
    dy=pitch
    cx=0
    cy=10
    ccx=0
    ccy=2*10
    cccx=0
    cccy=3*10
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -pitch
    dy = math.sin(math.rad(90 - r)) * pitch
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
  local rollX = math.floor(0 + 64/2)
  --local delta = (64 - 76)
  drawCroppedLine(rollX + dx - cccx,dy + 32 + cccy,r,5,DOTTED,0,0 + 64,yPos,57)
  drawCroppedLine(rollX + dx - ccx,dy + 32 + ccy,r,7,DOTTED,0,0 + 64,yPos,57)
  drawCroppedLine(rollX + dx - cx,dy + 32 + cy,r,16,DOTTED,0,0 + 64,yPos,57)
  drawCroppedLine(rollX + dx,dy + 32,r,44,SOLID,0,0 + 64,yPos,57)
  drawCroppedLine(rollX + dx + cx,dy + 32 - cy,r,16,DOTTED,0,0 + 64,yPos,57)
  drawCroppedLine(rollX + dx + ccx,dy + 32 - ccy,r,7,DOTTED,0,0 + 64,yPos,57)
  drawCroppedLine(rollX + dx + cccx,dy + 32 - cccy,r,5,DOTTED,0,0 + 64,yPos,57)
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
  local hw = math.floor(64/2)
  local ww = hw - 6
  local degL = 0
  local degR = 0
  local steps = 9
  local yawRounded = roundTo(yaw,10)
  local homeRounded = roundTo(homeAngle,10)
  local minY = 0 + 7
  --
  local cx = 0 + hw
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

  lcd.drawLine(0, minY + 7, 0 + 64 - 1, minY + 7, SOLID, 0)
  local xx = 0
  if ( yaw < 10) then
    xx = 1
  elseif (yaw < 100) then
    xx = -2
  else
    xx = -5
  end
  lcd.drawRectangle(0 + hw - 6, minY, 12,12, SOLID)
  lcd.drawFilledRectangle(0 + hw - 6, minY, 12,12, SOLID)
  lcd.drawNumber(0 + hw + xx - 4, minY, yaw, MIDSIZE+INVERS)
end


local function drawHud()
  drawRoll()
  drawPitch()
  if ekfFailsafe == 0 and battFailsafe == 0 and timerRunning == 0 then
    if (statusArmed == 1) then
      lcd.drawText(0 + 64/2 - 12, 39, "ARMED", SMLSIZE+INVERS)
    else
      lcd.drawText(0 + 64/2 - 18, 39, "DISARMED", SMLSIZE+INVERS+BLINK)
    end
  end
end

local function drawGrid()
  lcd.drawLine(0 - 1, 7 ,0 - 1, 57, SOLID, 0)
  lcd.drawLine(0 + 64, 7, 0 + 64, 57, SOLID, 0)
end

local function drawHomeDirection()
  local angle = math.floor(homeAngle - yaw)
  local x1 = 73 + 7 * math.cos(math.rad(angle - 90))
  local y1 = 50 + 7 * math.sin(math.rad(angle - 90))
  local x2 = 73 + 7 * math.cos(math.rad(angle - 90 + 150))
  local y2 = 50 + 7 * math.sin(math.rad(angle - 90 + 150))
  local x3 = 73 + 7 * math.cos(math.rad(angle - 90 - 150))
  local y3 = 50 + 7 * math.sin(math.rad(angle - 90 - 150))
  local x4 = 73 + 7 * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = 50 + 7 * 0.5 *math.sin(math.rad(angle - 270))
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,1)
  lcd.drawLine(x1,y1,x3,y3,SOLID,1)
  lcd.drawLine(x2,y2,x4,y4,SOLID,1)
  lcd.drawLine(x3,y3,x4,y4,SOLID,1)
end

local function drawCustomBoxes()
  lcd.drawRectangle(65,28,23 ,15,SOLID)
  lcd.drawFilledRectangle(65,28,23 ,15,SOLID)
end

---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms
  if timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0} 
    elseif  alarms[idx][4] == 1 then
      alarms[idx] = { false, 0, true, 1}
    else
      alarms[idx] = { false, 0, true, 2}
    end
  end
  -- for minimum type alarms, arm the alarm only after value has reached level  
  if alarms[idx][3] == false and timerRunning == 1 and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][3] = true
  end
  -- if the alarm is armed and value is "ouside" levl
  if alarms[idx][3] == true and timerRunning == 1 and level > 0 and sign*value > sign*level then
    -- for timer alarms trigger when flighttime is a multiple of delay
    if alarms[idx][4] == 2 then
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
      -- ...and then fire every conf secs after the first show
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
  -- silence alarms when showing min/max values
  if showMinMaxValues == false then
    -- vocal fence alarms
    checkAlarm(conf.minAltitudeAlert,homeAlt,1,-1,"minalt",menuItems[14][4])
    checkAlarm(conf.maxAltitudeAlert,homeAlt,2,1,"maxalt",menuItems[14][4])  
    checkAlarm(conf.maxDistanceAlert,homeDist,3,1,"maxdist",menuItems[14][4])  
    checkAlarm(1,2*ekfFailsafe,4,1,"ekf",menuItems[14][4])  
    checkAlarm(1,2*battFailsafe,5,1,"lowbat",menuItems[14][4])  
    checkAlarm(conf.timerAlert,flightTime,6,1,"timealert",conf.timerAlert)
  end

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

  if flightMode ~= lastFlightMode then
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

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,3
  do
    processTelemetry()
  end
  -- NORMAL: this runs at 20Hz (every 50ms)
  setTelemetryValue(0x0110, 0, 1, vSpeed, 5 , 1 , "VSpd")
  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
    setSensorValues()
  end
  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    calcBattery()
    calcFlightTime()
    checkEvents()
    checkLandingStatus()
    checkCellVoltage(battsource,calcCellMin(cell1min,cell2min),calcCellMin(cell1minFC,cell2minFC),cellminA2)
    minmaxValues[20] = math.max(batt1current,minmaxValues[20])
    minmaxValues[21] = math.max(batt2current,minmaxValues[21])
    bgclock = 0
  end
  bgclock = bgclock+1
end
--
local clock = 0
--
local function run(event)
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
    lcd.clear()
    if event == EVT_EXIT_BREAK or event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT then
      showMessages = false
    end
    drawAllMessages()
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    lcd.clear()
    drawConfigMenu(event)
    -------------------------------
    -- exit from menu and save
    -------------------------------
    if event == EVT_EXIT_BREAK then
      menu.editSelected = false
      showConfigMenu = false
      saveConfig()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    lcd.clear()
    if event == EVT_ENTER_BREAK then
      cycleBatteryInfo()
    end
    if event == EVT_MENU_BREAK then
      showMinMaxValues = not showMinMaxValues
    end
    if showDualBattery == true and event == EVT_EXIT_BREAK then
      showDualBattery = false
    end
    --clearHud()
    -- on  the HUD is replaced with 2nd battery details
    if showDualBattery == false then
      drawHud()
    end
    drawYaw()
    drawGrid()
    drawCustomBoxes()
    -- with dual battery default is to show aggregate view
    if batt2sources.fc or batt2sources.vs or batt2sources.a2 then
      if showDualBattery == false then
        -- dual battery: aggregate view
        lcd.drawText(0+1,57 - 8,"2B",SMLSIZE+INVERS)
        drawBatteryPane(0+64+1,battsource,batt1current+batt2current,getBatt1Capacity()+getBatt2Capacity(),batt1mah+batt2mah,calcCellMin(cell1min,cell2min),calcCellMin(cell1minFC,cell2minFC),cellminA2,calcCellMin(cell1sum,cell2sum),calcCellMin(cell1sumFC,cell2sumFC),cellsumA2,1,10,19)
      else
        -- dual battery:battery 1 right pane
        drawBatteryPane(0+64+1,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,2,11,20)
        -- dual battery:battery 2 left pane
        drawX7BatteryLeftPane(battsource,batt2current,getBatt2Capacity(),batt2mah,cell2min,cell2minFC,0,cell2sum,cell2sumFC,0,3,12,21)
      end
    else
      --- battery 1 right pane in single battery mode
      drawBatteryPane(0+64+1,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,2,11,20)
    end
    if showDualBattery == false then
      drawHomeDirection()
    end
    drawHomeDist()
    drawGPSStatus()
    if showMinMaxValues == true then
      drawVArrow(0 + 2,0 - 2 ,6,true,false)
      drawVArrow(0 + 26, 0 - 1,6,true,false)
    end
    drawTopBar()
    drawBottomBar()
    drawFailsafe()
    drawNoTelemetryData()
  end
  clock = clock + 1
end

local function init()
  loadConfig()
  pushMessage(6,"Yaapu X7 1.5.0-rc1")
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}

