#include "includes/yaapu_inc.lua"

#define BATTCELL_X 75
#define BATTCELL_Y 70
#define BATTCELL_XV 76
#define BATTCELL_YS 72
#define BATTCELL_YV 86
#define BATTCELL_FLAGS DBLSIZE+RIGHT
#define BATTCELL_XI 7
#define BATTCELL_YI 74

#define BATTPERC_X 25
#define BATTPERC_Y 18
#define BATTPERC_YPERC 99
#define BATTPERC_FLAGS DBLSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 10
#define BATTGAUGE_Y 22
#define BATTGAUGE_WIDTH 80
#define BATTGAUGE_HEIGHT 32
#define BATTGAUGE_STEPS 10

#define BATTLABEL_X 90
#define BATTLABEL_Y 54
#define BATTLABEL_FLAGS SMLSIZE+RIGHT

#define IMUTEMP_X 90
#define IMUTEMP_Y 120
#define IMUTEMP_XLABEL 90
#define IMUTEMP_YLABEL 108

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
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white  
  
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
  
  -- labels
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(x+BATTLABEL_X,BATTLABEL_Y,battId == 0 and "B1+B2" or (battId == 1 and "B1" or "B2"),BATTLABEL_FLAGS+CUSTOM_COLOR)
  lcd.drawText(x+IMUTEMP_XLABEL, IMUTEMP_YLABEL, "IMUt", SMLSIZE+RIGHT+CUSTOM_COLOR)
  
  -- IMU Temperature
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  lcd.drawText(x+IMUTEMP_X, IMUTEMP_Y, string.format("%d@",telemetry.imuTemp), DBLSIZE+RIGHT+CUSTOM_COLOR)  
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+11, BATTCELL_Y + 8,false,true,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}