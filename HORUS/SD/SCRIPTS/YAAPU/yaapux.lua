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

-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764
---------------------
-- features
---------------------
--#define RESETBATTALARMS
--#define HUD_ALGO1
--#define HUD_BIG
--#define BATTPERC_BY_VOLTAGE
---------------------
-- dev features
---------------------
--#define LOGTELEMETRY
--#define LOGMESSAGES
--
--#define DEBUG
--#define DEBUGEVT
--#define TESTMODE
--#define BATT2TEST
--#define CELLCOUNT 4
--#define DEMO
--#define DEV

-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
--#define HUDTIMER
-- calc and show telemetry process rate
--#define BGTELERATE
-- calc and show actual incoming telemetry rate
--#define TELERATE

--












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
-- battery levels
local batLevel = 99
local batLevels = {}
local battLevel1 = false
local battLevel2 = false

--
local lastBattLevel = 13
batLevels[0]=0
batLevels[1]=5
batLevels[2]=10
batLevels[3]=15
batLevels[4]=20
batLevels[5]=25
batLevels[6]=30
batLevels[7]=40
batLevels[8]=50
batLevels[9]=60
batLevels[10]=70
batLevels[11]=80
batLevels[12]=90
--
local bitmaps = {}
local blinktime = getTime()
local blinkon = false
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

--




























-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
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
  disableCurrentSensor = false
}
--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

  
local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}

local menuItems = {
  -- label, type, alias, currval, min, max, label, flags, increment 
  {"voice language:", 1, "L1", 1, { "english", "italian", "french" } , {"en","it","fr"} },
  {"batt alert level 1:", 0, "V1", 375, 320,420,"V", PREC2 ,5 },
  {"batt alert level 2:", 0, "V2", 350, 320,420,"V", PREC2 ,5 },
  {"batt[1] capacity override:", 0, "B1", 0, 0,5000,"Ah",PREC2 ,10 },
  {"batt[2] capacity override:", 0, "B2", 0, 0,5000,"Ah",PREC2 ,10 },
  {"disable all sounds:", 1, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", 1, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", 1, "S3", 1, { "no", "yes" }, { false, true } },
  {"default voltage source:", 1, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", 0, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", 0, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", 0, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", 0, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", 0, "T2", 10, 10,600,"sec",0,5 },
  {"cell count override:", 0, "CC", 0, 0,12,"cells",0,1 },
}

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

local function drawBlinkBitmap(bitmap,x,y)
  if blinkon == true then
      lcd.drawBitmap(getBitmap(bitmap),x,y)
  end
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
  --
  if conf.defaultBattSource ~= nil then
    battsource = conf.defaultBattSource
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

local function drawConfigMenuBars()
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,0, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawRectangle(0, 0, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawText(2,0,"Yaapu Horus telemetry script 1.5.1-beta11",MENU_TITLE_COLOR)
  lcd.drawFilledRectangle(0,LCD_H - 20, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawRectangle(0, LCD_H - 20, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawText(2,LCD_H - 20+1,getConfigFilename(),MENU_TITLE_COLOR)
  lcd.drawText(LCD_W,LCD_H - 20+1,itemIdx,MENU_TITLE_COLOR+RIGHT)
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
      lcd.drawText(300,25 + (idx-menu.offset-1)*20, "---",flags)
    else
      lcd.drawNumber(300,25 + (idx-menu.offset-1)*20, menuItems[idx][4],flags+menuItems[idx][8])
      lcd.drawText(300 + 50,25 + (idx-menu.offset-1)*20, menuItems[idx][7],flags)
    end
  else
    lcd.drawText(300,25 + (idx-menu.offset-1)*20, menuItems[idx][5][menuItems[idx][4]],flags)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK then
	menu.editSelected = not menu.editSelected
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == EVT_PLUS_REPT) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_MINUS_REPT) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT) then
    menu.selectedItem = (menu.selectedItem - 1)
    if menu.offset >=  menu.selectedItem then
      menu.offset = menu.offset - 1
    end
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT) then
    menu.selectedItem = (menu.selectedItem + 1)
    if menu.selectedItem - 11 > menu.offset then
      menu.offset = menu.offset + 1
    end
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1 
    menu.offset = 0
  elseif menu.selectedItem  < 1 then
    menu.selectedItem = #menuItems
    menu.offset = 4
  end
  --
  for m=1+menu.offset,math.min(#menuItems,11+menu.offset) do
    lcd.drawText(2,25 + (m-menu.offset-1)*20, menuItems[m][1],0+0)
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
--
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
  if top == true then
    drawBlinkBitmap("uparrow",x,y)
  else
    drawBlinkBitmap("downarrow",x,y)
  end
end

local function drawVArrow2(x,y,h,top,bottom)
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

local function drawHomeIcon(x,y)
  lcd.drawBitmap(getBitmap("minihomeorange"),x,y)
end

local function drawLine(x1,y1,x2,y2,flags1,flags2)
  --if x1~=x2 or y1~=y2 then
    if string.find(radio, "x10") and rev < 2 then
      lcd.drawLine(LCD_W-x1,LCD_H-y1,LCD_W-x2,LCD_H-y2,flags1,flags2)
    else
      lcd.drawLine(x1,y1,x2,y2,flags1,flags2)
    end
  --else
    --lcd.drawLine(x1,y1,x2,y2,flags1,flags2)
  --end
end

local function drawCroppedLine(ox,oy,angle,len,style,minX,maxX,minY,maxY,color)
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
  drawLine(x1,y1,x2,y2, style,color)
end


local function drawNumberWithTwoDims(x,y,xDim,yTop,yBottom,number,topDim,bottomDim,flags,topFlags,bottomFlags)
  lcd.drawNumber(x, y, number, flags)
  local lx = xDim
  lcd.drawText(lx, yTop, topDim, topFlags)
  lcd.drawText(lx, yBottom, bottomDim, bottomFlags)
end

local function drawNumberWithDim(x,y,xDim,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(xDim, yDim, dim, dimFlags)
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
  if #messages == 14 and messages[#messages][3] ~= msg then
    for i=1,14-1 do
      messages[i]=messages[i+1]
    end
    -- trunc at 9
    messages[14] = nil
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

local function calcMinValue(value,min)
  if min == 0 then
    return value
  else
    return math.min(value,min)
  end
end

-- returns the actual minimun only if both are > 0
local function calcCellMin(v1,v2)
  if v1 == nil or v1 == 0 then
    return v2
  elseif v2 == nil or v2 == 0 then
    return v1
  else
    return math.min(v1,v2)
  end
end



local function calcCellCount(battmax)
  -- cellcount is cached
  if conf.cellCount ~= nil and conf.cellCount > 0 then
    return conf.cellCount
  end
  
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
  --{ triggered, time, armed, type(0=min,1=max,2=timer,3=batt),  last_trigger}  
    { false, 0 , false, 0, 0},
    { false, 0 , true, 1, 0 },
    { false, 0 , true, 1, 0 },
    { false, 0 , true, 1, 0 },
    { false, 0 , true, 1, 0 },
    { false, 0 , true, 2, 0 },
    { false, 0 , false, 3, 0 }
}

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
--------------------
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
  --
  if showMinMaxValues == false then
    if battLevel2 == true then
      lcd.drawBitmap(getBitmap("cell_red"),x+33 - 4,13 + 8)
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255)) -- white
      flags = CUSTOM_COLOR
    elseif abattLevel1 == true then
      lcd.drawBitmap(getBitmap("cell_orange"),x+33 - 4,13 + 8)
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 0, 0)) -- black
      flags = CUSTOM_COLOR
    end
  end
  drawNumberWithTwoDims(x+33, 13,x+171, 23, 60,celm,"V",battsource,XXLSIZE+PREC2+flags,flags,flags)
  -- battery voltage
  drawNumberWithDim(x+100,164,x+95, 159, lipo,"V",DBLSIZE+PREC1+RIGHT,SMLSIZE)
  -- battery current
  local current = getMaxValue(battcurrent,currIdx)
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
    lcd.drawText(90, 155, "Yaapu Horus telemetry script 1.5.1-beta11", SMLSIZE+INVERS)
    return
  end
end

local function getMessage(index)
  local msg = messages[index][3]
  if messages[index][4] > 1 then
    return string.format("%02d:%s (x%d) %s", messages[index][1], mavSeverity[messages[index][2]], messages[index][4], msg)
  else
    return string.format("%02d:%s %s", messages[index][1], mavSeverity[messages[index][2]], msg)
  end
end

local function drawFlightMode()
  -- flight mode
  if frameTypes[frameType] ~= nil then
    local strMode = flightModes[frameTypes[frameType]][flightMode]
    if strMode ~= nil then
      if ( simpleMode == 1) then
        strMode = string.format("%s%s",strMode,"(S)")
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
  local fn = frameNames[frameType]
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
  lcd.drawTimer(330, 202 + 16, flightTime, DBLSIZE)
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
  local msg = getMessage(#messages)
  if (now - lastMsgTime ) > 150 or conf.disableMsgBlink then
    lcd.drawText(2, LCD_H - 20 + 1, msg,MENU_TITLE_COLOR)
  else
    lcd.drawText(2, LCD_H - 20 + 1, msg,INVERS+BLINK+MENU_TITLE_COLOR)
  end
end

local function drawAllMessages()
  collectgarbage()
  for i=1,#messages do
    if getMessage(i) ~= nil then
      lcd.drawText(1,19*(i-1), getMessage(i),0)
    else
      lcd.drawNumber(1,19*(i-1), i,0)
    end
  end
end

local function getTelemetryId(name)
  local field = getFieldInfo(name)
  return field and field.id or -1
end

local gpsDataId = getTelemetryId("GPS")
--
local function drawLeftPane(battcurrent,cellsumFC)
  -- gps status
  local strStatus = gpsStatuses[gpsStatus]
  local flags = BLINK
  local mult = 1
  local gpsData = nil
  local hdop = gpsHdopC
  if gpsStatus  > 2 then
    if homeAngle ~= -1 then
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
    if numSats == 15 then
      lcd.drawNumber(2 + 80, 22 + 4 , numSats, DBLSIZE+RIGHT)
      lcd.drawText(2 + 89, 22 + 19, "+", RIGHT)
    else
      lcd.drawNumber(2 + 87, 22 + 4 , numSats, DBLSIZE+RIGHT)
    end
    --
    lcd.drawText(2 + 94, 22-3, "hd", SMLSIZE)
    lcd.drawNumber(2 + 166, 22 + 4, hdop*mult , DBLSIZE+flags+RIGHT)
    --
    lcd.drawLine(2 + 91,22 ,2+91,22 + 36,SOLID,0)
    --
    gpsData = getValue(gpsDataId)
    --
    if type(gpsData) == "table" and gpsData.lat ~= nil and gpsData.lon ~= nil then
      lcd.drawText(2 ,22 + 38,math.floor(gpsData.lat * 100000) / 100000,SMLSIZE)
      lcd.drawText(165 ,22 + 38,math.floor(gpsData.lon * 100000) / 100000,SMLSIZE+RIGHT)
    end
    lcd.drawLine(2 ,22 + 37,2+160,22 + 37,SOLID,0)
    lcd.drawLine(2 ,22 + 54,2+160,22 + 54,SOLID,0)
  elseif gpsStatus == 0 then
    drawBlinkBitmap("nogpsicon",4,24)
  else
    drawBlinkBitmap("nolockicon",4,24)
  end  
  flags = BLINK
  -- always display gps altitude even without 3d lock
  local alt = gpsAlt/10
  if gpsStatus  > 2 then
    flags = 0
    -- update max only with 3d or better lock
    alt = getMaxValue(alt,24)
  end
  if showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(10, 106, "AltAsl(m)", SMLSIZE)
  local stralt = string.format("%d",alt)
  lcd.drawText(82, 123, stralt, MIDSIZE+flags+RIGHT)
  -- home distance
  drawHomeIcon(91,106,7)
  lcd.drawText(165, 106, "Dist(m)", SMLSIZE+RIGHT)
  flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(homeDist,27)
  if showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist)
  lcd.drawText(165, 123, strdist, MIDSIZE+flags+RIGHT)
  -- hspeed
  local speed = getMaxValue(hSpeed,26)
  lcd.drawText(85, 152, "Speed(m/s)", SMLSIZE+RIGHT)
  lcd.drawNumber(84,170,speed,MIDSIZE+RIGHT+PREC1)
  -- power
  local power = cellsumFC*battcurrent*0.1
  power = getMaxValue(power,22)
  lcd.drawText(165, 152, "Power(W)", SMLSIZE+RIGHT)
  lcd.drawNumber(165,170,power,MIDSIZE+RIGHT)
  if showMinMaxValues == true then
    drawVArrow(82-81, 123,6,true,false)
    drawVArrow(165-78, 123 ,6,true,false)
    drawVArrow(61-60,170,6,true,false)
    drawVArrow(165-78, 170, 5,true,false)
  end
end

local function drawFailsafe()
  if ekfFailsafe > 0 then
    drawBlinkBitmap("ekffailsafe",LCD_W/2 - 90,180)
  end
  if battFailsafe > 0 then
    drawBlinkBitmap("battfailsafe",LCD_W/2 - 90,180)
  end
end

local function drawArmStatus()
  -- armstatus
  if ekfFailsafe == 0 and battFailsafe == 0 and timerRunning == 0 then
    if (statusArmed == 1) then
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
  local centerYaw = (yaw+270)%360
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = roundTo(centerYaw,45)
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
  local leftYaw = (yaw + 180)%360
  local rightYaw = yaw%360
  local centerHome = (homeAngle+270)%360
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
  lcd.drawLine(yawMinX, yawY + 16, yawMaxX, yawY + 16, SOLID, 0)
  local xx = 0
  if ( yaw < 10) then
    xx = 0
  elseif (yaw < 100) then
    xx = -8
  else
    xx = -14
  end
  lcd.drawNumber(LCD_W/2 + xx - 6, yawY, yaw, MIDSIZE+INVERS)
end


local compassPoints = {}
compassPoints[0] = "N"
compassPoints[1] = nil
compassPoints[2] = "E"
compassPoints[3] = nil
compassPoints[4] = "S"
compassPoints[5] = nil
compassPoints[6] = "W"
compassPoints[7] = nil

local function drawCompassRose()
  local hw = math.floor(120/2)
  local yawRounded = roundTo(yaw,1)
  local homeRounded = roundTo(homeAngle,1)
  local minY = 0 + 20 - 1
  local Hdy = math.sin(math.rad(270+homeRounded-yawRounded))*30
  local Hdx = math.cos(math.rad(270+homeRounded-yawRounded))*30
  for ang=0,7
  do
    local Rdy = math.sin(math.rad(45*ang+270-yawRounded))*30
    local Rdx = math.cos(math.rad(45*ang+270-yawRounded))*30
    local Ldy = math.sin(math.rad(45*ang+270-yawRounded))*(30-5)
    local Ldx = math.cos(math.rad(45*ang+270-yawRounded))*(30-5)
    if compassPoints[ang] == nil then
      lcd.drawLine((LCD_W/2)+Ldx,202+Ldy,(LCD_W/2)+Rdx,202+Rdy,SOLID,2)
    else
      lcd.drawText((LCD_W/2)+Rdx-(10/2),202+Rdy-(10/2),compassPoints[ang],0)
    end
  end
  drawHomeIcon((LCD_W/2)+Hdx-(10/2),202+Hdy-(10/2))
  --
  local xx = 0
  if ( yaw < 10) then
    xx = 1
  elseif (yaw < 100) then
    xx = -8
  else
    xx = -12
  end
  lcd.drawNumber((LCD_W/2) + xx - 5, 202 - 30 - 24, yaw, INVERS)
end

local function drawYaw()
 drawCompassRibbon()
end



local function getStep(step)
  if step < 3 then
    return 2
  end
  if step < 6 then
    return 5
  end
  if step < 11 then
    return 10
  end
  if step < 21 then
    return 20
  end
  return 2
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
local function drawHud()

  local r = -roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = 0 + 20 + 8
  -----------------------
  -- artificial horizon
  -----------------------
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
  local rollX = math.floor((LCD_W-70)/2 + 70/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 70x70
  local minY = 43
  local maxY = 113
  local minX = (LCD_W-70)/2 + 1
  local maxX = (LCD_W-70)/2 + 70
  --
  local ox = (LCD_W-70)/2 + 70/2 + dx
  --
  local oy = 80 + dy
  local yy = 0
  
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(179, 204, 255))
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(51, 102, 255))
  
  lcd.drawFilledRectangle(minX,minY,70,maxY - minY,CUSTOM_COLOR)
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-roll))
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
  if ( 0 <= -roll and -roll <= 90 ) then
      if (minxY > minY and maxxY < maxY) then
        -- 5
        lcd.drawFilledRectangle(minX, maxxY, maxX - minX, maxY - maxxY,CUSTOM_COLOR)
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle, CUSTOM_COLOR)
      elseif (minxY < minY and maxxY < maxY and maxxY > minY) then
        -- 6
        lcd.drawFilledRectangle(minX, minY, minyX - minX, maxxY - minY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(minX, maxxY, maxX - minX, maxY - maxxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle, CUSTOM_COLOR)
      elseif (minxY < minY and maxxY > maxY) then
        -- 7
        lcd.drawFilledRectangle(minX, minY, minyX - minX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle, CUSTOM_COLOR)
      elseif (minxY < maxY and minxY > minY) then
        -- 8
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle, CUSTOM_COLOR)
      elseif (minxY < minY and maxxY < minY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
  elseif (90 < -roll and -roll <= 180) then
      if (minxY < maxY and maxxY > minY) then
        -- 9
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY > minY and maxxY < maxY) then
        -- 10
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxxY - minY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(minX, maxxY, maxyX - minX, maxY - maxxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxyX < maxX) then
        -- 11
        lcd.drawFilledRectangle(minX, minY, maxyX - minX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY < maxY and minxY > minY) then
        -- 12
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY > maxY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
      -- 9,10,11,12
  elseif (-90 < -roll and -roll < 0) then
      if (minxY < maxY and maxxY > minY) then
        -- 1
        lcd.drawFilledRectangle(minX, minxY, maxX - minX, maxY - minxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY < maxY and maxxY < minY and minxY > minY) then
        -- 2
        lcd.drawFilledRectangle(minX, minxY, maxX - minX, maxY - minxY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(minyX, minY, maxX - minyX, minxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY < minY) then
        -- 3
        lcd.drawFilledRectangle(minyX, minY, maxX - minyX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY > minY and maxxY < maxY) then
        -- 4
        fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY < minY and maxxY < minY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
  elseif (-180 <= -roll and -roll <= -90) then
      if (minxY > minY and maxxY < maxY) then
        -- 13
        lcd.drawFilledRectangle(minX, minY, maxX - minX, minxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle,CUSTOM_COLOR);
      elseif (maxxY > maxY and minxY > minY and minxY < maxY) then
        -- 14
        lcd.drawFilledRectangle(minX, minY, maxX - minX, minxY - minY,CUSTOM_COLOR);
        lcd.drawFilledRectangle(maxyX, minxY, maxX - maxyX, maxY - minxY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY < minY and maxyX < maxX) then
        -- 15
        lcd.drawFilledRectangle(maxyX, minY, maxX - maxyX, maxY - minY,CUSTOM_COLOR);
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY < minY and maxxY > minY) then
        -- 16
        fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -roll, angle,CUSTOM_COLOR);
      elseif (minxY > maxY and maxxY > minY) then
        -- off screen
        lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
      end
  end
  --[[
  lcd.drawText(350,30,"R:",INVERS+SMLSIZE)
  lcd.drawNumber(430,30,roll,INVERS+SMLSIZE)
  lcd.drawText(350,50,"P:",INVERS+SMLSIZE)  
  lcd.drawNumber(430,50,pitch,INVERS+SMLSIZE)
  lcd.drawText(350,70,"angle",INVERS+SMLSIZE)
  lcd.drawNumber(430,70,angle*100,PREC2+INVERS+SMLSIZE)
  --]]  --[[
  lcd.drawText(350,100,"minxY:",INVERS+SMLSIZE)
  lcd.drawNumber(430,100,minxY,INVERS+SMLSIZE)
  lcd.drawText(350,120,"maxxY:",INVERS+SMLSIZE)
  lcd.drawNumber(430,120,maxxY,INVERS+SMLSIZE)
  --
  lcd.drawText(350,15,"minyX:",INVERS+SMLSIZE)
  lcd.drawNumber(430,150,minyX,INVERS+SMLSIZE)
  lcd.drawText(350,170,"maxyX:",INVERS+SMLSIZE)
  lcd.drawNumber(430,170,maxyX,INVERS+SMLSIZE)
  --]]  
  -- parallel lines above and below horizon of increasing length 5,7,16,16,7,5
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255))
  --
  drawCroppedLine(rollX + dx - cccx,dy + 80 + cccy,r,40,DOTTED,(LCD_W-70)/2,(LCD_W-70)/2 + 70,minY,maxY,CUSTOM_COLOR)
  drawCroppedLine(rollX + dx - ccx,dy + 80 + ccy,r,20,DOTTED,(LCD_W-70)/2,(LCD_W-70)/2 + 70,minY,maxY,CUSTOM_COLOR)
  drawCroppedLine(rollX + dx - cx,dy + 80 + cy,r,40,DOTTED,(LCD_W-70)/2,(LCD_W-70)/2 + 70,minY,maxY,CUSTOM_COLOR)
  drawCroppedLine(rollX + dx + cx,dy + 80 - cy,r,40,DOTTED,(LCD_W-70)/2,(LCD_W-70)/2 + 70,minY,maxY,CUSTOM_COLOR)
  drawCroppedLine(rollX + dx + ccx,dy + 80 - ccy,r,20,DOTTED,(LCD_W-70)/2,(LCD_W-70)/2 + 70,minY,maxY,CUSTOM_COLOR)
  drawCroppedLine(rollX + dx + cccx,dy + 80 - cccy,r,40,DOTTED,(LCD_W-70)/2,(LCD_W-70)/2 + 70,minY,maxY,CUSTOM_COLOR)
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(getBitmap("hud_70x70d"),(LCD_W-86)/2,32) --86x92
  -------------------------------------
  -- vario bitmap
  -------------------------------------
  local varioMax = math.log(5)
  local varioSpeed = math.log(1 + math.min(math.abs(0.05*vSpeed),4))
  local varioH = 0
  if vSpeed > 0 then
    varioY = math.min(79 - varioSpeed/varioMax*44,125)
  else
    varioY = 78
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0))
  lcd.drawFilledRectangle(176 + 2, varioY, 8, varioSpeed/varioMax*44, CUSTOM_COLOR, 0)  
  lcd.drawBitmap(getBitmap("variogauge"),176,24)
  if vSpeed > 0 then
    lcd.drawBitmap(getBitmap("varioline"),173,varioY)
  else
    lcd.drawBitmap(getBitmap("varioline"),173,78 + varioSpeed/varioMax*44)
  end
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255))
  -- altitude
  local alt = getMaxValue(homeAlt,23)
  --
  lcd.drawText(265,LCD_H-37,"alt(m)",SMLSIZE)
  if alt > 0 then
    if alt < 10 then -- 2 digits with decimal
      lcd.drawNumber(265,LCD_H-60,alt * 10,MIDSIZE+PREC1)
    else -- 3 digits
      lcd.drawNumber(265,LCD_H-60,alt,MIDSIZE)
    end
  else
    if alt > -10 then -- 1 digit with sign
      lcd.drawNumber(265,LCD_H-60,alt * 10,MIDSIZE+PREC1)
    else -- 3 digits with sign
      lcd.drawNumber(265,LCD_H-60,alt,MIDSIZE)
    end
  end
  -- vertical speed
  lcd.drawText(170,LCD_H-37,"vspd(m/s)",SMLSIZE)
  if (vSpeed > 999) then
    lcd.drawNumber(180,LCD_H-60,vSpeed*0.1,MIDSIZE+PREC1)
  elseif (vSpeed < -99) then
    lcd.drawNumber(180,LCD_H-60,vSpeed * 0.1,MIDSIZE+PREC1)
  else
    lcd.drawNumber(180,LCD_H-60,vSpeed,MIDSIZE+PREC1)
  end
  -- min/max arrows
  if showMinMaxValues == true then
    drawVArrow(265 - 13, LCD_H-60 + 2,6,true,false)
  end
end

local function drawGrid()
  lcd.drawLine((LCD_W-70)/2 - 1, 7 ,(LCD_W-70)/2 - 1, 57, SOLID, 0)
  lcd.drawLine((LCD_W-70)/2 + 70, 7, (LCD_W-70)/2 + 70, 57, SOLID, 0)
end

local function drawHomeDirection()
  local angle = math.floor(homeAngle - yaw)
  local x1 = (LCD_W/2) + 22 * math.cos(math.rad(angle - 90))
  local y1 = 202 + 22 * math.sin(math.rad(angle - 90))
  local x2 = (LCD_W/2) + 22 * math.cos(math.rad(angle - 90 + 150))
  local y2 = 202 + 22 * math.sin(math.rad(angle - 90 + 150))
  local x3 = (LCD_W/2) + 22 * math.cos(math.rad(angle - 90 - 150))
  local y3 = 202 + 22 * math.sin(math.rad(angle - 90 - 150))
  local x4 = (LCD_W/2) + 22 * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = 202 + 22 * 0.5 *math.sin(math.rad(angle - 270))
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
  -- once landed reset all alarms
  if timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0, 0} 
    elseif  alarms[idx][4] == 1 then
      alarms[idx] = { false, 0, true, 1, 0}
    elseif  alarms[idx][4] == 2 then
      alarms[idx] = { false, 0, true, 2, 0}
    elseif  alarms[idx][4] == 3 then
      alarms[idx] = { false, 0 , false, 3, 0}
    end
  end
  -- for minimum type alarms, arm the alarm only after value has reached level  
  if alarms[idx][3] == false and timerRunning == 1 and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][3] = true
  end
  -- if alarm is armed and value is "outside" level
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
      -- fire once but only every 2secs max
      if alarms[idx][2] == 0 then
        alarms[idx][1] = true
        alarms[idx][2] = flightTime
        if (flightTime - alarms[idx][5]) > 2 then
          playSound(sound)
          if alarms[idx][5] == 0 then
            alarms[idx][5] = flightTime
          end
        end
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

  for l=0,12 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    if batLevel <= batLevels[l] + 1 and l < lastBattLevel then
      lastBattLevel = l
      playSound("bat"..batLevels[l])
      break
    end
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

local function checkCellVoltage(battsource,cellmin,cellminFC,cellminA2)
  local celm = getVoltageBySource(battsource,cellmin,cellminFC,cellminA2)*100
  -- trigger batt1 and batt2
  if celm > conf.battAlertLevel2 and celm < conf.battAlertLevel1 and battLevel1 == false then
    battLevel1 = true
    playSound("batalert1")
  end
  if celm > 320 and celm < conf.battAlertLevel2 then
    battLevel2 = true
  end
  --
  checkAlarm(conf.battAlertLevel2,celm,7,-1,"batalert2",menuItems[14][4])  
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
    collectgarbage()
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
  -- blinking support
  if (getTime() - blinktime) > 65 then
    blinkon = not blinkon
    blinktime = getTime()
  end
  return 0
end
--------------------------
-- RUN
--------------------------
  -- EVT_EXIT_BREAK = RTN
  -- EVT_PAGEDN_FIRST/EVT_PAGEUP_FIRST PGUP/PGDN





local function run(event)
  background()
  lcd.clear()
  ---------------------
  -- SHOW MESSAGES
  ---------------------
  if showConfigMenu == false and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT) then
    showMessages = true
  end
  ---------------------
  -- SHOW CONFIG MENU
  ---------------------
  if showMessages == false and (event == 2053 or event == 2051 ) then
    showConfigMenu = true
    killEvents(event)
  end
  --
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
      showConfigMenu = false
      saveConfig()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if event == 518 then
      showMinMaxValues = not showMinMaxValues
    end
    if showDualBattery == true and event == EVT_EXIT_BREAK then
      showDualBattery = false
      killEvents(event)
    end
    if event == EVT_ROT_BREAK then
      cycleBatteryInfo()
    end
    drawHomeDirection()
    drawHud()
    drawCompassRibbon()
    --drawGrid()
    -- with dual battery default is to show aggregate view
    if batt2sources.fc or batt2sources.vs or batt2sources.a2 then
      if showDualBattery == false then
        -- dual battery: aggregate view
        lcd.drawText(285+67,85,"BATTERY: 1+2",SMLSIZE+INVERS)
        drawBatteryPane(285,battsource,batt1current+batt2current,getBatt1Capacity()+getBatt2Capacity(),batt1mah+batt2mah,calcCellMin(cell1min,cell2min),calcCellMin(cell1minFC,cell2minFC),cellminA2,calcCellMin(cell1sum,cell2sum),calcCellMin(cell1sumFC,cell2sumFC),cellsumA2,1,10,19)
      else
        -- dual battery:battery 1 right pane
        lcd.drawText(285+75,85,"BATTERY: 1",SMLSIZE+INVERS)
        drawBatteryPane(285,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,2,11,20)
        -- dual battery:battery 2 left pane
        lcd.drawText(50,85,"BATTERY: 2",SMLSIZE+INVERS)
        drawBatteryPane(-24,battsource,batt2current,getBatt2Capacity(),batt2mah,cell2min,cell2minFC,0,cell2sum,cell2sumFC,0,3,12,21)
      end
    else
      -- battery 1 right pane in single battery mode
      lcd.drawText(285+75,85,"BATTERY: 1",SMLSIZE+INVERS)
      drawBatteryPane(285,battsource,batt1current,getBatt1Capacity(),batt1mah,cell1min,cell1minFC,cellminA2,cell1sum,cell1sumFC,cellsumA2,2,11,20)
    end
    -- left pane info when not in dual battery mode
    if showDualBattery == false then
      -- power is always based on flight controller values
      drawLeftPane(batt1current+batt2current,calcCellMin(cell1sumFC,cell2sumFC))
    end
    drawFlightMode()
    drawTopBar()
    drawBottomBar()
    drawFlightTime()
    drawFailsafe()
    drawArmStatus()
    if showDualBattery == false then
    end
    drawNoTelemetryData()
  end
  return 0
end

local function init()
  loadConfig()
  pushMessage(6,"Yaapu Horus telemetry script 1.5.1-beta11")
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run, init=init}

