    --[[
    // Auto Pilot Modes enumeration
    enum control_mode_t {
        LAND =          0,  // currently just stops moving
        MANUAL =        1,  // manual control
        VELOCITY =      2,  // velocity mode
        LOITER =        3,  // loiter mode (position hold)
    };
  --]]
  local flightModes = {}

  -- copter flight modes
  flightModes[0]=""
  flightModes[1]="Land"
  flightModes[2]="Manual"
  flightModes[3]="Velocity"
  flightModes[4]="Loiter"

return {flightModes=flightModes}
