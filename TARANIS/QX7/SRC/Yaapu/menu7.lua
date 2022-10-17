--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry script for the Taranis class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
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
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"
local menuItems = {
  {"voice language:", "L1", 1, { "eng", "ita", "fre", "ger" } , {"en","it","fr","de"} },
  {"batt alert level 1:", "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] cap override:", "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] cap override:", "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[1] cells override:", "CC", 0, 0,12,"s",0,1 },
  {"batt[2] cells override:", "CC2", 0, 0,12,"s",0,1 },
  {"dual battery conf:", "BC", 1, { "par", "ser", "other-1", "other-2" }, { 1, 2, 3, 4 } },
  {"def voltage source:", "VS", 1, { "auto", "FLVSS", "fc" }, { nil, "vs", "fc" } },
  {"disable all sounds:", "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", "S2", 1, { "no", "info", "all" }, { 1, 2, 3 } },
  {"enable haptic:", "VIBR", 1, { "no", "yes" }, { false, true } },
  {"timer alert every:", "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", "T2", 10, 5,600,"sec",0,5 },
  {"rangefinder max:", "RM", 0, 0,10000," cm",0,10 },
  {"air/groundspd unit:", "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vert speed unit:", "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
  {"center panel layout:", "CPANE", 1, { "def", "min" }, { 1, 2 } },
  {"right panel layout:", "RPANE", 1, { "def", "min" }, { 1, 2 } },
  {"left panel layout:", "LPANE", 1, { "def","m2f" }, { 1, 2 } },
  {"second view layout:", "AVIEW", 1, { "def" }, { 1 } },
  {"enable px4 modes:", "PX4", 1, { "no", "yes" }, { false, true } },
  {"enable CRSF:", "CRSF", 1, { "no", "yes" }, { false, true } },
}

local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0,
}

local centerPanelFiles = {"hud7","hud7_min"}
local rightPanelFiles = {"right7","right7_min"}
local leftPanelFiles = {"left7","left7_m2f"}
local altViewFiles = {"alt7_view"}

------------------------------------------
-- returns item's VALUE,LABEL,IDX
------------------------------------------
local function getMenuItemByName(items,name)
  for idx=1,#items
  do
    -- items[idx][2] is the menu item's name as it appears in the config file
    if items[idx][2] == name then
      if type(items[idx][4]) ==  "table" then
        -- return item's value, label and index
        return items[idx][5][items[idx][3]], items[idx][4][items[idx][3]], idx
      else
        -- return item's value, label and index
        return items[idx][3], name, idx
      end
    end
  end
  return nil
end

local function getConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues(items,conf)
  conf.language = getMenuItemByName(items,"L1")
  conf.battAlertLevel1 = getMenuItemByName(items,"V1")
  conf.battAlertLevel2 = getMenuItemByName(items,"V2")
  conf.battCapOverride1 = getMenuItemByName(items,"B1")
  conf.battCapOverride2 = getMenuItemByName(items,"B2")
  conf.disableAllSounds = getMenuItemByName(items,"S1")
  conf.disableMsgBeep = getMenuItemByName(items,"S2")
  conf.timerAlert = math.floor(getMenuItemByName(items,"T1")*0.1*60)
  conf.minAltitudeAlert = getMenuItemByName(items,"A1")*0.1
  conf.maxAltitudeAlert = getMenuItemByName(items,"A2")
  conf.maxDistanceAlert = getMenuItemByName(items,"D1")
  conf.repeatAlertsPeriod = getMenuItemByName(items,"T2")
  conf.battConf = getMenuItemByName(items,"BC")
  conf.cell1Count = getMenuItemByName(items,"CC")
  conf.cell2Count = getMenuItemByName(items,"CC2")
  conf.rangeFinderMax = getMenuItemByName(items,"RM")
  conf.horSpeedMultiplier, conf.horSpeedLabel = getMenuItemByName(items,"HSPD")
  conf.vertSpeedMultiplier, conf.vertSpeedLabel = getMenuItemByName(items,"VSPD")
  conf.enablePX4Modes = getMenuItemByName(items,"PX4")
  conf.enableCRSF = getMenuItemByName(items,"CRSF")

  conf.centerPanel = centerPanelFiles[getMenuItemByName(items,"CPANE")]
  conf.rightPanel = rightPanelFiles[getMenuItemByName(items,"RPANE")]
  conf.leftPanel = leftPanelFiles[getMenuItemByName(items,"LPANE")]
  conf.altView = altViewFiles[getMenuItemByName(items,"AVIEW")]

  if getMenuItemByName(items,"VS") ~= nil then
    conf.defaultBattSource = getMenuItemByName(items,"VS")
  end

  conf.enableHaptic = getMenuItemByName(items,"VIBR")
  menu.editSelected = false
  collectgarbage()
  collectgarbage()
end

local function loadConfig(conf)
  local cfg = io.open(getConfigFilename(),"r")
  collectgarbage()
  collectgarbage()
  if cfg ~= nil then
    local str = io.read(cfg,200)
    io.close(cfg)
    if string.len(str) > 0 then
      for i=1,#menuItems
      do
        local value = string.match(str, menuItems[i][2]..":([-%d]+)")
        collectgarbage()
        if value ~= nil then
          menuItems[i][3] = tonumber(value)
          -- check if the value read from file is compatible with available options
          if type(menuItems[i][4]) == "table" and tonumber(value) > #menuItems[i][4] then
            --if not force default
            menuItems[i][3] = 1
          end
        end
      end
    end
  end
  collectgarbage()
  collectgarbage()
  applyConfigValues(menuItems,conf)
end

local function saveConfig(conf)
  local myConfig = ""
  for i=1,#menuItems
  do
    myConfig = myConfig..menuItems[i][2]..":"..menuItems[i][3]
    if i < #menuItems then
      myConfig = myConfig..","
    end
  end
  local cfg = assert(io.open(getConfigFilename(),"w"))
  collectgarbage()
  collectgarbage()
  if cfg ~= nil then
    io.write(cfg,myConfig)
    io.close(cfg)
  end
  myConfig = nil
  collectgarbage()
  collectgarbage()
  applyConfigValues(menuItems,conf)
end

local function drawConfigMenuBars()
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,0, 128, 7, SOLID)
  lcd.drawText(0,0,"Yaapu 2.0.0-dev".." ("..'d5cce31'..")",SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,LCD_H-8, 128, 8, SOLID)
  lcd.drawText(0,57-1,string.sub(getConfigFilename(),8),SMLSIZE+INVERS)
  lcd.drawText(128,57+1,itemIdx,SMLSIZE+INVERS+RIGHT)
end

local function incMenuItem(idx)
  if type(menuItems[idx][4]) == "table" then
    menuItems[idx][3] = menuItems[idx][3] + 1
    if menuItems[idx][3] > #menuItems[idx][4] then
      menuItems[idx][3] = 1
    end
  else
    menuItems[idx][3] = menuItems[idx][3] + menuItems[idx][8]
    if menuItems[idx][3] > menuItems[idx][5] then
      menuItems[idx][3] = menuItems[idx][5]
    end
  end
end

local function decMenuItem(idx)
  if type(menuItems[idx][4]) == "table" then
    menuItems[idx][3] = menuItems[idx][3] - 1
    if menuItems[idx][3] < 1 then
      menuItems[idx][3] = #menuItems[idx][4]
    end
  else
    menuItems[idx][3] = menuItems[idx][3] - menuItems[idx][8]
    if menuItems[idx][3] < menuItems[idx][4] then
      menuItems[idx][3] = menuItems[idx][4]
    end
  end
end

local function drawItem(idx,flags)
  if type(menuItems[idx][4]) == "table" then
    lcd.drawText(128-2,7 + (idx-menu.offset-1)*7, menuItems[idx][4][menuItems[idx][3]],SMLSIZE+flags+RIGHT)
  else
    if menuItems[idx][3] == 0 then
      lcd.drawText(128-2,7 + (idx-menu.offset-1)*7, "---",SMLSIZE+flags+menuItems[idx][7]+RIGHT)
    else
      lcd.drawText(128-2,7 + (idx-menu.offset-1)*7, menuItems[idx][6],SMLSIZE+flags+RIGHT)
      lcd.drawNumber(lcd.getLastLeftPos(),7 + (idx-menu.offset-1)*7, menuItems[idx][3],0+SMLSIZE+flags+menuItems[idx][7]+RIGHT)
    end
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK or event == 34 then
    menu.editSelected = not menu.editSelected
    menu.updated = true
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == EVT_PLUS_REPT or event == 36) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_MINUS_REPT or event == 35) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == 36) then
    menu.selectedItem = (menu.selectedItem - 1)
    if menu.offset >=  menu.selectedItem then
      menu.offset = menu.offset - 1
    end
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == 35) then
    menu.selectedItem = (menu.selectedItem + 1)
    if menu.selectedItem - 7 > menu.offset then
      menu.offset = menu.offset + 1
    end
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1
    menu.offset = 0
  elseif menu.selectedItem  < 1 then
    menu.selectedItem = #menuItems
    menu.offset = #menuItems - 7
  end
  --
  for m=1+menu.offset,math.min(#menuItems,7+menu.offset) do
    lcd.drawText(1,7 + (m-menu.offset-1)*7, menuItems[m][1],0+SMLSIZE)
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


return {
  drawConfigMenu=drawConfigMenu,
  loadConfig=loadConfig,
  saveConfig=saveConfig,
  menuItems=menuItems,
  menu=menu,
}
