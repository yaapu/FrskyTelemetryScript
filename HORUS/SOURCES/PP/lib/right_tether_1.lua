#include "includes/yaapu_inc.lua"

#define BATTCELL_X 75
#define BATTCELL_Y 16
#define BATTCELL_XV 76
#define BATTCELL_YS 18
#define BATTCELL_YV 36
#define BATTCELL_FLAGS DBLSIZE+RIGHT
#define BATTCELL_XI 7
#define BATTCELL_YI 20

#define BATTCELL2_X 75
#define BATTCELL2_Y 72
#define BATTCELL2_XV 78
#define BATTCELL2_YS 72
#define BATTCELL2_YV 88
#define BATTCELL2_FLAGS DBLSIZE+RIGHT
#define BATTCELL2_XI 7
#define BATTCELL2_YI 76

#define BATTPERC_X 35
#define BATTPERC_Y 76
#define BATTPERC_YPERC 74
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTPERC2_X 35
#define BATTPERC2_Y 126
#define BATTPERC2_YPERC 124
#define BATTPERC2_FLAGS MIDSIZE
#define BATTPERC2_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 10
#define BATTGAUGE_Y 75
#define BATTGAUGE_WIDTH 80
#define BATTGAUGE_HEIGHT 21
#define BATTGAUGE_STEPS 10

#define BATTGAUGE2_X 10
#define BATTGAUGE2_Y 130
#define BATTGAUGE2_WIDTH 80
#define BATTGAUGE2_HEIGHT 21
#define BATTGAUGE2_STEPS 10

#define POWER_X 75
#define POWER_Y 46
#define POWER_XLABEL 77
#define POWER_YLABEL 53
#define POWER_FLAGS SMLSIZE

#define POWER2_X 75
#define POWER2_Y 103
#define POWER2_XLABEL 77
#define POWER2_YLABEL 110
#define POWER2_FLAGS SMLSIZE

#ifdef BATTPERC_BY_VOLTAGE
#define VOLTAGE_DROP 0.15
--[[
  Example data based on a 18 minutes flight for quad, battery:5200mAh LiPO 10C, hover @15A
  Notes:
  - when motors are armed VOLTAGE_DROP offset is applied!
  - number of samples is fixed at 11 but percentage values can be anything and are not restricted to multiples of 10
  - voltage between samples is assumed to be linear
--]]
local battPercByVoltage = { 
  {3.40,  0}, 
  {3.46, 10}, 
  {3.51, 20}, 
  {3.53, 30}, 
  {3.56, 40},
  {3.60, 50},
  {3.63, 60},
  {3.70, 70},
  {3.73, 80},
  {3.86, 90},
  {4.00, 99}
  }

function getBattPercByCell(cellVoltage)
  if cellVoltage == 0 then
    return 99
  end
  if cellVoltage >= battPercByVoltage[11][1] then
    return 99
  end
  if cellVoltage <= battPercByVoltage[1][1] then
    return 0
  end
  for i=2,11 do                                  
    if cellVoltage <= battPercByVoltage[i][1] then
      --
      local v0 = battPercByVoltage[i-1][1]
      local fv0 = battPercByVoltage[i-1][2]
      --
      local v1 = battPercByVoltage[i][1]
      local fv1 = battPercByVoltage[i][2]
      -- interpolation polinomial
      return fv0 + ((fv1 - fv0)/(v1-v0))*(cellVoltage - v0)
    end
  end --for
end
#endif --BATTPERC_BY_VOLTAGE

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
  local perc = 99
  #ifdef BATTPERC_BY_VOLTAGE
  if conf.enableBattPercByVoltage == true then
    --[[
      discharge curve is based on battery under load, when motors are disarmed
      cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    --]]
    if telemetry.statusArmed then
      perc = getBattPercByCell(0.01*battery[BATT_CELL+1])
    else
      perc = getBattPercByCell((0.01*battery[BATT_CELL+1])-VOLTAGE_DROP)
    end
  else
  #endif --BATTPERC_BY_VOLTAGE
  perc = battery[BATT_PERC+1]
  #ifdef BATTPERC_BY_VOLTAGE
  end --conf.enableBattPercByVoltage
  #endif --BATTPERC_BY_VOLTAGE
  
  local perc2 = 99
  #ifdef BATTPERC_BY_VOLTAGE
  if conf.enableBattPercByVoltage == true then
    --[[
      discharge curve is based on battery under load, when motors are disarmed
      cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    --]]
    if telemetry.statusArmed then
      perc = getBattPercByCell(0.01*battery[BATT_CELL+2])
    else
      perc = getBattPercByCell((0.01*battery[BATT_CELL+2])-VOLTAGE_DROP)
    end
  else
  #endif --BATTPERC_BY_VOLTAGE
  perc2 = battery[BATT_PERC+2]
  #ifdef BATTPERC_BY_VOLTAGE
  end --conf.enableBattPercByVoltage
  #endif --BATTPERC_BY_VOLTAGE
  
  -- battery 1 cell voltage (no alerts on battery 1)
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(200,200,200)) -- white
  lcd.drawFilledRectangle(x+7,BATTCELL_Y+5,86,52,CUSTOM_COLOR)
  --lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- white
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[BATT_CELL+1] * 0.01 < 10 then
    lcd.drawNumber(x+BATTCELL_X+2, BATTCELL_Y, battery[BATT_CELL+1] + 0.5, PREC2+BATTCELL_FLAGS+flags)
  else
    lcd.drawNumber(x+BATTCELL_X+2, BATTCELL_Y, (battery[BATT_CELL+1] + 0.5)*0.1, PREC1+BATTCELL_FLAGS+flags)
  end
  
  local lx = x+BATTCELL_XV
  lcd.drawText(lx, BATTCELL_YV, "V", flags)
  lcd.drawText(lx, BATTCELL_YS, status.battsource, flags)
  
  --  BATT2 Cell voltage
  flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[ALARMS_BATT_L2][ALARM_START] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+BATTCELL2_XI,BATTCELL2_YI)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+BATTCELL2_XI,BATTCELL2_YI)
    elseif status.battLevel1 == false and alarms[ALARMS_BATT_L1][ALARM_START] > 0 then
      --lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+BATTCELL2_XI,BATTCELL2_YI)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+BATTCELL2_XI,BATTCELL2_YI)
      lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[BATT_CELL+2] * 0.01 < 10 then
    lcd.drawNumber(x+BATTCELL2_X+2, BATTCELL2_Y, battery[BATT_CELL+2] + 0.5, PREC2+BATTCELL2_FLAGS+flags)
  else
    lcd.drawNumber(x+BATTCELL2_X+2, BATTCELL2_Y, (battery[BATT_CELL+2] + 0.5)*0.1, PREC1+BATTCELL2_FLAGS+flags)
  end
  
  lx = x+BATTCELL2_XV
  lcd.drawText(lx, BATTCELL2_YV, "V", flags)
  lcd.drawText(lx, BATTCELL2_YS, status.battsource, flags)
  
  -- BATTERY BAR % --
  --[[
  -- batt1 capacity bar %
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
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  --]]
  -- batt2 capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+BATTGAUGE2_X, BATTGAUGE2_Y,BATTGAUGE2_WIDTH,BATTGAUGE2_HEIGHT,CUSTOM_COLOR)
  if perc2 > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc2 <= 50 and perc2 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+BATTGAUGE2_X, BATTGAUGE2_Y,BATTGAUGE2_WIDTH,BATTGAUGE2_HEIGHT,perc2,100,CUSTOM_COLOR)
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  local strperc2 = string.format("%02d%%",perc2)
  lcd.drawText(x+BATTPERC2_X, BATTPERC2_Y, strperc2, BATTPERC2_FLAGS+CUSTOM_COLOR)
  
  -- POWER --
  -- power 1
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK)
  local power1 = battery[BATT_VOLT+1]*battery[BATT_CURR+1]*0.01
  lcd.drawNumber(x+POWER_X,POWER_Y,power1,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+POWER_XLABEL,POWER_YLABEL,"W",CUSTOM_COLOR)
  -- power 2
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  local power2 = battery[BATT_VOLT+2]*battery[BATT_CURR+2]*0.01
  lcd.drawNumber(x+POWER2_X,POWER2_Y,power2,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+POWER2_XLABEL,POWER2_YLABEL,"W",CUSTOM_COLOR)
  
  --[[
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+11, BATTCELL_Y + 8,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+11,BATTVOLT_Y + 3, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+11,BATTCURR_Y + 10,true,false,utils)
  end
  --]]
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}