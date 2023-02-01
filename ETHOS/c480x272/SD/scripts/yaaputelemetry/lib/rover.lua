--[[
  // Auto Pilot modes
  // ----------------
  enum Number {
      MANUAL       = 0,
      ACRO         = 1,
      STEERING     = 3,
      HOLD         = 4,
      LOITER       = 5,
      FOLLOW       = 6,
      SIMPLE       = 7,
      AUTO         = 10,
      RTL          = 11,
      SMART_RTL    = 12,
      GUIDED       = 15,
      INITIALISING = 16
  };
--]]

local flightModes = {}

-- rover modes
flightModes[0]=""
flightModes[1]="Manual"
flightModes[2]="Acro"
flightModes[3]=""
flightModes[4]="Steering"
flightModes[5]="Hold"
flightModes[6]="Loiter"
flightModes[7]="Follow"
flightModes[8]="Simple"
flightModes[9]=""
flightModes[10]=""
flightModes[11]="Auto"
flightModes[12]="RTL"
flightModes[13]="SmartRTL"
flightModes[14]=""
flightModes[15]=""
flightModes[16]="Guided"
flightModes[17]="Initializing"
flightModes[18]=""
flightModes[19]=""
flightModes[20]=""
flightModes[21]=""
flightModes[22]=""
--
return {flightModes=flightModes}

