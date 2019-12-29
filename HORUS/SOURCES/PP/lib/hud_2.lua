#include "includes/yaapu_inc.lua"
#include "includes/layout_2_inc.lua"

#define LEFTWIDTH   38
#define RIGHTWIDTH  38

#define HUD_WIDTH 160
#define HUD_HEIGHT 90
#define HUD_X (LCD_W-HUD_WIDTH)/2
#define HUD_Y 24
#define HUD_Y_MID 69

#define VARIO_X 310
#define VARIO_Y HUD_Y
#define VARIO_H HUD_HEIGHT/2
#define VARIO_W 10

-----------------------
-- COMPASS RIBBON
-----------------------
#define YAW_X (LCD_W-140)/2
#define YAW_Y 120
#define YAW_WIDTH 140

#define YAWICON_Y 3
#define YAWTEXT_Y 16
#define YAW_STEPWIDTH 15
#define YAW_SYMBOLS 16
#define YAW_X_MIN (LCD_W-YAW_WIDTH)/2
#define YAW_X_MAX (LCD_W+YAW_WIDTH)/2
#define R2 12


-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
#ifdef HUDTIMER
local hudDrawTime = 0
local hudDrawCounter = 0
#endif

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)
#ifdef HUDTIMER
  local hudStart = getTime()
#endif

  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch
    cx=0
    cy=R2
    ccx=0
    ccy=2*R2
    cccx=0
    cccy=3*R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * R2
    cy = math.sin(math.rad(90 - r)) * R2
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * R2
    ccy = math.sin(math.rad(90 - r)) * 2 * R2
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * R2
    cccy = math.sin(math.rad(90 - r)) * 3 * R2
  end
  local rollX = math.floor(HUD_X + HUD_WIDTH/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 140x90
  local minY = HUD_Y
  local maxY = HUD_Y + HUD_HEIGHT
  
  local minX = HUD_X
  local maxX = HUD_X + HUD_WIDTH
  
  local ox = HUD_X + HUD_WIDTH/2 + dx
  local oy = HUD_Y_MID + dy
  local yy = 0
  
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x0d, 0x68, 0xb1)) -- bighud blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.drawFilledRectangle(minX,minY,maxX-minX,maxY - minY,CUSTOM_COLOR)
  -- HUD
  #include "includes/hud_algo_inc.lua"

  -- parallel lines above and below horizon
  local linesMaxY = maxY-1
  local linesMinY = minY+1
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  -- +/- 90 deg
  for dist=1,8
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + HUD_Y_MID + dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + HUD_Y_MID - dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end
-- hashmarks
  local startY = minY + 1
  local endY = maxY - 10
  local step = 18
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(120,120,120))
  -- hSpeed 
  local roundHSpeed = math.floor((telemetry.hSpeed*UNIT_HSPEED_SCALE*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*UNIT_HSPEED_SCALE*0.1-roundHSpeed)*0.2*step);
  local ii = 0;  
  local yy = 0  
  for j=roundHSpeed+10,roundHSpeed-10,-5
  do
      yy = startY + (ii*step) + offset
      if yy >= startY and yy < endY then
        lcd.drawLine(HUD_X + 1, yy+9, HUD_X + 5, yy+9, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(HUD_X + 8,  yy, j, SMLSIZE+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  -- altitude 
  local roundAlt = math.floor((telemetry.homeAlt*UNIT_ALT_SCALE/5)+0.5)*5;
  offset = math.floor((telemetry.homeAlt*UNIT_ALT_SCALE-roundAlt)*0.2*step);
  ii = 0;  
  yy = 0
  for j=roundAlt+10,roundAlt-10,-5
  do
      yy = startY + (ii*step) + offset
      if yy >= startY and yy < endY then
        lcd.drawLine(HUD_X + HUD_WIDTH - 15, yy+8, HUD_X + HUD_WIDTH -10, yy+8, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(HUD_X + HUD_WIDTH - 16,  yy, j, SMLSIZE+RIGHT+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_160x90c"),(LCD_W-HUD_WIDTH)/2,HUD_Y) --160x90
  -------------------------------------
  -- vario bitmap
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*35
  if telemetry.vSpeed > 0 then
    varioY = VARIO_Y + 35 - varioH
  else
    varioY = VARIO_Y + 55
  end
  --00ae10
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0)) --yellow
  -- lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
  -- lcd.setColor(CUSTOM_COLOR,lcd.RGB(50, 50, 50)) --dark grey
  lcd.drawFilledRectangle(VARIO_X, varioY, VARIO_W, varioH, CUSTOM_COLOR, 0)  
  
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE
  if math.abs(alt) > 999 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
    lcd.drawNumber(HUD_X+HUD_WIDTH+1,HUD_Y_MID-10,alt,CUSTOM_COLOR+RIGHT)
  elseif math.abs(alt) >= 10 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
    lcd.drawNumber(HUD_X+HUD_WIDTH+1,HUD_Y_MID-14,alt,MIDSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
    lcd.drawNumber(HUD_X+HUD_WIDTH+1,HUD_Y_MID-14,alt*10,MIDSIZE+PREC1+CUSTOM_COLOR+RIGHT)
  end
  -- telemetry.hSpeed is in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,MAX_HSPEED) * 0.1 * UNIT_HSPEED_SCALE
  if (math.abs(hSpeed) >= 10) then
    lcd.drawNumber(HUD_X+2,HUD_Y_MID-14,hSpeed,MIDSIZE+CUSTOM_COLOR)
  else
    lcd.drawNumber(HUD_X+2,HUD_Y_MID-14,hSpeed*10,MIDSIZE+CUSTOM_COLOR+PREC1)
  end
#ifdef HUDTIMER
  hudDrawTime = hudDrawTime + (getTime() - hudStart)
  hudDrawCounter = hudDrawCounter + 1
#endif
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(HUD_X+50, HUD_Y_MID-9,true,false,utils)
    drawLib.drawVArrow(HUD_X+HUD_WIDTH-57, HUD_Y_MID-9,true,false,utils)
  end
  -- compass ribbon
  drawLib.drawCompassRibbon(YAW_Y,myWidget,conf,telemetry,status,battery,utils,YAW_WIDTH,YAW_X_MIN,YAW_X_MAX,YAW_STEPWIDTH,false)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}