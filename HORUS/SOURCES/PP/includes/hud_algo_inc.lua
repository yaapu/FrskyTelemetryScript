  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x0d, 0x68, 0xb1)) -- bighud blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.drawFilledRectangle(minX,minY,maxX-minX,maxY - minY,CUSTOM_COLOR)
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(77, 153, 0))
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x90, 0x63, 0x20)) --906320 bighud brown
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x63, 0x30, 0x00)) --623000 old brown
  
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- prevent divide by zero
  if telemetry.roll == 0 then
    drawLib.drawFilledRectangle(minX,math.max(minY,dy+minY+(maxY-minY)/2),maxX-minX,math.min(maxY-minY,(maxY-minY)/2-dy+(math.abs(dy) > 0 and 1 or 0)),CUSTOM_COLOR)
  elseif math.abs(telemetry.roll) >= 180 then
    drawLib.drawFilledRectangle(minX,minY,maxX-minX,math.min(maxY-minY,(maxY-minY)/2+dy),CUSTOM_COLOR)
  else
#ifdef HUD_ALGO1
    -- HUD drawn using vertical bars of width 2
    local step = 2
    local steps = (maxX - minX)/step
    local xx = 0
    local xxR = 0
    for s=0,steps -1
    do
      xx = minX + s*step
      xxR = xx + step
      if telemetry.roll > 90 or telemetry.roll < -90 then
        yy = (oy - ox*angle) + math.floor(xx*angle)
        if yy > minY + 1 and yy < maxY then
          lcd.drawFilledRectangle(xx,minY,step,yy-minY,CUSTOM_COLOR)
        elseif yy >= maxY then
          lcd.drawFilledRectangle(xx,minY,step,maxY-minY,CUSTOM_COLOR)
        end
      else
        yy = (oy - ox*angle) + math.floor(xx*angle)
        if yy <= minY then
          lcd.drawFilledRectangle(xx,minY,step,maxY-minY,CUSTOM_COLOR)
        elseif yy < maxY then
          lcd.drawFilledRectangle(xx,yy,step,maxY-yy+1,CUSTOM_COLOR)
        end
      end
    end
#endif --HUD_ALGO1
#ifdef HUD_ALGO2
    -- HUD drawn using boxes + horizontal bars of height 2
    local minxY = (oy - ox * angle) + minX * angle;
    local maxxY = (oy - ox * angle) + maxX * angle;
    local maxyX = (maxY - (oy - ox * angle)) / angle;
    local minyX = (minY - (oy - ox * angle)) / angle;
    --        
    if ( 0 <= -telemetry.roll and -telemetry.roll <= 90 ) then
        if (minxY > minY and maxxY < maxY) then
          -- 5
          lcd.drawFilledRectangle(minX, maxxY, maxX - minX, maxY - maxxY,CUSTOM_COLOR)
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle, CUSTOM_COLOR)
        elseif (minxY < minY and maxxY < maxY and maxxY > minY) then
          -- 6
          lcd.drawFilledRectangle(minX, minY, minyX - minX, maxxY - minY,CUSTOM_COLOR);
          lcd.drawFilledRectangle(minX, maxxY, maxX - minX, maxY - maxxY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle, CUSTOM_COLOR)
        elseif (minxY < minY and maxxY > maxY) then
          -- 7
          lcd.drawFilledRectangle(minX, minY, minyX - minX, maxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle, CUSTOM_COLOR)
        elseif (minxY < maxY and minxY > minY) then
          -- 8
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle, CUSTOM_COLOR)
        elseif (minxY < minY and maxxY < minY) then
          -- off screen
          lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
        end
    elseif (90 < -telemetry.roll and -telemetry.roll <= 180) then
        if (minxY < maxY and maxxY > minY) then
          -- 9
          lcd.drawFilledRectangle(minX, minY, maxX - minX, maxxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY > maxY and maxxY > minY and maxxY < maxY) then
          -- 10
          lcd.drawFilledRectangle(minX, minY, maxX - minX, maxxY - minY,CUSTOM_COLOR);
          lcd.drawFilledRectangle(minX, maxxY, maxyX - minX, maxY - maxxY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY > maxY and maxyX < maxX) then
          -- 11
          lcd.drawFilledRectangle(minX, minY, maxyX - minX, maxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY < maxY and minxY > minY) then
          -- 12
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY > maxY and maxxY > maxY) then
          -- off screen
          lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
        end
        -- 9,10,11,12
    elseif (-90 < -telemetry.roll and -telemetry.roll < 0) then
        if (minxY < maxY and maxxY > minY) then
          -- 1
          lcd.drawFilledRectangle(minX, minxY, maxX - minX, maxY - minxY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY < maxY and maxxY < minY and minxY > minY) then
          -- 2
          lcd.drawFilledRectangle(minX, minxY, maxX - minX, maxY - minxY,CUSTOM_COLOR);
          lcd.drawFilledRectangle(minyX, minY, maxX - minyX, minxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY > maxY and maxxY < minY) then
          -- 3
          lcd.drawFilledRectangle(minyX, minY, maxX - minyX, maxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY > minY and maxxY < maxY) then
          -- 4
          drawLib.fillTriangle(ox, oy, math.max(minX, maxyX), math.min(maxX, minyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY < minY and maxxY < minY) then
          -- off screen
          lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
        end
    elseif (-180 <= -telemetry.roll and -telemetry.roll <= -90) then
        if (minxY > minY and maxxY < maxY) then
          -- 13
          lcd.drawFilledRectangle(minX, minY, maxX - minX, minxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (maxxY > maxY and minxY > minY and minxY < maxY) then
          -- 14
          lcd.drawFilledRectangle(minX, minY, maxX - minX, minxY - minY,CUSTOM_COLOR);
          lcd.drawFilledRectangle(maxyX, minxY, maxX - maxyX, maxY - minxY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY < minY and maxyX < maxX) then
          -- 15
          lcd.drawFilledRectangle(maxyX, minY, maxX - maxyX, maxY - minY,CUSTOM_COLOR);
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY < minY and maxxY > minY) then
          -- 16
          drawLib.fillTriangle(ox, oy, math.max(minX, minyX), math.min(maxX, maxyX), -telemetry.roll, angle,CUSTOM_COLOR);
        elseif (minxY > maxY and maxxY > minY) then
          -- off screen
          lcd.drawFilledRectangle(minX, minY, maxX - minX, maxY - minY,CUSTOM_COLOR);
        end
    end
#endif --HUD_ALGO2
#ifdef HUD_ALGO3
    -- HUD drawn using horizontal bars of height 2
    -- true if flying inverted
    local inverted = math.abs(telemetry.roll) > 90
    -- true if part of the hud can be filled in one pass with a rectangle
    local fillNeeded = false
    local yRect = inverted and 0 or LCD_H
    
    local step = 2
    local steps = (maxY - minY)/step - 1
    local yy = 0
    
    if 0 < telemetry.roll and telemetry.roll < 180 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step,CUSTOM_COLOR)
        elseif xx < minX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    elseif -180 < telemetry.roll and telemetry.roll < 0 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(minX, yy, xx-minX, step,CUSTOM_COLOR)
        elseif xx > maxX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    end
    
    if fillNeeded then
      local yMin = inverted and minY or yRect
      local height = inverted and yRect - minY or maxY-yRect
      --lcd.setColor(CUSTOM_COLOR,COLOR_RED) --623000 old brown
      lcd.drawFilledRectangle(minX, yMin, maxX-minX, height ,CUSTOM_COLOR)
    end
#endif --HUD_ALGO3
  end
