local messages = {
  ---------------------
  -- PreArm
  ---------------------
  {
    "PreArm: Need 3D Fix",
    "PreArming: Need 3D Fix",
    "Home GPS assente"
  },
  { 
    "SmartRTL Unavailable, Trying RTL Mode",
    "Smart RTL Unavailable",
    "Smart RTL non disponibile"
  },
  {
    "EKF variance",
    "EKF variance",
    "Varianza E K F"
  },
  {
    "GPS Glitch cleared",
    "GPS Glitch cleared",
    "gps glitch corretto"
  },
  {
    "GPS Glitch",
    "GPS Glitch",
    "gps glitch"
  },
  {
    "Parachute: Released",
    "Parachute: Released",
    "paracadute lanciato",
  },
  {
    "Flight plan received",
    "Flight plan received",
    "nuovo piano di volo"
  },
  {
    "Mission complete, changing mode to RTL",
    "Mission complete",
    "missione completata"
  },
  {
    "Geofence triggered",
    "Geofence triggered",
    "raggiunta barriera gps"
  },
  {
    "Flight mode change failed",
    "Flight mode change failed",
    "Cambio modo di volo fallito"
  },
  ---------------
  -- AUTOTUNE
  ---------------
  {
    "AutoTune: Success",
    "AutoTune: Success",
    "AutoTiun: completato",
  },
  {
    "AutoTune: Failed",
    "AutoTune: Failed",
    "AutoTiun: fallito"
  },
  ---------------
  -- VTOL
  ---------------
  {
    "Transition FW done",
    "Transition done",
    "transizione completata"
  },
  {
    "Transition airspeed wait",
    "Transition started",
    "transizione iniziata"
  },
  {
    "Transition done",
    "Transition done",
    "transizione completata"
  },
  {
    "Transition VTOL done",
    "Transition VTOL done",
    "transizione completata"
  },
  {
    "Land descend started",
    "Land descend started",
    "inizio sequenza atterraggio",
  },
  {
    "Land final started",
    "Land final started",
    "atterraggio in corso",
  },
  
  ---------------
  -- SOARING
  ---------------
  {
    "Soaring: forcing RTL",
    "Soaring: forcing RTL",
    "rientro forzato in RTL"
  },
  {
    "Soaring: Thermal detected, entering loiter",
    "Soaring: Thermal detected",
    "inizio volo in termica"
  },
  {
    "Soaring: Thermal ended, entering RTL",
    "Soaring: Thermal ended",
    "fine volo in termica"
  },
  {
    "Soaring: Thermal ended, restoring CRUISE",
    "Soaring: Thermal ended",
    "fine volo in termica"
  },
  {
    "Soaring: Thermal ended, restoring AUTO",
    "Soaring: Thermal ended",
    "fine volo in termica"
  },
  
  ---------------------------------
  -- prefix hashes of max 16 chars
  ---------------------------------
  -- Reached command #%i
  {
    "Reached command ",
    "command: reached ",
    "comando raggiunto"
  },
  -- Reached waypoint #%i dist %um
  {
    "Reached waypoint",
    "waypoint: reached",
    "waypoint raggiunto"
  },
  -- Passed waypoint #%i dist %um
  {
    "Passed waypoint ",
    "Passed waypoint",
    "waypoint superato"
  },
  -- Takeoff complete at %.2fm
  {
    "Takeoff complete",
    "Takeoff complete",
    "decollo completato"
  },
  -- SmartRTL deactivated: %s
  {
    "SmartRTL deactiv",
    "SmartRTL deactivated",
    "Smart RTL disattivato"
  },
  -- EKF2 IMU0 is using GPS
  {
    "EKF2 IMU0 is usi",
    "GPS home acquired",
    "Acquisita Home GPS"
  },
  -- EKF3 IMU0 is using GPS
  {
    "EKF3 IMU0 is usi",
    "GPS home acquired",
    "Acquisita Home GPS"
  },
}


function fnv32(str)
	local hash = 2166136261
  local count = 0
	for char in string.gmatch(str, ".") do
    hash = bit32.bxor(hash, string.byte(char))
    hash = (hash * 16777619) % 2^32
	end

	return hash
end

local hashes = {}
for i=1,#messages
do
  hashes[i]=fnv32(messages[i][1])
end

print("{")
for i=1,#messages
do
  print(string.format("  %s, -- \"%s.wav\", \"%s\"",tostring(hashes[i]),tostring(hashes[i]),messages[i][1]))
end
print("}")

for i=1,#messages
do
  print(string.format("/SOUNDS/yaapu/en|%s|%s",tostring(hashes[i]),messages[i][2]))
end

for i=1,#messages
do
  print(string.format("/SOUNDS/yaapu/it|%s|%s",tostring(hashes[i]),messages[i][3]))
end
