# Yaapu Frsky Telemetry script

A lua based telemetry script for the Taranis X9D+ radio using the frsky passthrough protocol.

Requires OpenTX 2.2 and a recent release of arducoper, arduplane or rover.

Tested on a pixracer with copter 3.5.3 and on a pixhawk clone with copter 3.5.4

![Taranis X9D+](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/screenshot_x9.JPG)


## Features

 - flight mode (modes are displayed based on the frame type:copter,plane or rover)
 - artificial horizon with roll,pitch and yaw with numeric compass heading
 - battery voltage from 3 sources (in order of priority)
 - - frsky FLVSS voltage sensor if available (vs is displayed next to voltage)
 - - frsky analog port if available (a2 is displayed next to voltage)
 - - flight controller via telemetry (fc is displayed next to voltage)
 - battery lowest cell if available or cell average if not
 - battery current
 - battery capacity and battery capacity used in mAh and %
 - vertical speed on left side of HUD
 - altitude on right side of HUD 
 - gps altitude
 - gps fix status and hdop
 - flight time
 - rssi value
 - transmitter voltage
 - home distance
 - horizontal speed
 - home heading as rotating triangle
 - mavlink messages with history accessible with +/- buttons short press
 - english sound files for selected events: battery levels, failsafe, flightmodes and landing

## Installation

The script is quite big and compilation on your radio may fail.
The safest way is to compile it on Companion and then copy the .luac compiled version to the SD card in the /SCRIPTS/TELEMETRY folder.

Note:On radios without the luac option enabled it is necessary to rename the script from yaapu9.luac to yaapu9.lua and from yaapu7.luac to yaapu7.lua

To enable sound files playback copy them to /SOUNDS/yaapu0/en folder.

## Hardware requirements

Please refer to the arducopter wiki for information on how to configure your flight controller for passthrough protocol
 - http://ardupilot.org/copter/docs/common-frsky-passthrough.html

For information on how to connect the FrSky equipment together, please refer to 
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#common-frsky-equipment
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#frsky-cables

## Test Mode

The script can be run in TEST mode. 
TEST mode is automatically enabled when you run the script in companion.
By using TEST mode you can control the telemetry values by moving the radio sticks.

PLEASE DO NOT FLY IN THIS MODE

To enable TEST mode you need to uncomment one line and recompile the script.

search for the following code
```lua
local flagSim = false
```
and change it to
```lua
local flagSim = true
```
Now you can test how the script behaves by using your radio channels 1,2,3,4,10 and 12.

## Notes

Speech sound files generated with https://soundoftext.com/

As of now only english is supported
