--[[
  enum class Number : uint8_t {
      LAND =          0,  // currently just stops moving
      MANUAL =        1,  // manual control
      VELOCITY =      2,  // velocity mode
      LOITER =        3,  // loiter mode (position hold)
      RTL =           4,  // rtl
      // Mode number 30 reserved for "offboard" for external/lua control.
  };    
--]]
local flightModes = {}

-- copter flight modes
flightModes[0]=""
flightModes[1]="Land"
flightModes[2]="Manual"
flightModes[3]="Velocity"
flightModes[4]="Loiter"
flightModes[5]="Rtl"

return {flightModes=flightModes}
