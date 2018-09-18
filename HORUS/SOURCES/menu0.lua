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
-- Script Version 
---------------------
#define VERSION "Yaapu Telemetry Script 1.7.2"

--#define BATTPERC_BY_VOLTAGE

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 20
#define TOPBAR_WIDTH LCD_W

#define BOTTOMBAR_Y LCD_H - 20
#define BOTTOMBAR_HEIGHT 20
#define BOTTOMBAR_WIDTH LCD_W
--------------------------------------------------------------------------------
-- CONFIGURATION MENU
--------------------------------------------------------------------------------
#define TYPEVALUE 0
#define TYPECOMBO 1
#define MENU_Y 25
#define MENU_PAGESIZE 11
#ifdef BATTPERC_BY_VOLTAGE
#define MENU_WRAPOFFSET 9
#else
#define MENU_WRAPOFFSET 8
#endif
#define MENU_ITEM_X 300

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
#define CC 15
#define RM 16
#define SVS 17
#define HSPD 18
#define VSPD 19
#define BPBV 20
  
local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}

local menuItems = {}
 -- label, type, alias, currval, min, max, label, flags, increment 
menuItems[L1] = {"voice language:", TYPECOMBO, "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} }
menuItems[V1] = {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V", PREC2 ,5 }
menuItems[V2] = {"batt alert level 2:", TYPEVALUE, "V2", 350, 0,5000,"V", PREC2 ,5 }
menuItems[B1] = {"batt[1] capacity override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2 ,10 }
menuItems[B2] = {"batt[2] capacity override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2 ,10 }
menuItems[S1] = {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } }
menuItems[S2] = {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "yes" }, { false, true } }
menuItems[S3] = {"disable msg blink:", TYPECOMBO, "S3", 1, { "no", "yes" }, { false, true } }
menuItems[VS] = {"default voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } }
menuItems[T1] = {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 }
menuItems[A1] = {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 }
menuItems[A2] = {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 }
menuItems[D1] = {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 }
menuItems[T2] = {"repeat alerts every:", TYPEVALUE, "T2", 10, 5,600,"sec",0,5 }
menuItems[CC] = {"cell count override:", TYPEVALUE, "CC", 0, 0,12,"cells",0,1 }
menuItems[RM] = {"rangefinder max:", TYPEVALUE, "RM", 0, 0,10000," cm",0,10 }
menuItems[SVS] = {"enable synthetic vspeed:", TYPECOMBO, "SVS", 1, { "no", "yes" }, { false, true } }
menuItems[HSPD] = {"air/groundspeed unit:", TYPECOMBO, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} }
menuItems[VSPD] = {"vertical speed unit:", TYPECOMBO, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} }
#ifdef BATTPERC_BY_VOLTAGE  
menuItems[BPBV] = {"enable battery % by voltage:", TYPECOMBO, "BPBV", 1, { "no", "yes" }, { false, true } }
#endif --BATTPERC_BY_VOLTAGE
--

local function getConfigFilename()
  local info = model.getInfo()
  return "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
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
end

local function drawConfigMenuBars()
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,TOPBAR_Y, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawRectangle(0, TOPBAR_Y, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawText(2,0,VERSION,MENU_TITLE_COLOR)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawRectangle(0, BOTTOMBAR_Y, LCD_W, 20, TITLE_BGCOLOR)
  lcd.drawText(2,BOTTOMBAR_Y+1,getConfigFilename(),MENU_TITLE_COLOR)
  lcd.drawText(BOTTOMBAR_WIDTH,BOTTOMBAR_Y+1,itemIdx,MENU_TITLE_COLOR+RIGHT)
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
      lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*20, "---",flags)
    else
      lcd.drawNumber(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*20, menuItems[idx][4],flags+menuItems[idx][8])
      lcd.drawText(MENU_ITEM_X + 50,MENU_Y + (idx-menu.offset-1)*20, menuItems[idx][7],flags)
    end
  else
    lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*20, menuItems[idx][5][menuItems[idx][4]],flags)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK then
    if menu.editSelected == true then
      -- confirm modified value
      saveConfig()
    end
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
    menu.offset = MENU_WRAPOFFSET
  end
  --
  for m=1+menu.offset,math.min(#menuItems,MENU_PAGESIZE+menu.offset) do
    lcd.drawText(2,MENU_Y + (m-menu.offset-1)*20, menuItems[m][1],0+0)
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

--------------------------
-- RUN
--------------------------
local function run(event)
  lcd.clear()
  ---------------------
  -- CONFIG MENU
  ---------------------
  drawConfigMenu(event)
  return 0
end
#endif --WIDGET

local function init()
  loadConfig()
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run, init=init}