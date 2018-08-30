# Yaapu Frsky Telemetry Script

This is the home of the Yaapu Telemetry Script project, a [LUA](https://www.lua.org/about.html) telemetry script for the Frsky Horus and Taranis radios using the ArduPilot frsky passthru telemetry protocol.

The supported radios are:
- Taranis X9D(+) and QX7 on OpenTX 2.2.1/2.2.2
- X-Lite on OpenTX 2.2.2 (by using the QX7 version)
- Horus X10(S) and X12 on OpenTX 2.2.1/2.2.2

Here you'll find
- a **Telemetry** script for the Taranis radios: X9D,QX7 and X-Lite ([changelog](https://github.com/yaapu/FrskyTelemetryScript/raw/master/taranis-changelog.txt))
- a **Widget** for the Horus radios: X10/S and X12  ([changelog](https://github.com/yaapu/FrskyTelemetryScript/raw/master/horus-changelog.txt))

both support all of the telemetry DIY 0x5000 packets sent by ardupilot’s [frsky passthrough protocol library](https://github.com/ArduPilot/ardupilot/tree/master/libraries/AP_Frsky_Telem)

The script is also compatible with the excellent [MavlinkToPassthru](https://github.com/zs6buj/MavlinkToPassthru) converter firmware by Eric Stockenstrom

Requires [OpenTX 2.2.1/2.2.2](http://www.open-tx.org/) and a recent release of [ArduPilot](http://ardupilot.org/ardupilot/index.html).

![X10](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10.png)

![X9D](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9d.png)

![X7](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7.png)


## Index

 - [display layout](#display-layout)
 - [features](#features)
 - [advanced features](#advanced-features)
 - [sensor discovery](#sensor-discovery-optional)
 - [supported flight modes](#supported-flight-modes)
 - [voltage sources](#voltage-sources)
 - [supported battery configurations](#supported-battery-configurations)
 - [cell count detection](#cell-count-detection)
 - [airspeed vs groundspeed](#airspeed-vs-groundspeed)
 - [alerts](#alerts)
 - [script timing and update rates](#script-timing-and-update-rates)
 - [configuration](#configuration)
 - [installation on Taranis](#installation-on-taranis)
 - [installation on Horus](#installation-on-horus)
 - [sound files customization](#sound-files-customization)
 - [compilation](#compilation)
 - [hardware requirements](#hardware-requirements)
 - [support and troubleshooting](#support-and-troubleshooting)
 - [credits](#credits)
 
## Screenshots

dual battery view

![X10dual](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10dualbattery.png)

![X9Ddual](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9ddual.png)

![X7dual](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7dual.png)

mavlink message history

![X10messages](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10messages.png)

![X9Dmessages](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dmessages.png)

![X7messages](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7messages.png)

## Display layout

![X12](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10displayinfo.png)

![X9D](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9displayinfo.png)

![QX7](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7displayinfo.png)

## Features

 - configuration menu, long press [MENU] on Taranis or [MDL] on Horus (in Widget mode refer to this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12-as-a-Widget#how-to-access-the-script-configuration-menu-while-in-widget-mode))
 - per model configuration saved in MODELS/yaapu/modelname.cfg on Taranis, SCRIPTS/YAAPU/CFG/modelname.cfg on Horus
 - imperial and metric units for altitude and distance inherited from radio settings
 - horizontal and vertical speed units selectable from script config menu
 - flight [modes](#supported-flight-modes) based on frame type:copter,plane or rover with vocal sound support
 - artificial horizon with roll,pitch and yaw with numeric compass heading
 - vertical variometer gauge on left side of center panel
 - rangefinder with max range support in config menu
 - mini home icon on yaw compass at home angle position
 - battery voltage from 3 sources, short pressing [ENTER]/[ENCODER] cycles between the sources
   - frsky FLVSS voltage sensor if available (vs is displayed next to voltage)
   - flight controller via telemetry (fc is displayed next to voltage)
   - frsky analog port if available (a2 is displayed next to voltage)
 - battery lowest cell if available or cell average if not
 - battery current
 - battery capacity and battery capacity used in mAh and % with vocal alerts for 90,80,70,60,50,40,30,25,20,15,10,4 levels
 - efficiency as battery current/speed, value in mAh
 - vertical speed on left side of HUD
 - "synthetic vertical speed" calculated from altitude variations (no vspeed is sent by the autopilot in DCM mode)
 - altitude on right side of HUD 
 - gps altitude
 - gps fix extendend status (2D,3D,DGPS,RTK)
 - gps HDop
 - satellite count (Note: the highest reported count is 15 sats due to telemetry library restrictions)
 - flight time (uses OpenTX timer 3) with vocal time alerts and spoken flight time
 - rssi value
 - transmitter voltage
 - home distance
 - horizontal ground speed or airspeed (available if configured in mission planner)
 - home heading as rotating triangle
 - mavlink messages with history accessible with [PLUS]/[MINUS] or by turning the [ENCODER] buttons (in Widget mode follow this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12-as-a-Widget#mandatory-steps))
 - english, italian, french and german sound files for selected events: battery levels, failsafe, flightmodes, alerts and landing
 - lcd panel backlight control for the Horus radios, see [this](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-enable-lcd-panel-backlight-support-on-X10-and-X12)


## Advanced Features 

- dual battery support (dual FLVSS and/or dual battery from ArduPilot) short press [ENTER] on Taranis or [ENCODER] on Horus to display second battery info. If a second battery is detected there will be a "B1+B2" label on screen (in Widget mode follow this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12-as-a-Widget#optional-steps))
 - capacity ovveride for battery 1 and 2
 - tracking of min/max values for battery/cell voltage, current, altitude, ground and vertical speed, short press [MENU] on Taranis or [SYS] on Horus to display them, an up pointing arrow will indicate max values whereas a down pointing arrow will indicate min values (in Widget mode follow this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12-as-a-Widget#optional-steps))
 
 ![X10 minmax](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10minmax.png)
 
 ![X9D minmax](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dminmax.png)
 
 ![X7 minmax](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7minmax.png)

 - vocal alerts for battery levels, 
 - vocal fence: max distance and min/max altitude alerts
 - configurable vocal timer alert every n minutes
 - sensors VFAS,CURR,Alt,VSpd,GAlt,Hdg,GSpd,Fuel,IMUt,ARM are exposed to OpenTX, see the [wiki](https://github.com/yaapu/FrskyTelemetryScript/wiki/Telemetry-sensors-exposed-to-OpenTX-by-the-Yaapu-script) for details.
 
## Sensor Discovery (Optional)

**Note: Sensor discovery is optional, the script works fine without this extra step**

On the Taranis you need to run "discover new sensors" in your model telemetry page to use the sensors in OpenTX, the script has to be running for this to work.
 
On the Horus the procedure is different: you start sensor discovery in the model telemetry page, leave it running and run the Yaapu Script as one time script or as a Widget. Go back to the telemetry page where discovery should still be running and all sensors should have been discovered.
If this does not work sensors can still be created manually in the model telemetry page.

Note: The A2 sensor (analog input port) will only be discovered on X4R and X6R receivers.
 
Sensor valus are passed to OpenTX only when the script receives valid telemetry from the rx!
 
## Supported Flight Modes

### Copter

| #  | flight mode | sound support |
|---:|:------------|:-----------|
|1|Stabilize|YES|
|2|Acro|YES|
|3|AltHold|YES|
|4|Auto|YES|
|5|Guided|YES|
|6|Loiter|YES|
|7|RTL|YES|
|8|Circle|YES|
|10|Land|YES|
|12|Drift|YES|
|14|Sport|YES|
|15|Flip|YES|
|16|AutoTune|YES|
|17|PosHold|YES|
|18|Brake|YES|
|19|Throw|YES|
|20|AvoidADSB|YES|
|21|GuidedNOGPS|YES|
|22|SmartRTL|YES|
|23|FlowHold|YES|
|24|Follow|YES|

### Plane
| #  | flight mode | sound support |
|---:|:------------|:-----------|
|1|Manual|YES|
|2|Circle|YES|
|3|Stabilize|YES|
|4|Training|YES|
|5|Acro|YES|
|6|FlyByWireA|YES|
|7|FlyByWireB|YES|
|8|Cruise|YES|
|9|Autotune|YES|
|11|Auto|YES|
|12|RTL|YES|
|13|Loiter|YES|
|15|AvoidADSB|YES|
|16|Guided|YES|
|17|Initializing|YES|
|18|QStabilize|YES|
|19|QHover|YES|
|20|QLoiter|YES|
|21|Qland|YES|
|22|QRTL|YES|

### Rover

| #  | flight mode | sound support |
|---:|:------------|:-----------|
|1|Manual|YES|
|2|Acro|YES|
|4|Steering|YES|
|5|Hold|YES|
|11|Auto|YES|
|12|RTL|YES|
|13|SmartRTL|YES|
|16|Guided|YES|
|17|Initializing|YES|

## Voltage Sources

Battery voltage is tracked independentely for 3 battery sources: FLVSS, analog port A2 and flight controller. (The script can use the A2 analog voltage source from X4R and X6R receivers, a2 would be displayed next to cell voltage). In single battery mode a short press of [ENTER] on Taranis or [ENCODER] on Horus cycles between all the sources. Min value is also tracked for the 3 sources and can be shown with a [MENU] short press on Taranis or [SYS] on the Horus.

Note:If you use a second FLVSS voltage sensor the OpenTX variable has to be renamed to "Cel2"

When a second battery is detected the script also tracks "aggregate" battery values and shows a "B1+B2" label in the right panel. Cell value and battery voltage is the "minimum" between the two batteries, current is summed and capacity percent is averaged. A short press of [MENU] on Taranis or [ENCODER] on the Horus will show min/max values for this aggregate view.

In dual battery mode a short press of [ENTER] on the Taranis or [ENCODER] on the Horus switches from single aggregate view to individual dual battery view. Subsequent short presses of [ENTER]/[ENCODER] in this dual view will cycle between voltage sources. In dual view a short press of [MENU] on Taranis or [SYS] on Horus shows individual packs min/max values.

To get back to aggregate view and retain the selected voltage source short press [EXIT] on Taranis or [RTN] on Horus.

**Note:In widget mode voltage source cycling is not available, the voltage source has to be selected from the menu**


## Supported battery configurations

- A2 analog port only: In this configuration only 1 battery will be detected,a2 will be displayed next to the cell voltage, Cell voltage is calculated as A2 battery voltage divided by cell count. No current or battery consumption will be availbale. If the user overrides battery capacity from the config menu battery % will be stuck at 99%.
- Single power module: In this configuration only 1 battery will be detected, fc will be displayed next to the cell voltage, Cell voltage is calculated as battery pack voltage divided by cell count. Current and consumed mAh will be reported. Battery percentage depends on battery capacity either received from ArduPilot or overriden from the menu.
- Dual power module: In this configuration 2 batteries will be detected, fc will be displayed next to the cell voltage, Cell voltage is calculated as battery pack voltage divided by cell count. Current and consumed mAh will be reported. Battery percentage depends on battery capacity either received from ArduPilot or overriden from the menu. Battery stats can be displayed in aggregate view or separate battery view (battery 1 in right pane and battery 2 in left pane).
In aggregate battery view Cell voltage is the minimun cell voltage between battery 1 and 2, current is the sum of current 1 and current 2, consumed mAh is the sum of mAh 1 and mAh 2 and battery percentage is the weighted average of percentage 1 and percentage 2
- Single FLVSS sensor:  In this configuration only 1 battery will be detected,vs will be displayed next to the cell voltage, Cell voltage is the minimum cell voltage of the pack. No current or battery consumption will be availbale. If the user overrides battery capacity from the config menu battery % will be stuck at 99%.
- Dual FLVSS sensor:  In this configuration only 2 batteries will be detected,vs will be displayed next to the cell voltage, Cell voltage is the minimum cell voltage of the pack. No current or battery consumption will be availbale. If the user overrides battery capacity from the config menu battery % will be stuck at 99%.
Battery stats can be displayed in aggregate view or separate battery view (battery 1 in right pane and battery 2 in left pane)
In aggregate battery view Cell voltage is the minimun cell voltage between battery 1 and 2.
- Single FLVSS sensor + single power module: voltage will be available from 2 sources, user can choose which one to display. Current will always be visible. 
- Dual FLVSS sensors + dual power module: voltage will be available from 2 sources, user can choose which one to display. Current will always be visible. Voltage and current visible in dual battery view as well as aggregate battery view.
- Dual FLVSS + single power module: voltage will be available from 2 sources, user can choose which one to display.The script assumes that the power module is monitoring the aggregate current from both batteries (in parallel), i.e. load is equally shared between the two batteries and the displayed current in dual battery view will be half on battery 1 and half on battery 2.

## Cell Count Detection

The script tries to autodetect the cell count by monitoring the maximum pack voltage.

If autodetection fails it's possible to override cell count in the configuration menu up to 12s.

## Airspeed vs Groundspeed

The frsky passthrough telemetry library can send on the radio link only 1 speed value.
Where it picks that speed value depends on arduplane configuration.

- ARSPD_TYPE > 0 : an airspeed sensor has been enabled in arduplane.
The telemetry library will try to use airspeed even if the sensor is unhealthy, if it’s unhealty the reported speed will be 0, with a healthy airspeed sensor the reported speed will be actual airspeed.

- ARSPD_TYPE = 0 : no airspeed sensor defined in arduplane. The telemetry library will always send groundspeed (gps)

To recap: the script has no control and simply displays what arduplane is sending based on airspeed sensor configuration.

## Alerts

There are 2 battery level alerts, both are set as cell voltage so independent from cell count. Battery level 1 should be set higher than battery level 2.

When cell voltage falls below level 1 it will trigger a vocal alert and the V next to the cell voltage will start blinking: once triggered blinking will persist even if the voltage raises above level 1.

When cell voltage falls below battery level 2 it will trigger a second vocal alert and the cell voltage digits will start blinking: once triggered blinking will persist even if the voltage raises above level 2.

If the battery reaches the failsafe level (it must be configured in mission planner) the script will display "batt failsafe" on the hud and play a vocal alert every n seconds (period can be configured from the menu).

It's also possible to configure a timer that will trigger a vocal alert every n minutes of flight time.

The script also support a "vocal fence" feature by setting a minimun altitude, a maximum altitude and a maximum distance alert.
When the vehicle moves outside of the fence the script will play a vocal alert every n seconds.

**Note: for versions 1.7.1 and above the battery monitoring engine has been modified to allow the voltage to drop below level for up to 4 seconds before triggering the alert. During this period the voltage background will flash to indicate that the alarm is about to be fired, if during this "grace" period the voltage raises above level the alarm is reset and not fired.**

## Script update rates

- The script processes telemetry up to 60Hz
- Screen is redrawn at 20Hz
- Frsky sensors are exposed to OpenTX at 4Hz
- Events and alarms are checked at 2Hz

## Configuration

![X10 menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10menu.png)

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dmenupag1.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7menupag1.png)

Complete menu options list:
- voice language: english, italian, french and german
- battery alert level 1, default is 3.75V
- battery alert level 2, default is 3.5V
- capacity override for battery 1
- capacity override for battery 2
- disable all sounds
- disable msg beep: disable sound on incoming message
- disable msg blink: disable text blink on incoming message
- default voltage source: disable autodetection and force either FLVSS,A2 or ArduPilot as battery voltage source
- timer alert every: play a vocal timer alert and speak flight time at configured intervals
- min altitude alert: minimum altitude vocal fence
- max altitude alert: maximum altitude vocal fence
- max distance alert: maximum distance vocal fence
- repeat alerts every: alert period in seconds
- cell count override: disable cell count detection and override it manually
- rangefinder max: enable rangefinder and enter maximum rangefinder distance
- enable synthetic vspeed: ignore telemetry vertical speed and calculate it from atitude variations
- ground/airspeed unit: select either m/s, km/h, mph, kn
- vertical speed unit: select either m/s, ft/s, ft/min

The language of the vocal alerts is independent from the radio language and can be configured from the menu.
Right now only english, italian and french are supported but new languages can be added with ease.

Battery capacity for battery 1 and battery 2 is automatically read from the values configured in mission planner but can both be overidden from the menu. When a new capacity is defined from the menu it will immediately be used in all calculations and it's value will be displayed on screen.

## Installation on Taranis

Copy the contents of the SD folder to your radio SD Card.

Make sure to have the /SOUNDS/yaapu0, MODELS/yaapu and /SCRIPTS/TELEMETRY/yaapu folders.

- For X9D/X9D+ and X9E radios use the yaapu9.luac script (use the yaapu9.lua if the radio doesn't start it, see the note below).
- For QX7 radios use the yaapu7.luac script (use yaapu7.lua if the radio doesn't start it, see the note below).
- For X-Lite radios use the yaapu7.luac script (use yaapu7.lua if the radio doesn't start it, see the note below).

The script is quite big and compilation on your radio will fail with a memory error.
The correct way is to compile it on Companion and then copy the .luac compiled version to the SD card in the /SCRIPTS/TELEMETRY folder on Taranis 

The correct folder structure for X9 series is

- /MODELS/yaapu/<modelname>.cfg
- /SCRIPTS/TELEMETRY/yaapu9.lua
- /SCRIPTS/TELEMETRY/yaapu9.luac
- /SCRIPTS/TELEMETRY/yaapu/copter.lua
- /SCRIPTS/TELEMETRY/yaapu/copter.luac
- /SCRIPTS/TELEMETRY/yaapu/plane.lua
- /SCRIPTS/TELEMETRY/yaapu/plane.luac
- /SCRIPTS/TELEMETRY/yaapu/rover.lua
- /SCRIPTS/TELEMETRY/yaapu/rover.luac
- /SOUNDS/yaapu0/en
- /SOUNDS/yaapu0/it
- /SOUNDS/yaapu0/fr
- /SOUNDS/yaapu0/de
 
For QX7 and X-Lite radios the correct folder structure is

- /MODELS/yaapu/<modelname>.cfg
- /SCRIPTS/TELEMETRY/yaapu7.lua
- /SCRIPTS/TELEMETRY/yaapu7.luac
- /SCRIPTS/TELEMETRY/yaapu/copter.lua
- /SCRIPTS/TELEMETRY/yaapu/copter.luac
- /SCRIPTS/TELEMETRY/yaapu/plane.lua
- /SCRIPTS/TELEMETRY/yaapu/plane.luac
- /SCRIPTS/TELEMETRY/yaapu/rover.lua
- /SCRIPTS/TELEMETRY/yaapu/rover.luac
- /SOUNDS/yaapu0/en
- /SOUNDS/yaapu0/it
- /SOUNDS/yaapu0/fr
- /SOUNDS/yaapu0/de

**Note: On radios without the luac option enabled it is necessary to use the .lua versions**

Please refer to the ardupilot [wiki](http://ardupilot.org/copter/docs/common-frsky-telemetry.html#assigning-a-display-script-to-a-screen) for instructions on how to assign the Yaapu script to a telemetry screen on your Taranis.

## Installation on Horus

Copy the contents of the SD folder to your radio SD Card.
Make sure you have the /SOUNDS/yaapu0, SCRIPTS/YAAPU/CFG, SCRIPTS/YAAPU/IMAGES and WIDGETS/Yaapu folders.

**Power cycle the radio to clear widget caches!**

The script can be started in 2 ways:

- **Widget** (recommended) see this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12-as-a-Widget)

- **One time script** by using the yaapux.lua or yaapux.luac script, see this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12)

**Note:** For the script to control the lcd panel backlight a few extra steps are required, please follow this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-enable-lcd-panel-backlight-support-on-X10-and-X12)

The script is quite big and compilation on your radio may fail with a memory error.
The correct way is to compile it on Companion and then copy the .luac compiled version to the SD card to the /SCRIPTS/YAAPU or /WIDGETS/Yaapu folder.

The correct folder structure is

- /SCRIPTS/YAAPU/CFG
- /SCRIPTS/YAAPU/IMAGES
- /SCRIPTS/YAAPU/yaapux.lua
- /SCRIPTS/YAAPU/yaapux.luac
- /SCRIPTS/YAAPU/menu.lua
- /SCRIPTS/YAAPU/menu.luac
- /SCRIPTS/YAAPU/LIB/copter.lua
- /SCRIPTS/YAAPU/LIB/copter.luac
- /SCRIPTS/YAAPU/LIB/plane.lua
- /SCRIPTS/YAAPU/LIB/plane.luac
- /SCRIPTS/YAAPU/LIB/rover.lua
- /SCRIPTS/YAAPU/LIB/rover.luac
- /SCRIPTS/YAAPU/LIB/init.lua
- /SCRIPTS/YAAPU/LIB/init.luac
- /SOUNDS/yaapu0/en
- /SOUNDS/yaapu0/it
- /SOUNDS/yaapu0/fr
- /SOUNDS/yaapu0/de
- /WIDGETS/Yaapu/main.lua
- /WIDGETS/Yaapu/main.luac 

**Note: On radios without the luac option enabled it is necessary to use the .lua versions**

## Sound files customization

All sound files are inside the SOUNDS/yaapu0/"language" folder, where language is a 2 chars language code.The following table is a list of all english files.
 
| folder path  | filename | TTS text |
|:---|:------------|:-----------| 
|SOUNDS/yaapu0/en|acro|Acro flight mode|
|SOUNDS/yaapu0/en|acro_r|Acro mode|
|SOUNDS/yaapu0/en|althold|Altitude hold flight mode|
|SOUNDS/yaapu0/en|armed|Motors armed|
|SOUNDS/yaapu0/en|auto|Auto flight mode|
|SOUNDS/yaapu0/en|auto_r|Auto mode|
|SOUNDS/yaapu0/en|autotune|Autotune enabled|
|SOUNDS/yaapu0/en|avoidadsb|Avoid A D S B flight mode|
|SOUNDS/yaapu0/en|bat5|Battery at 5 percent|
|SOUNDS/yaapu0/en|bat10|Battery at 10 percent|
|SOUNDS/yaapu0/en|bat15|Battery at 15 percent|
|SOUNDS/yaapu0/en|bat20|Battery at 20 percent|
|SOUNDS/yaapu0/en|bat25|Battery at 25 percent|
|SOUNDS/yaapu0/en|bat30|Battery at 30 percent|
|SOUNDS/yaapu0/en|bat40|Battery at 40 percent|
|SOUNDS/yaapu0/en|bat50|Battery at 50 percent|
|SOUNDS/yaapu0/en|bat60|Battery at 60 percent|
|SOUNDS/yaapu0/en|bat70|Battery at 70 percent|
|SOUNDS/yaapu0/en|bat80|Battery at 80 percent|
|SOUNDS/yaapu0/en|bat90|Battery at 90 percent|
|SOUNDS/yaapu0/en|batalert|Battery alert|
|SOUNDS/yaapu0/en|batalert1|Battery level 1 alert|
|SOUNDS/yaapu0/en|batalert2|Battery level 2 alert|
|SOUNDS/yaapu0/en|brake|Brake flight mode|
|SOUNDS/yaapu0/en|circle|Circle flight mode|
|SOUNDS/yaapu0/en|cruise|Cruise flight mode|
|SOUNDS/yaapu0/en|disarmed|Motors disarmed|
|SOUNDS/yaapu0/en|drift|Drift flight mode|
|SOUNDS/yaapu0/en|ekf|E K F failsafe|
|SOUNDS/yaapu0/en|flip|Flip flight mode|
|SOUNDS/yaapu0/en|flowhold|flow hold flight mode|
|SOUNDS/yaapu0/en|follow|follow flight mode|
|SOUNDS/yaapu0/en|flybywirea|Fly by wire a flight mode|
|SOUNDS/yaapu0/en|flybywireb|Fly by wire b flight mode|
|SOUNDS/yaapu0/en|gpsfix|GPS 3D fix lock|
|SOUNDS/yaapu0/en|gpsnofix|No gps|
|SOUNDS/yaapu0/en|guided|Guided flight mode|
|SOUNDS/yaapu0/en|guided_r|Guided mode|
|SOUNDS/yaapu0/en|guidednogps|Guided no gps flight mode|
|SOUNDS/yaapu0/en|hold_r|Hold mode|
|SOUNDS/yaapu0/en|initializing|Initializing|
|SOUNDS/yaapu0/en|land|Land flight mode|
|SOUNDS/yaapu0/en|landing|Landing complete|
|SOUNDS/yaapu0/en|loiter|Loiter flight mode|
|SOUNDS/yaapu0/en|lowbat|Low battery|
|SOUNDS/yaapu0/en|manual|Manual flight mode|
|SOUNDS/yaapu0/en|manual_r|Manual mode|
|SOUNDS/yaapu0/en|maxalt|Max altitude alert|
|SOUNDS/yaapu0/en|maxdist|Max distance alert|
|SOUNDS/yaapu0/en|minalt|Low altitude alert|
|SOUNDS/yaapu0/en|poshold|Position hold flight mode|
|SOUNDS/yaapu0/en|qhover|Q hover flight mode|
|SOUNDS/yaapu0/en|qland|Q land flight mode|
|SOUNDS/yaapu0/en|qloiter|Q loiter flight mode|
|SOUNDS/yaapu0/en|qrtl|Q return to home flight mode|
|SOUNDS/yaapu0/en|qstabilize|Q stabilize flight mode|
|SOUNDS/yaapu0/en|rtl|Return to home|
|SOUNDS/yaapu0/en|rtl_r|Return to home mode|
|SOUNDS/yaapu0/en|simpleon|simple mode enabled|
|SOUNDS/yaapu0/en|simpleoff|simple mode disabled|
|SOUNDS/yaapu0/en|ssimpleon|super simple mode enabled|
|SOUNDS/yaapu0/en|ssimpleoff|super simple mode disabled|
|SOUNDS/yaapu0/en|smartrtl|Smart return to home flight mode|
|SOUNDS/yaapu0/en|smartrtl_r|Smart return to home mode|
|SOUNDS/yaapu0/en|sport|Sport flight mode|
|SOUNDS/yaapu0/en|stabilize|Stabilize flight mode|
|SOUNDS/yaapu0/en|steering_r|Steering mode|
|SOUNDS/yaapu0/en|throw|Throw flight mode|
|SOUNDS/yaapu0/en|timealert|Timer alert|
|SOUNDS/yaapu0/en|training|Training flight mode|
|SOUNDS/yaapu0/en|yaapu|Yaapu telemetry ready|

Sound files can be customized but must be compatible with [OpenTX](https://opentx.gitbooks.io/manual-for-opentx-2-2/content/advanced/audio.html)

An easy way to automate creation of sound files is by using the [TTSAutomate](https://github.com/CaffeineAU/TTSAutomate) tool with a phrase file.

A reference [phrase file](https://github.com/yaapu/FrskyTelemetryScript/blob/master/TARANIS/SOURCES/english.psv) for the english language is provided as a template for other languages.
Taranis and Horus phrase files may differ so make sure to pick the right one.

**Note:In order to add new languages the script needs to be recompiled because the language must be added to the script configuration menu.**

## Compilation

To compile your own version you must first preprocess the SOURCES/yaapu0.lua scripts with the pproc.lua preprocessor.
Details on the preprocessor can be found [here](https://gist.github.com/incinirate/d52e03f453df94a65e1335d9c36d114e)

You need a working lua interpreter for this to work.
On a command line simply run "lua pproc.lua yaapu0.lua yaapu9.lua"
The yaapu9.lua script is now ready to be compiled in Companion.


## Hardware requirements

Please refer to the arducopter wiki for information on how to configure your flight controller for passthrough protocol
 - http://ardupilot.org/copter/docs/common-frsky-passthrough.html

For information on how to connect the FrSky equipment together, please refer to 
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#common-frsky-equipment
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#diy-cable-for-x-receivers
 
For information about building DIY frsky telemetry cables
 - https://discuss.ardupilot.org/t/some-soldering-required/27613 

## Support and Troubleshooting
 
 Official Blog Thread on ardupilot.org
 - https://discuss.ardupilot.org/t/an-open-source-frsky-telemetry-script-for-the-horus-x10-x12-and-taranis-x9d-x9e-and-qx7-radios/26443
 
Official thread on rcgroups.com
- https://www.rcgroups.com/forums/showthread.php?3020527-An-Ardupilot-frsky-telemetry-LUA-script-for-the-Horus-X10-X12-and-Taranis-X9D-E-QX7

Open an issue on github.com
- https://github.com/yaapu/FrskyTelemetryScript/issues
 
 ## Credits
 
 Thanks go to 
 - Marco Robustini (X9D tester) 
 - Chris Rey (QX7 tester)
 - Alain Chartier (french sound files)
 - [Johnex](https://github.com/Johnex) for TTSAutomate phrase file
 - Franck Perruchoud (X12 main beta tester)
 - Chen Zhengzhong (X10 tester)
 - Andras Schaffer (X12 tester)
 - Massild (X10 tester)
 - Zeek (X10 tester)
 - Vova Reznik (X10 tester)
 - [athertop](https://github.com/athertop) (X9D tester)
 - [zs6buj](https://github.com/zs6buj) (X9D tester)
 - [BFD Systems](https://www.bfdsystems.com/) (Horus version sponsor)
 - Craft&Theory for the passthrough protocol
