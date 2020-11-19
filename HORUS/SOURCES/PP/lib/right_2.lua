#include "includes/yaapu_inc.lua"

#define BATTCELL_X 41
#define BATTCELL_Y 13
#define BATTCELL_XV 175
#define BATTCELL_YV 23
#define BATTCELL_YS 58
#define BATTCELL_FLAGS XXLSIZE

#define BATTVOLT_X 105
#define BATTVOLT_Y 79
#define BATTVOLT_XV 103
#define BATTVOLT_YV 79
#define BATTVOLT_FLAGS DBLSIZE+PREC1+RIGHT
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCURR_X 178
#define BATTCURR_Y 79
#define BATTCURR_XA 176
#define BATTCURR_YA 79
#define BATTCURR_FLAGS DBLSIZE+RIGHT
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 98
#define BATTPERC_Y 114
#define BATTPERC_YPERC 117
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 43
#define BATTGAUGE_Y 117
#define BATTGAUGE_WIDTH 147
#define BATTGAUGE_HEIGHT 23
#define BATTGAUGE_STEPS 10

#define BATTMAH_X 183
#define BATTMAH_Y 140
#define BATTMAH_FLAGS MIDSIZE

#define BATTEFF_X 478
#define BATTEFF_Y 178
#define BATTEFF_XLABEL 478
#define BATTEFF_YLABEL 165
#define BATTEFF_FLAGS SMLSIZE
#define BATTEFF_FLAGSW MIDSIZE

#define POWER_X 395
#define POWER_Y 178
#define POWER_XLABEL 395
#define POWER_YLABEL 165

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
      utils.drawBlinkBitmap("cell_red",x+BATTCELL_X - 2,BATTCELL_Y + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red"),x+BATTCELL_X - 2,BATTCELL_Y + 7)
    elseif status.battLevel1 == false and alarms[ALARMS_BATT_L1][ALARM_START] > 0 then
      --lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
      utils.drawBlinkBitmap("cell_orange_blink",x+BATTCELL_X - 2,BATTCELL_Y + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange"),x+BATTCELL_X - 2,BATTCELL_Y + 7)
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
  
  --lcd.drawNumber(x+BATTCELL_X+2, BATTCELL_Y, battery[BATT_CELL+battId] + 0.5, BATTCELL_FLAGS+flags)
  local lx = x+BATTCELL_XV
  lcd.drawText(lx, BATTCELL_YV, "V", flags)
  lcd.drawText(lx, BATTCELL_YS, status.battsource, flags)
  
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white  
  -- battery voltage
  drawLib.drawNumberWithDim(x+BATTVOLT_X,BATTVOLT_Y,x+BATTVOLT_XV, BATTVOLT_YV, battery[BATT_VOLT+battId],"V",BATTVOLT_FLAGS+CUSTOM_COLOR,BATTVOLT_FLAGSV+CUSTOM_COLOR)
  -- battery current
  drawLib.drawNumberWithDim(x+BATTCURR_X,BATTCURR_Y,x+BATTCURR_XA,BATTCURR_YA,battery[BATT_CURR+battId]*(battery[BATT_CURR+battId] >= 100 and 0.1 or 1),"A",BATTCURR_FLAGS+CUSTOM_COLOR+(battery[BATT_CURR+battId] >= 100 and 0 or PREC1),BATTCURR_FLAGSA+CUSTOM_COLOR)
  -- display capacity bar %
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawBitmap(utils.getBitmap("gauge_bg"),x+BATTGAUGE_X-2,BATTGAUGE_Y-2)
  lcd.drawGauge(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  
  -- battery mah
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  local strmah = string.format("%.02f/%.01f",battery[BATT_MAH+battId]/1000,battery[BATT_CAP+battId]/1000)
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y+6, "Ah", RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+BATTMAH_X - 22, BATTMAH_Y, strmah, BATTMAH_FLAGS+RIGHT+CUSTOM_COLOR)
    
  lcd.setColor(CUSTOM_COLOR,COLOR_DARK_GREY)
  local battLabel = "B1+B2"
  if battId == 0 then
    if conf.battConf ==  BATTCONF_OTHER then
      -- alarms are based on battery 1
      battLabel = "B1"
    elseif conf.battConf ==  BATTCONF_OTHER2 then
      -- alarms are based on battery 2
      battLabel = "B2"
    end
  else
    battLabel = (battId == 1 and "B1(Ah)" or "B2(Ah)")
  end
  
  lcd.drawText(x+190, 124, battLabel, SMLSIZE+CUSTOM_COLOR+RIGHT)
  
  if battId < 2 then
    -- RIGHT labels
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)  
    lcd.drawText(BATTEFF_XLABEL, BATTEFF_YLABEL, "Eff(mAh)", BATTEFF_FLAGS+RIGHT+CUSTOM_COLOR)
    lcd.drawText(POWER_XLABEL, POWER_YLABEL, "Power(W)", SMLSIZE+CUSTOM_COLOR+RIGHT)
    --data
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    -- efficiency for indipendent batteries makes sense only for battery 1
    local speed = utils.getMaxValue(telemetry.hSpeed,MAX_HSPEED)  
    local eff = speed > 2 and (conf.battConf == BATTCONF_OTHER and battery[BATT_CURR+1] or battery[BATT_CURR])*1000/(speed*UNIT_HSPEED_SCALE) or 0
    eff = ( conf.battConf == BATTCONF_OTHER and battId == 2) and 0 or eff
    lcd.drawNumber(BATTEFF_X,BATTEFF_Y,eff,BATTEFF_FLAGSW+RIGHT+CUSTOM_COLOR)
    -- power
    local power = battery[BATT_VOLT]*(conf.battConf == BATTCONF_OTHER and battery[BATT_CURR+1] or battery[BATT_CURR])*0.01
    lcd.drawNumber(POWER_X,POWER_Y,power,MIDSIZE+RIGHT+CUSTOM_COLOR)
  end
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+140, BATTCELL_Y + 27,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+4,BATTVOLT_Y + 10, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+3,BATTCURR_Y + 10,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}