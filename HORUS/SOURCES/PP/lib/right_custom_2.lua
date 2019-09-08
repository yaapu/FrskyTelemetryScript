#include "includes/yaapu_inc.lua"

#define BATTCELL_X 110
#define BATTCELL_Y 16
#define BATTCELL_XV 180
#define BATTCELL_YV 19
#define BATTCELL_YS 35
#define BATTCELL_FLAGS DBLSIZE

#define BATTVOLT_X 110
#define BATTVOLT_Y 48
#define BATTVOLT_XV 110
#define BATTVOLT_YV 46
#define BATTVOLT_FLAGS MIDSIZE+PREC1+RIGHT
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCURR_X 178
#define BATTCURR_Y 48
#define BATTCURR_XA 178
#define BATTCURR_YA 48
#define BATTCURR_FLAGS MIDSIZE+RIGHT+PREC1
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 63
#define BATTPERC_Y 27
#define BATTPERC_FLAGS 0
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 47
#define BATTGAUGE_Y 29
#define BATTGAUGE_WIDTH 58
#define BATTGAUGE_HEIGHT 16
#define BATTGAUGE_STEPS 10

#define BATTMAH_X 180
#define BATTMAH_Y 71
#define BATTMAH_FLAGS 0

#define BATTEFF_X 191
#define BATTEFF_Y 93
#define BATTEFF_YW 105
#define BATTEFF_FLAGS SMLSIZE
#define BATTEFF_FLAGSW 0

#define SENSOR1_X 110
#define SENSOR1_Y 101
#define SENSOR1_XLABEL 110
#define SENSOR1_YLABEL 90

#define SENSOR2_X 196
#define SENSOR2_Y 101
#define SENSOR2_XLABEL 196
#define SENSOR2_YLABEL 90

#define SENSOR3_X 110
#define SENSOR3_Y 132
#define SENSOR3_XLABEL 110
#define SENSOR3_YLABEL 123

#define SENSOR4_X 196
#define SENSOR4_Y 132
#define SENSOR4_XLABEL 196
#define SENSOR4_YLABEL 123

#define SENSOR5_X 110
#define SENSOR5_Y 173
#define SENSOR5_XLABEL 110
#define SENSOR5_YLABEL 163

#define SENSOR6_X 196
#define SENSOR6_Y 173
#define SENSOR6_XLABEL 196
#define SENSOR6_YLABEL 163


--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------
#define SENSOR_LABEL 1
#define SENSOR_NAME 2
#define SENSOR_PREC 3
#define SENSOR_UNIT 4
#define SENSOR_MULT 5
#define SENSOR_MAX 6
#define SENSOR_FONT 7
#define SENSOR_WARN 8
#define SENSOR_CRIT 9

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

local customSensorXY = {
  { SENSOR1_XLABEL, SENSOR1_YLABEL, SENSOR1_X, SENSOR1_Y},
  { SENSOR2_XLABEL, SENSOR2_YLABEL, SENSOR2_X, SENSOR2_Y},
  { SENSOR3_XLABEL, SENSOR3_YLABEL, SENSOR3_X, SENSOR3_Y},
  { SENSOR4_XLABEL, SENSOR4_YLABEL, SENSOR4_X, SENSOR4_Y},
  { SENSOR5_XLABEL, SENSOR5_YLABEL, SENSOR5_X, SENSOR5_Y},
  { SENSOR6_XLABEL, SENSOR6_YLABEL, SENSOR6_X, SENSOR6_Y},
}

local function drawCustomSensors(x,customSensors,utils,status)
    if customSensors == nil then
      return
    end
    
    local label,data,prec,mult,flags,sensorConfig
    for i=1,6
    do
      if customSensors.sensors[i] ~= nil then 
        sensorConfig = customSensors.sensors[i]
        
        if sensorConfig[SENSOR_UNIT] == "" then
          label = string.format("%s",sensorConfig[SENSOR_LABEL])
        else
          label = string.format("%s(%s)",sensorConfig[SENSOR_LABEL],sensorConfig[SENSOR_UNIT])
        end
        -- draw sensor label
        lcd.setColor(CUSTOM_COLOR,COLOR_BLACK)
        lcd.drawText(x+customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+CUSTOM_COLOR)
        
        mult =  sensorConfig[SENSOR_PREC] == 0 and 1 or ( sensorConfig[SENSOR_PREC] == 1 and 10 or 100 )
        prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)
        
        local sensorName = sensorConfig[SENSOR_NAME]..(status.showMinMaxValues == true and sensorConfig[SENSOR_MAX] or "")
        local sensorValue = getValue(sensorName) 
        local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[SENSOR_MULT]        
        
        -- default font size
        flags = (i<=2 and MIDSIZE or (sensorConfig[SENSOR_FONT] == 1 and MIDSIZE or DBLSIZE))
        
        -- for sensor 3,4,5,6 reduce font if necessary
        if i>2 and math.abs(value)*mult > 99999 then
          flags = MIDSIZE
        end

        local color = COLOR_TEXT
        local sign = sensorConfig[SENSOR_MAX] == "+" and 1 or -1
        
        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          color = ( sensorValue*sign > sensorConfig[SENSOR_CRIT]*sign and COLOR_CRIT or (sensorValue*sign > sensorConfig[SENSOR_WARN]*sign and COLOR_WARN or COLOR_TEXT))
        end
        
        lcd.setColor(CUSTOM_COLOR,color)
        
        local voffset = (i>2 and flags==MIDSIZE) and 5 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+CUSTOM_COLOR)
        else
          lcd.drawNumber(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+CUSTOM_COLOR)
        end
      end
    end
end

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
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils,customSensors)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  local perc = 0
  #ifdef BATTPERC_BY_VOLTAGE
  if conf.enableBattPercByVoltage == true then
    --[[
      discharge curve is based on battery under load, when motors are disarmed
      cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    --]]
    if telemetry.statusArmed then
      perc = getBattPercByCell(0.01*battery[BATT_CELL+battId])
    else
      perc = getBattPercByCell((0.01*battery[BATT_CELL+battId])-VOLTAGE_DROP)
    end
  else
  #endif --BATTPERC_BY_VOLTAGE
  if (battery[BATT_CAP+battId] > 0) then
    perc = (1 - (battery[BATT_MAH+battId]/battery[BATT_CAP+battId]))*100
    if perc > 99 then
      perc = 99
    elseif perc < 0 then
      perc = 0
    end
  end
  #ifdef BATTPERC_BY_VOLTAGE
  end --conf.enableBattPercByVoltage
  #endif --BATTPERC_BY_VOLTAGE
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[ALARMS_BATT_L2][ALARM_START] > 0 then
      utils.drawBlinkBitmap("cell_red_small",x+BATTCELL_X+1,BATTCELL_Y + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_small"),x+BATTCELL_X+1,BATTCELL_Y + 7)
    elseif status.battLevel1 == false and alarms[ALARMS_BATT_L1][ALARM_START] > 0 then
      --lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
      utils.drawBlinkBitmap("cell_orange_small_blink",x+BATTCELL_X+1,BATTCELL_Y + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_small"),x+BATTCELL_X+1,BATTCELL_Y + 7)
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
  lcd.drawText(lx, BATTCELL_YV, "V", SMLSIZE+flags)
  lcd.drawText(lx-2, BATTCELL_YS, status.battsource, SMLSIZE+flags)
  
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT) -- white  
  -- battery voltage
  drawLib.drawNumberWithDim(x+BATTVOLT_X,BATTVOLT_Y,x+BATTVOLT_XV, BATTVOLT_YV, battery[BATT_VOLT+battId],"V",BATTVOLT_FLAGS+CUSTOM_COLOR,BATTVOLT_FLAGSV+CUSTOM_COLOR)
  -- battery current
  drawLib.drawNumberWithDim(x+BATTCURR_X,BATTCURR_Y,x+BATTCURR_XA,BATTCURR_YA,battery[BATT_CURR+battId],"A",BATTCURR_FLAGS+CUSTOM_COLOR,BATTCURR_FLAGSA+CUSTOM_COLOR)
  -- display capacity bar %
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawBitmap(utils.getBitmap("gauge_bg_small"),x+BATTGAUGE_X,BATTGAUGE_Y)
  lcd.drawGauge(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  
  -- battery mah
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  local strmah = string.format("%.02f/%.01f",battery[BATT_MAH+battId]/1000,battery[BATT_CAP+battId]/1000)
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y+4, "Ah", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+BATTMAH_X - 22, BATTMAH_Y, strmah, BATTMAH_FLAGS+RIGHT+CUSTOM_COLOR)
    
  lcd.setColor(CUSTOM_COLOR,COLOR_DARK_GREY)
  --lcd.drawText(475,124,battId == 0 and "B1+B2" or (battId == 1 and "B1" or "B2"),SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.drawBitmap(utils.getBitmap("battbox_small"),x+42,21)

  -- do no show custom sensors when displaying 2nd battery info
  if battId < 2 then
    drawCustomSensors(x,customSensors,utils,status)
  end
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(LCD_W-12, BATTCELL_Y + 8,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+5,BATTVOLT_Y + 6, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+4,BATTCURR_Y + 6,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}