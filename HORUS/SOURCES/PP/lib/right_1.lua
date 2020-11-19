#include "includes/yaapu_inc.lua"

#define BATTCELL_X 75
#define BATTCELL_Y 16
#define BATTCELL_XV 76
#define BATTCELL_YS 18
#define BATTCELL_YV 32
#define BATTCELL_FLAGS DBLSIZE+RIGHT
#define BATTCELL_XI 7
#define BATTCELL_YI 20

#define BATTVOLT_X 77
#define BATTVOLT_Y 48
#define BATTVOLT_XV 77
#define BATTVOLT_YV 58
#define BATTVOLT_FLAGS RIGHT+MIDSIZE+PREC1
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCURR_X 75
#define BATTCURR_Y 68
#define BATTCURR_XA 76
#define BATTCURR_YA 83
#define BATTCURR_FLAGS DBLSIZE+RIGHT
#define BATTCURR_FLAGSA 0

#define BATTPERC_X 35
#define BATTPERC_Y 101
#define BATTPERC_YPERC 99
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 10
#define BATTGAUGE_Y 105
#define BATTGAUGE_WIDTH 80
#define BATTGAUGE_HEIGHT 21
#define BATTGAUGE_STEPS 10

#define BATTLABEL_X 90
#define BATTLABEL_Y 126
#define BATTLABEL_FLAGS SMLSIZE+RIGHT

#define BATTMAH_X 90
#define BATTMAH_Y 138
#define BATTMAH_FLAGS 0

#define POWER_X 95
#define POWER_Y 164
#define POWER_XLABEL 95
#define POWER_YLABEL 154

#define BATTEFF_X 12
#define BATTEFF_Y 164
#define BATTEFF_XLABEL 12
#define BATTEFF_YLABEL 154

-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
--[[
BATT_CELL 1
BATT_VOLT 4
BATT_CURR 7
BATT_MAH 10
BATT_CAP 13

BATT_IDALL 0
BATT_ID1 1
BATT_ID2 2
--]]
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  local perc = battery[BATT_PERC+battId]
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[ALARMS_BATT_L2][ALARM_START] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+BATTCELL_XI,BATTCELL_YI)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+BATTCELL_XI,BATTCELL_YI)
    elseif status.battLevel1 == false and alarms[ALARMS_BATT_L1][ALARM_START] > 0 then
      --lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+BATTCELL_XI,BATTCELL_YI)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+BATTCELL_XI,BATTCELL_YI)
      lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[BATT_CELL+battId] * 0.01 < 10 then
    lcd.drawNumber(x+BATTCELL_X+2, BATTCELL_Y, battery[BATT_CELL+battId] + 0.5, PREC2+BATTCELL_FLAGS+flags)
  else
    lcd.drawNumber(x+BATTCELL_X+2, BATTCELL_Y, (battery[BATT_CELL+battId] + 0.5)*0.1, PREC1+BATTCELL_FLAGS+flags)
  end
  
  local lx = x+BATTCELL_XV
  lcd.drawText(lx, BATTCELL_YV, "V", flags)
  lcd.drawText(lx, BATTCELL_YS, status.battsource, flags)
  
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white  
  -- battery voltage
  drawLib.drawNumberWithDim(x+BATTVOLT_X,BATTVOLT_Y,x+BATTVOLT_XV, BATTVOLT_YV, battery[BATT_VOLT+battId],"V",BATTVOLT_FLAGS+CUSTOM_COLOR,BATTVOLT_FLAGSV+CUSTOM_COLOR)
  -- battery current
  local lowAmp = battery[BATT_CURR+battId]*0.1 < 10
  drawLib.drawNumberWithDim(x+BATTCURR_X,BATTCURR_Y,x+BATTCURR_XA,BATTCURR_YA,battery[BATT_CURR+battId]*(lowAmp and 1 or 0.1),"A",BATTCURR_FLAGS+CUSTOM_COLOR+(lowAmp and PREC1 or 0),BATTCURR_FLAGSA+CUSTOM_COLOR)
  -- display capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,CUSTOM_COLOR)
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  
  -- battery mah
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  local strmah = string.format("%.02f/%.01f",battery[BATT_MAH+battId]/1000,battery[BATT_CAP+battId]/1000)
  --lcd.drawText(x+BATTMAH_X, BATTMAH_Y+2, "Ah", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y, strmah, BATTMAH_FLAGS+RIGHT+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  local battLabel = "B1+B2(Ah)"
  if battId == 0 then
    if conf.battConf ==  BATTCONF_OTHER then
      -- alarms are based on battery 1
      battLabel = "B1(Ah)"
    elseif conf.battConf ==  BATTCONF_OTHER2 then
      -- alarms are based on battery 2
      battLabel = "B2(Ah)"
    end
  else
    battLabel = (battId == 1 and "B1(Ah)" or "B2(Ah)")
  end
  lcd.drawText(x+BATTLABEL_X, BATTLABEL_Y, battLabel, BATTLABEL_FLAGS+CUSTOM_COLOR)
  if battId < 2 then
    -- labels
    lcd.drawText(x+BATTEFF_XLABEL, BATTEFF_YLABEL, "Eff(mAh)", SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(x+POWER_XLABEL, POWER_YLABEL, "Power(W)", SMLSIZE+CUSTOM_COLOR+RIGHT)
    -- data
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    local speed = utils.getMaxValue(telemetry.hSpeed,MAX_HSPEED)  
    -- efficiency for indipendent batteries makes sense only for battery 1
    local eff = speed > 2 and (conf.battConf == BATTCONF_OTHER and battery[BATT_CURR+1] or battery[BATT_CURR])*1000/(speed*UNIT_HSPEED_SCALE) or 0
    eff = ( conf.battConf == BATTCONF_OTHER and battId == 2) and 0 or eff
    lcd.drawNumber(x+BATTEFF_X,BATTEFF_Y,eff,(eff > 99999 and 0 or MIDSIZE)+RIGHT+CUSTOM_COLOR)
    -- power
    local power = battery[BATT_VOLT+battId]*battery[BATT_CURR+battId]*0.01
    lcd.drawNumber(x+POWER_X,POWER_Y,power,MIDSIZE+RIGHT+CUSTOM_COLOR)
    --lcd.drawText(x+POWER_X,POWER_Y,string.format("%dW",power),MIDSIZE+CUSTOM_COLOR)
  end
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+11, BATTCELL_Y + 8,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+11,BATTVOLT_Y + 3, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+11,BATTCURR_Y + 10,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}