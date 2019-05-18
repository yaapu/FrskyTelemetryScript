#include "includes/yaapu_inc.lua"

--[[

TYPEVALUE - menu option to select a numeric value
{description, type,name,default value,min,max,uit of measure,precision,increment step}
example {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V",PREC2,5,"L2",350 },

TYPECOMBO - menu option to select a value from a list
{description, type, name, default, label list, value list}
example {"center pane layout:", TYPECOMBO, "CPANE", 1, { "hud","radar" }, { 1, 2 }},

--]]
#ifdef X9
local menuItems = {
  {"voice language:", TYPECOMBO, "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} },
  {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", TYPEVALUE, "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] capacity override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] capacity override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "info", "all" }, { 1, 2, 3 } },
  {"enable haptic:", TYPECOMBO, "VIBR", 1, { "no", "yes" }, { false, true } },
  {"default voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "fc" }, { nil, "vs", "fc" } },
  {"dual battery config:", TYPECOMBO, "BC", 1, { "par", "ser", "other" }, { 1, 2, 3 } },
  {"batt[1] cell count override:", TYPEVALUE, "CC", 0, 0,12," cells",0,1 },
  {"batt[2] cell count override:", TYPEVALUE, "CC2", 0, 0,12," cells",0,1 },
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
#ifdef HDOP_ALARM  
  {"max hdop alert:", TYPEVALUE, "HDOP", 20, 0,50,"m",PREC1,2 },  
#endif  
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 5,600,"sec",0,5 },
#ifdef MONITOR  
  {"altitude alert interval:", TYPEVALUE, "ALTM", 0, 0,1000,unitLabel,0,1 },
  {"distance alert interval:", TYPEVALUE, "DISTM", 0, 0,1000,unitLabel,0,1 },
#endif --MONITOR
  {"rangefinder max:", TYPEVALUE, "RM", 0, 0,10000," cm",0,10 },
#ifdef SYNTHVSPEED  
  {"enable synthetic vspeed:", TYPECOMBO, "SVS", 1, { "no", "yes" }, { false, true } },
#endif
  {"air/groundspeed unit:", TYPECOMBO, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vertical speed unit:", TYPECOMBO, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
  {"center panel layout:", TYPECOMBO, "CPANE", 1, { "def" }, { 1 } },
  {"right panel layout:", TYPECOMBO, "RPANE", 1, { "def" }, { 1 } },
  {"left panel layout:", TYPECOMBO, "LPANE", 1, { "def","m2f" }, { 1, 2 } },
  {"second view layout:", TYPECOMBO, "AVIEW", 1, { "def" }, { 1 } },
--[[  
  {"gas rpm label:", TYPECOMBO, "GAS_RPM", 1, { "Eng","Head" }, { 1, 2 },"RPANE",2 },
--]]
#ifdef LOGTELEMETRY  
  {"log messages to file:", TYPECOMBO, "LOG", 1, { "no","yes"}, { 1, 2 } },
#endif
  {"enable px4 flightmodes:", TYPECOMBO, "PX4", 1, { "no", "yes" }, { false, true } },
}
#else
local menuItems = {
  {"voice language:", TYPECOMBO, "L1", 1, { "eng", "ita", "fre", "ger" } , {"en","it","fr","de"} },
  {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", TYPEVALUE, "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] cap override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] cap override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "info", "all" }, { 1, 2, 3 } },
  {"enable haptic:", TYPECOMBO, "VIBR", 1, { "no", "yes" }, { false, true } },
  {"def voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "fc" }, { nil, "vs", "fc" } },
  {"dual battery config:", TYPECOMBO, "BC", 1, { "par", "ser", "other" }, { 1, 2, 3 } },
  {"batt[1] cells override:", TYPEVALUE, "CC", 0, 0,12,"s",0,1 },
  {"batt[2] cells override:", TYPEVALUE, "CC2", 0, 0,12,"s",0,1 },
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
#ifdef HDOP_ALARM  
  {"max hdop alert:", TYPEVALUE, "HDOP", 20, 0,50,"m",PREC1,2 },  
#endif  
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 5,600,"sec",0,5 },
#ifdef MONITOR  
  {"alt alert interval:", TYPEVALUE, "ALTM", 0, 0,1000,unitLabel,0,1 },
  {"dist alert interval:", TYPEVALUE, "DISTM", 0, 0,1000,unitLabel,0,1 },
#endif --MONITOR
  {"rangefinder max:", TYPEVALUE, "RM", 0, 0,10000," cm",0,10 },
#ifdef SYNTHVSPEED  
  {"enable synth.vspeed:", TYPECOMBO, "SVS", 1, { "no", "yes" }, { false, true } },
#endif
  {"air/groundspd unit:", TYPECOMBO, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vert speed unit:", TYPECOMBO, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
  {"center panel layout:", TYPECOMBO, "CPANE", 1, { "def" }, { 1 } },
  {"right panel layout:", TYPECOMBO, "RPANE", 1, { "def" }, { 1 } },
  {"left panel layout:", TYPECOMBO, "LPANE", 1, { "def","m2f" }, { 1, 2 } },
  {"second view layout:", TYPECOMBO, "AVIEW", 1, { "def" }, { 1 } },
--[[  
  {"gas rpm label:", TYPECOMBO, "GAS_RPM", 1, { "eng","head" }, { 1, 2 },"RPANE",2 },
--]]
#ifdef LOGTELEMETRY  
  {"enable message log:", TYPECOMBO, "LOG", 1, { "no","yes" }, { 1, 2 } },
#endif
  {"enable px4 modes:", TYPECOMBO, "PX4", 1, { "no", "yes" }, { false, true } },
}
#endif --X9

local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0,
}

#ifdef X9
local centerPanelFiles = {"hud9"}
local rightPanelFiles = {"right9"}
local leftPanelFiles = {"left9","left9_m2f"}
local altViewFiles = {"alt9_view"}
#else
local centerPanelFiles = {"hud7"}
local rightPanelFiles = {"right7"}
local leftPanelFiles = {"left7","left7_m2f"}
local altViewFiles = {"alt7_view"}
#endif

------------------------------------------
-- returns item's VALUE,LABEL,IDX
------------------------------------------
local function getMenuItemByName(items,name)
  for idx=1,#items
  do
    -- items[idx][3] is the menu item's name as it appears in the config file
    if items[idx][3] == name then
      if items[idx][2] ==  TYPECOMBO then
        -- return item's value, label and index
        return items[idx][6][items[idx][4]], items[idx][5][items[idx][4]], idx
      else
        -- return item's value, label and index
        return items[idx][4], name, idx
      end
    end
  end
  return nil
end

local function getConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

#ifdef LOGTELEMETRY  
local function getLogFilename()
  local date = getDateTime()
  local info = model.getInfo()
  local modelName = string.lower(string.gsub(info.name, "[%c%p%s%z]", ""))
  return string.format("/LOGS/%s-%04d%02d%02d_%02d%02d%02d.ylog",modelName,date.year,date.mon,date.day,date.hour,date.min,date.sec)
end
#endif --LOGTELEMETRY

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
  
  conf.centerPanel = centerPanelFiles[getMenuItemByName(items,"CPANE")]
  conf.rightPanel = rightPanelFiles[getMenuItemByName(items,"RPANE")]
  conf.leftPanel = leftPanelFiles[getMenuItemByName(items,"LPANE")]
  conf.altView = altViewFiles[getMenuItemByName(items,"AVIEW")]
  
  if getMenuItemByName(items,"VS") ~= nil then
    conf.defaultBattSource = getMenuItemByName(items,"VS")
  end
  
#ifdef SYNTHVSPEED  
  conf.enableSynthVSpeed = getMenuItemByName(items,"SVS")
#endif
#ifdef LOGTELEMETRY
  conf.logLevel = getMenuItemByName(items,"LOG")
  conf.logFilename = conf.logLevel > 1 and (conf.logFilename == nil and getLogFilename() or conf.logFilename) or nil 
#endif --LOGTELEMETRY
#ifdef MONITOR  
  conf.altMonitorInterval = getMenuItemByName(items,"ALTM")
  conf.distMonitorInterval = getMenuItemByName(items,"DISTM")
#endif
#ifdef HDOP_ALARM  
  conf.maxHdopAlert = getMenuItemByName(items,"HDOP")
#endif 
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
        local value = string.match(str, menuItems[i][3]..":([-%d]+)")
        collectgarbage()
        if value ~= nil then
          menuItems[i][4] = tonumber(value)
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
    myConfig = myConfig..menuItems[i][3]..":"..menuItems[i][4]
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
#ifdef X9
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawText(0,0,VERSION,SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y+1,getConfigFilename(),SMLSIZE+INVERS)
#endif --X9
#ifdef X7
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawText(0,0,VERSION,SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y-2, BOTTOMBAR_WIDTH, 9, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y-1,string.sub(getConfigFilename(),8),SMLSIZE+INVERS)
#endif --X7
  lcd.drawText(BOTTOMBAR_WIDTH,BOTTOMBAR_Y+1,itemIdx,SMLSIZE+INVERS+RIGHT)
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
      lcd.drawText(lcd.getLastRightPos(),MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][7],SMLSIZE+flags)
    end
  else
    lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][5][menuItems[idx][4]],SMLSIZE+flags)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK or event == XLITE_ENTER then
    menu.editSelected = not menu.editSelected
    menu.updated = true
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == EVT_PLUS_REPT or event == XLITE_UP) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_MINUS_REPT or event == XLITE_DOWN) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == XLITE_UP) then
    menu.selectedItem = (menu.selectedItem - 1)
    if menu.offset >=  menu.selectedItem then
      menu.offset = menu.offset - 1
    end
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == XLITE_DOWN) then
    menu.selectedItem = (menu.selectedItem + 1)
    if menu.selectedItem - MENU_PAGESIZE > menu.offset then
      menu.offset = menu.offset + 1
    end
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1 
    menu.offset = 0
  elseif menu.selectedItem  < 1 then
    menu.selectedItem = #menuItems
    menu.offset = #menuItems - MENU_PAGESIZE
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

#ifdef COMPILE
local function compilePanels()
  -- compile all layouts for all panes
  for i=1,#centerPanelFiles do
    loadScript(LIB_BASE_PATH..centerPanelFiles[i]..".lua","c")
  end
  for i=1,#rightPanelFiles do
    loadScript(LIB_BASE_PATH..rightPanelFiles[i]..".lua","c")
  end
  for i=1,#leftPanelFiles do
    loadScript(LIB_BASE_PATH..leftPanelFiles[i]..".lua","c")
  end
  for i=1,#altViewFiles do
    loadScript(LIB_BASE_PATH..altViewFiles[i]..".lua","c")
  end
end
#endif

return {
  drawConfigMenu=drawConfigMenu,
#ifdef LOGTELEMETRY  
  getLogFilename=getLogFilename,
#endif --LOGTELEMETRY  
  loadConfig=loadConfig,
  saveConfig=saveConfig,
  menuItems=menuItems,
  menu=menu,
#ifdef COMPILE
  compilePanels=compilePanels
#endif
}