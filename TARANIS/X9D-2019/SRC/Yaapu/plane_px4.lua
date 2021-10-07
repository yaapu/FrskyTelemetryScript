--[[
 MavToPT 2.63
 
 uint8_t PX4FlightModeNum(uint8_t main, uint8_t sub) {
     switch(main) {
        case 1:
          return 0;  // MANUAL 
        case 2:
          return 1;  // ALTITUDE       
        case 3:
          return 2;  // POSCTL      
        case 4:
          switch(sub) {
            case 1:
              return 12;  // AUTO READY
            case 2:
              return 13;  // AUTO TAKEOFF 
            case 3:
              return 14;  // AUTO LOITER  
            case 4:
              return 15;  // AUTO MISSION 
            case 5:
              return 16;  // AUTO RTL 
            case 6:
              return 17;  // AUTO LAND 
            case 7:
              return 18;  //  AUTO RTGS 
            case 8:
              return 19;  // AUTO FOLLOW ME 
            case 9:
              return 20;  //  AUTO PRECLAND 
            default:
              return 31;  //  AUTO UNKNOWN   
          } 
        case 5:
          return 3;  //  ACRO
        case 6:
          return 4;  //  OFFBOARD        
        case 7:
          return 5;  //  STABILIZED
        case 8:
          return 6;  //  RATTITUDE        
        case 9:
          return 7;  //  SIMPLE 
        default:
          return 11;  //  UNKNOWN                                        
       }
    }
--]]
local flightModes = {}
-- plane flight modes
flightModes[0]  = "Manual"
flightModes[1]  = "AltCtl"     --px4 specific
flightModes[2]  = "PosCtl"     --px4 specific
flightModes[3]  = "Acro"
flightModes[4]  = "OffBoard"   --px4 specific
flightModes[5]  = "Stabilize"
flightModes[6]  = "RAttitude"  --px4 specific
flightModes[7]  = "Simple"     --px4 specific
flightModes[8]  = ""
flightModes[9]  = ""
flightModes[10] = ""
flightModes[11] = ""
flightModes[12] = "Ready"     --px4 specific
flightModes[13] = "Takeoff"   --px4 specific
flightModes[14] = "Loiter"
flightModes[15] = "Mission"   --px4 specific
flightModes[16] = "RTL"
flightModes[17] = "Land"
flightModes[18] = ""
flightModes[19] = "Follow"
flightModes[20] = "PrecLand"  --px4 specific
flightModes[21] = ""
flightModes[22] = ""
flightModes[23] = ""
flightModes[24] = ""
flightModes[25] = ""
flightModes[26] = ""
flightModes[27] = ""
flightModes[28] = ""
flightModes[29] = ""
flightModes[30] = ""
flightModes[31] = "Unknown"

return {flightModes=flightModes}

