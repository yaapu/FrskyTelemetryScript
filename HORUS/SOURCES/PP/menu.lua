#include "includes/yaapu_inc.lua"

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
--]]
--[[

TYPEVALUE - menu option to select a numeric value
{description, type,name,default value,min,max,uit of measure,precision,increment step, <master name>, <master value>}
example {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V",PREC2,5,"L2",350 },

TYPECOMBO - menu option to select a value from a list
{description, type, name, default, label list, value list, <master name>, <master value>}
example {"center pane layout:", TYPECOMBO, "CPANE", 1, { "hud","radar" }, { 1, 2 },"CPANE",1 },

--]]
--
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
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 5,600,"sec",0,5 },
  {"dual battery config:", TYPECOMBO, "BC", 1, { "par", "ser", "other" }, { 1, 2, 3 } },
  {"batt[1] cell count override:", TYPEVALUE, "CC", 0, 0,12," cells",0,1 },
  {"batt[2] cell count override:", TYPEVALUE, "CC2", 0, 0,12," cells",0,1 },
  {"rangefinder max:", TYPEVALUE, "RM", 0, 0,10000," cm",0,10 },
  {"air/groundspeed unit:", TYPECOMBO, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vertical speed unit:", TYPECOMBO, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
  {"widget layout:", TYPECOMBO, "WL", 1, { "default","legacy"}, { 1, 2 } },
  {"center panel:", TYPECOMBO, "CPANE", 1, { "option 1","option 2","option 3","option 4" }, { 1, 2, 3, 4 } },
  {"right panel:", TYPECOMBO, "RPANE", 1, {  "option 1","option 2","option 3","option 4" }, { 1, 2, 3, 4 } },
  {"left panel:", TYPECOMBO, "LPANE", 1, {  "option 1","option 2","option 3","option 4" }, { 1 , 2, 3, 4 } },
  {"enable px4 flightmodes:", TYPECOMBO, "PX4", 1, { "no", "yes" }, { false, true } },
  {"screen toggle channel:", TYPEVALUE, "STC", 0, 0, 32,nil,0,1 },
  {"map zoom level:", TYPEVALUE, "MAPZ", -2, -2, 17,nil,0,1 },
  {"map type:", TYPECOMBO, "MAPT", 1, { "satellite", "map", "terrain" }, { "sat_tiles", "tiles", "ter_tiles" } },
  {"map grid lines:", TYPECOMBO, "MAPG", 1, { "yes", "no" }, { true, false } },
  {"map zoom channel:", TYPEVALUE, "ZTC", 0, 0, 32,nil,0,1 },
}

local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0,
  updated = true, -- if true menu needs a call to updateMenuItems()
  wrapOffset = 0, -- changes according to enabled/disabled features and panels
}

local basePath = "/SCRIPTS/YAAPU/"
local libBasePath = basePath.."LIB/"

local widgetLayoutFiles = {"layout_1","layout_2"}

local centerPanelFiles = {}
local rightPanelFiles = {}
local leftPanelFiles = {}

------------------------------------------
-- returns item's VALUE,LABEL,IDX
------------------------------------------
local function getMenuItemByName(items,name)
  for idx=1,#items
  do
    -- items[idx][3] is the menu item's name as it appears in the config file
    if items[idx][3] == name then
      if items[idx][2] ==  TYPECOMBO then
        -- return item's value, label, index
        return items[idx][6][items[idx][4]], items[idx][5][items[idx][4]], idx
      else
        -- return item's value, label, index
        return items[idx][4], name, idx
      end
    end
  end
  return nil
end

local function updateMenuItems()
  if menu.updated == true then
    local value, name, idx = getMenuItemByName(menuItems,"WL")
    if value == 1 then
      ---------------------
      -- large hud layout
      ---------------------
      value, name, idx = getMenuItemByName(menuItems,"CPANE")
      menuItems[idx][5] = { "default"};
      menuItems[idx][6] = { 1 };
      
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"RPANE")
      menuItems[idx][5] = { "default" };
      menuItems[idx][6] = { 1 };
      
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"LPANE")
      menuItems[idx][5] = { "default","mav2passthru" };
      menuItems[idx][6] = { 1, 2 };
      
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
      
      centerPanelFiles = {"hud_1", "hud_nav_1" }
      rightPanelFiles = {"right_1" }
      leftPanelFiles = {"left_1", "left_m2f_1" }
    
    elseif value == 2 then
      ---------------------
      -- legacy layout
      ---------------------
      value, name, idx = getMenuItemByName(menuItems,"CPANE")
      menuItems[idx][5] = { "default", "russian hud", "compact hud" };
      menuItems[idx][6] = { 1, 2, 3 };
      
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"RPANE")
      menuItems[idx][5] = { "default", "custom sensors" };
      menuItems[idx][6] = { 1, 2 };
      
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"LPANE")
      menuItems[idx][5] = { "default","mav2passthru" };
      menuItems[idx][6] = { 1, 2 };
      
      if menuItems[idx][4] > #menuItems[idx][5] then
        menuItems[idx][4] = 1
      end
      
      centerPanelFiles = {"hud_2", "hud_russian_2", "hud_small_2" }
      rightPanelFiles = {"right_2", "right_custom_2" }
      leftPanelFiles = {"left_2", "left_m2f_2" }
    end
    
    menu.updated = false
    collectgarbage()
    collectgarbage()
  end
end

local
function getConfigFilename()
  local info = model.getInfo()
  return "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues(conf)
  if menu.updated == true then
    updateMenuItems()
    menu.updated = false
  end
  conf.language = getMenuItemByName(menuItems,"L1")
  conf.battAlertLevel1 = getMenuItemByName(menuItems,"V1")
  conf.battAlertLevel2 = getMenuItemByName(menuItems,"V2")
  conf.battCapOverride1 = getMenuItemByName(menuItems,"B1")
  conf.battCapOverride2 = getMenuItemByName(menuItems,"B2")
  conf.disableAllSounds = getMenuItemByName(menuItems,"S1")
  conf.disableMsgBeep = getMenuItemByName(menuItems,"S2")
  conf.enableHaptic = getMenuItemByName(menuItems,"VIBR")
  conf.timerAlert = math.floor(getMenuItemByName(menuItems,"T1")*0.1*60)
  conf.minAltitudeAlert = getMenuItemByName(menuItems,"A1")*0.1
  conf.maxAltitudeAlert = getMenuItemByName(menuItems,"A2")
  conf.maxDistanceAlert = getMenuItemByName(menuItems,"D1")
  conf.repeatAlertsPeriod = getMenuItemByName(menuItems,"T2")
  conf.battConf = getMenuItemByName(menuItems,"BC")
  conf.cell1Count = getMenuItemByName(menuItems,"CC")
  conf.cell2Count = getMenuItemByName(menuItems,"CC2")
  conf.rangeFinderMax = getMenuItemByName(menuItems,"RM")
  conf.horSpeedMultiplier, conf.horSpeedLabel = getMenuItemByName(menuItems,"HSPD")
  conf.vertSpeedMultiplier, conf.vertSpeedLabel = getMenuItemByName(menuItems,"VSPD")
  -- Layout configuration
  conf.widgetLayout = getMenuItemByName(menuItems,"WL")
  conf.widgetLayoutFilename = widgetLayoutFiles[conf.widgetLayout]
  
  conf.centerPanel = getMenuItemByName(menuItems,"CPANE")
  conf.centerPanelFilename = centerPanelFiles[conf.centerPanel]
  
  conf.rightPanel = getMenuItemByName(menuItems,"RPANE")
  conf.rightPanelFilename = rightPanelFiles[conf.rightPanel]
  
  conf.leftPanel = getMenuItemByName(menuItems,"LPANE")
  conf.leftPanelFilename = leftPanelFiles[conf.leftPanel]
  
  conf.enablePX4Modes = getMenuItemByName(menuItems,"PX4")
  
  conf.mapZoomLevel = getMenuItemByName(menuItems,"MAPZ")
  conf.mapType = getMenuItemByName(menuItems,"MAPT")
  
  local chInfo = getFieldInfo("ch"..getMenuItemByName(menuItems,"STC"))
  conf.screenToggleChannelId = (chInfo == nil and -1 or chInfo['id'])
  
  chInfo = getFieldInfo("ch"..getMenuItemByName(menuItems,"ZTC"))
  conf.mapToggleChannelId = (chInfo == nil and -1 or chInfo['id'])
  
  conf.enableMapGrid = getMenuItemByName(menuItems,"MAPG")
  
  -- set default voltage source
  if getMenuItemByName(menuItems,"VS") ~= nil then
    conf.defaultBattSource = getMenuItemByName(menuItems,"VS")
  end
  
  menu.editSelected = false
  collectgarbage()
  collectgarbage()
end

local function loadConfig(conf)
  local cfg = io.open(getConfigFilename(),"r")
  if cfg ~= nil then
    local str = io.read(cfg,500)
    io.close(cfg)
    if string.len(str) > 0 then
      for i=1,#menuItems
      do
        local value = string.match(str, menuItems[i][3]..":([-%d]+)")
        collectgarbage()
        if value ~= nil then
          menuItems[i][4] = tonumber(value)
          -- check if the value read from file is compatible with available options
          if menuItems[i][2] == TYPECOMBO and tonumber(value) > #menuItems[i][5] then
            --if not force default
            menuItems[i][4] = 1
          end
        end
      end
    end
  end
  -- menu was loaded apply required changes
  menu.updated = true
  -- when run standalone there's nothing to update :-)
  if conf ~= nil then
    applyConfigValues(conf)
  end
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
  if cfg ~= nil then
    io.write(cfg,myConfig)
    io.close(cfg)
  end
  myConfig = nil
  collectgarbage()
  collectgarbage()
  -- when run standalone there's nothing to update :-)
  if conf ~= nil then
    applyConfigValues(conf)
  end
  model.setGlobalVariable(CONF_GV,CONF_FM_GV,1)
end

local function drawConfigMenuBars()
  lcd.setColor(CUSTOM_COLOR,COLOR_BARS)
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,TOPBAR_Y, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawRectangle(0, TOPBAR_Y, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawRectangle(0, BOTTOMBAR_Y, LCD_W, 20, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  lcd.drawText(2,0,VERSION,CUSTOM_COLOR)
  lcd.drawText(2,BOTTOMBAR_Y+1,getConfigFilename(),CUSTOM_COLOR)
  lcd.drawText(BOTTOMBAR_WIDTH,BOTTOMBAR_Y+1,itemIdx,CUSTOM_COLOR+RIGHT)
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
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)    
  if menuItems[idx][2] == TYPEVALUE then
    if menuItems[idx][4] == 0 and menuItems[idx][5] >= 0 then
      lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*20, "---",flags+CUSTOM_COLOR)
    else
      lcd.drawNumber(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*20, menuItems[idx][4],flags+menuItems[idx][8]+CUSTOM_COLOR)
      if menuItems[idx][7] ~= nil then
        lcd.drawText(MENU_ITEM_X + 50,MENU_Y + (idx-menu.offset-1)*20, menuItems[idx][7],flags+CUSTOM_COLOR)
      end
    end
  else
    lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*20, menuItems[idx][5][menuItems[idx][4]],flags+CUSTOM_COLOR)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  updateMenuItems()
  if event == EVT_ENTER_BREAK then
    if menu.editSelected == true then
      -- confirm modified value
      saveConfig()
    end
    menu.editSelected = not menu.editSelected
    menu.updated = true
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
    menu.offset =  #menuItems - MENU_PAGESIZE
  end
  --
  for m=1+menu.offset,math.min(#menuItems,MENU_PAGESIZE+menu.offset) do
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)   
    lcd.drawText(2,MENU_Y + (m-menu.offset-1)*20, menuItems[m][1],CUSTOM_COLOR)
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
local function compileLayouts()
  local files = {
    "layout_1", "layout_2", "layout_map",
    
    "hud_1",
    "right_1",
    "left_1", "left_m2f_1",
    
    "hud_2", "hud_russian_2", "hud_small_2",
    "right_2", "right_custom_2",
    "left_2", "left_m2f_2",
  }
  
  -- compile all layouts for all panes
  for i=1,#files do
    loadScript(libBasePath..files[i]..".lua","c")
  end
end
#endif

--------------------------
-- RUN
--------------------------
local function run(event)
  lcd.setColor(CUSTOM_COLOR, COLOR_BG) -- hex 0x084c7b -- 073f66
  lcd.clear(CUSTOM_COLOR)
  ---------------------
  -- CONFIG MENU
  ---------------------  
  drawConfigMenu(event)
  return 0
end

local function init()
  loadConfig()
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run, init=init, loadConfig=loadConfig, compileLayouts=compileLayouts, menuItems=menuItems}