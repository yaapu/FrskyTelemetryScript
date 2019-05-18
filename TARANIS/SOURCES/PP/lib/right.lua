#include "includes/yaapu_inc.lua"

#ifdef X9

#define BATTVOLT_X 0
#define BATTVOLT_Y 36
#define BATTVOLT_YV 36
#define BATTVOLT_FLAGS MIDSIZE+PREC1
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCELL_X 21
#define BATTCELL_Y 7
#define BATTCELL_YV 8
#define BATTCELL_YS 17
#define BATTCELL_FLAGS DBLSIZE

#define BATTCURR_X 61
#define BATTCURR_Y 36
#define BATTCURR_YA 36
#define BATTCURR_FLAGS MIDSIZE+PREC1
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 0
#define BATTPERC_Y 11
#define BATTPERC_YPERC 16
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 5
#define BATTGAUGE_Y 24
#define BATTGAUGE_WIDTH 50
#define BATTGAUGE_HEIGHT 3
#define BATTGAUGE_STEPS 10

#define BATTMAH_X 5
#define BATTMAH_Y 29
#define BATTMAH_FLAGS SMLSIZE+PREC1

-- power and efficiency
#define BATTPOWER_X 61
#define BATTPOWER_Y 49
#define BATTPOWER_XLABEL 0
#define BATTPOWER_YLABEL 49
#define BATTPOWER_FLAGS SMLSIZE+RIGHT

#else

#define BATTCELL_X 1
#define BATTCELL_Y 7
#define BATTCELL_YV 7
#define BATTCELL_YS 13
#define BATTCELL_FLAGS MIDSIZE

#define BATTVOLT_X 30
#define BATTVOLT_Y 19
#define BATTVOLT_YV 19
#define BATTVOLT_FLAGS SMLSIZE
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCURR_X 30
#define BATTCURR_Y 26
#define BATTCURR_YA 26
#define BATTCURR_FLAGS SMLSIZE
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 1
#define BATTPERC_Y 32
#define BATTPERC_YPERC 36
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTMAH_X 1
#define BATTMAH_Y 44
#define BATTMAH_FLAGS SMLSIZE+PREC1

#endif

--------------------
-- Single long function much more memory efficient than many little functions
---------------------
#ifdef X9
local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  local perc = 0
  if (battery[BATT_CAP+battId] > 0) then
    perc = math.min(math.max((1 - (battery[BATT_MAH+battId]/battery[BATT_CAP+battId]))*100,0),99)
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if status.showMinMaxValues == false then
    if status.battAlertLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif status.battAlertLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  -- cell voltage
  -- +0.5 because PREC2 does a math.floor()  and not a math.round()
  lcd.drawNumber(x+BATTCELL_X, BATTCELL_Y, (battery[BATT_CELL+battId] + 0.5)*(battery[BATT_CELL+battId] < 1000 and 1 or 0.1), BATTCELL_FLAGS+flags+(battery[BATT_CELL+battId] < 1000 and PREC2 or PREC1))
  -- save pos to print source and V
  local lx = lcd.getLastRightPos()
  -- battery voltage
  lcd.drawNumber(x+BATTVOLT_X, BATTVOLT_Y, battery[BATT_VOLT+battId]/10,MIDSIZE)
  lcd.drawText(lcd.getLastRightPos() - 1, BATTVOLT_Y, ".",MIDSIZE)
  lcd.drawNumber(lcd.getLastRightPos() - 1, BATTVOLT_Y+4, battery[BATT_VOLT+battId]%10,0)
  lcd.drawText(lcd.getLastRightPos()-1, BATTVOLT_YV, "V", SMLSIZE)
  -- battery current
  lcd.drawText(x+BATTCURR_X, BATTCURR_YA, "A", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTCURR_Y+4, battery[BATT_CURR+battId]%10,RIGHT)
  lcd.drawText(lcd.getLastLeftPos(), BATTCURR_Y, ".",MIDSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), BATTCURR_Y, battery[BATT_CURR+battId]/10,MIDSIZE+RIGHT)
  -- battery percentage
  lcd.drawNumber(x+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- display capacity bar %
  lcd.drawFilledRectangle(x+BATTGAUGE_X, BATTGAUGE_Y, perc/100*BATTGAUGE_WIDTH, BATTGAUGE_HEIGHT, SOLID+FORCE)
  local step = BATTGAUGE_WIDTH/BATTGAUGE_STEPS
  for s=1,BATTGAUGE_STEPS - 1 do
    lcd.drawLine(x+BATTGAUGE_X + s*step - 1,BATTGAUGE_Y, x+BATTGAUGE_X + s*step - 1, BATTGAUGE_Y + BATTGAUGE_HEIGHT - 1,SOLID,0)
  end
  -- battery mah
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y, battery[BATT_MAH+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "/", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), BATTMAH_Y, battery[BATT_CAP+battId]/100, BATTMAH_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "Ah", SMLSIZE)
  -- efficiency
  local eff = telemetry.hSpeed*0.1 > 2 and 1000*battery[BATT_CURR+battId]*0.1/(telemetry.hSpeed*0.1*UNIT_HSPEED_SCALE) or 0
  lcd.drawText(x+BATTPOWER_XLABEL, BATTPOWER_YLABEL, "Eff", SMLSIZE)
  lcd.drawText(x+BATTPOWER_X,BATTPOWER_Y,string.format("%d mAh",eff),BATTPOWER_FLAGS)
  --minmax
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTVOLT_X+23,BATTVOLT_Y + 8, 4,false,true)
    drawLib.drawVArrow(x+BATTCURR_X-3,BATTCURR_Y + 8,4,true,false)
    drawLib.drawVArrow(x+BATTCELL_X+33, BATTCELL_Y + 2 ,6,false,true)
  else
    lcd.drawText(lx, BATTCELL_YV, "V", dimFlags)
    lcd.drawText(lx, BATTCELL_YS, status.battsource, SMLSIZE)
  end  
end
#endif

#ifdef X7
local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  local perc = 0
  if (battery[BATT_CAP+battId] > 0) then
    perc = math.min(math.max((1 - (battery[BATT_MAH+battId]/battery[BATT_CAP+battId]))*100,0),99)
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if status.showMinMaxValues == false then
    if status.battAlertLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif status.battAlertLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  -- +0.5 because PREC2 does a math.floor()  and not a math.round()
  lcd.drawNumber(x+BATTCELL_X, BATTCELL_Y, (battery[BATT_CELL+battId] + 0.5)*(battery[BATT_CELL+battId] < 1000 and 1 or 0.1), BATTCELL_FLAGS+flags+(battery[BATT_CELL+battId] < 1000 and PREC2 or PREC1))
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+26, BATTCELL_Y+2,6,false,true)
  else
    local lx = lcd.getLastRightPos()
    lcd.drawText(lx-1, BATTCELL_YV, "V", dimFlags+SMLSIZE)
    --local xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
    local s = status.battsource == "a2" and "a" or (status.battsource == "vs" and "s" or "f")
    lcd.drawText(lx, BATTCELL_YS, s, SMLSIZE)  
  end
  -- battery voltage
  lcd.drawText(x+BATTVOLT_X, BATTVOLT_YV, "V", SMLSIZE+RIGHT)  
  lcd.drawNumber(lcd.getLastLeftPos(), BATTVOLT_Y, battery[BATT_VOLT+battId],SMLSIZE+PREC1+RIGHT)
  -- battery current
  lcd.drawText(x+BATTCURR_X, BATTCURR_YA, "A", SMLSIZE+RIGHT)  
  lcd.drawNumber(lcd.getLastLeftPos(), BATTCURR_Y, battery[BATT_CURR+battId],PREC1+SMLSIZE+RIGHT)
  -- battery percentage
  lcd.drawNumber(x+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos()+1, BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- battery mah
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y, battery[BATT_MAH+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "Ah", SMLSIZE)
  -- battery cap
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y+7, battery[BATT_CAP+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y+7, "Ah", SMLSIZE)
end
#endif

#ifdef CUSTOM_BG_CALL
local function background(conf,telemetry,status,getMaxValue,checkAlarm)
end
#endif 

return {
  drawPane=drawPane,
#ifdef CUSTOM_BG_CALL
  background=background
#endif
}