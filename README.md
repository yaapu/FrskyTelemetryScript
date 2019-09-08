# Yaapu Frsky Telemetry Script

This is the home of the Yaapu Telemetry Script project, a [LUA](https://www.lua.org/about.html) telemetry script for the Frsky Horus and Taranis radios using the ArduPilot frsky passthru telemetry protocol.

**Note: the latest pre-release versions are downloadable from the [releases](https://github.com/yaapu/FrskyTelemetryScript/releases) section** 

The supported radios are:
- Taranis X9D(+) and QX7 on OpenTX 2.2.2/2.2.3
- X-Lite on OpenTX 2.2.2/2.2.3 (by using the QX7 version)
- Horus X10(S) and X12 on OpenTX 2.2.2/2.2.3
- Jumper T16 on JumperTX 2.2.3 (by using the Horus version)

Here you'll find
- a **Telemetry** script for the Taranis radios: X9D,QX7 and X-Lite ([changelog](https://github.com/yaapu/FrskyTelemetryScript/raw/master/taranis-changelog.txt))
- a **Widget** for the Frsky Horus radios: X10/S and X12 and for Jumper T16 ([changelog](https://github.com/yaapu/FrskyTelemetryScript/raw/master/horus-changelog.txt))


both support all of the telemetry DIY 0x5000 packets sent by ardupilot’s [frsky passthrough protocol library](https://github.com/ArduPilot/ardupilot/tree/master/libraries/AP_Frsky_Telem)

The script is also compatible with the excellent [MavlinkToPassthru](https://github.com/zs6buj/MavlinkToPassthru) converter firmware by Eric Stockenstrom

Requires [OpenTX 2.2.x](http://www.open-tx.org/) and a recent release of [ArduPilot](http://ardupilot.org/ardupilot/index.html).

![X10](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10.png)

![X9D](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9d.png)

![X7](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7.png)

## Index

 - [display layout](#display-layout)
 - [features](#features)
 - [advanced features](#advanced-features)
 - [extra screen with up to 6 frsky sensors](#extra-screen-with-external-frsky-sensors-support)
 - [mavlinkToPassthru firmware support](#mavlinktopassthru-firmware-support)
 - [sensor discovery](https://github.com/yaapu/FrskyTelemetryScript/wiki/Telemetry-sensors-discovery)
 - [supported flight modes](https://github.com/yaapu/FrskyTelemetryScript/wiki/Supported-Flight-Modes)
 - [voltage sources](#voltage-sources)
 - [supported battery configurations](https://github.com/yaapu/FrskyTelemetryScript/wiki/Supported-battery-configurations)
 - [airspeed vs groundspeed](#airspeed-vs-groundspeed)
 - [alerts](#alerts)
 - [telemetry reset](#telemetry-reset)
 - [configuration](#configuration)
 - [ardupilot configuration](#ardupilot-configuration)
 - [installation on Taranis](https://github.com/yaapu/FrskyTelemetryScript/wiki/Installation-on-Taranis-radios)
 - [installation on Horus](#installation-on-horus)
 - [sound files customization](https://github.com/yaapu/FrskyTelemetryScript/wiki/Sound-files-customization)
 - [compilation](#compilation)
 - [hardware requirements](#hardware-requirements)
 - [support and troubleshooting](#support-and-troubleshooting)
 - [credits](#credits)
 - [donation](#donation)
 
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
 - full telemetry reset on timer 3 reset, see [this](#telemetry-reset)
 - PX4 flight modes support when used with a Teensy running the mavlinkToPassthru firmware
 - vocal playback for a subset of mavlink status messages
 - up to 6 frsky sensors can be displayed on screen

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
 
## Extra screen with external frsky sensors support

Version 1.8.0 and above introduce an extra screen reachable by pressing [ENTER] from the status message history.
This screen adds support for up to 6 user selected frsky sensors to be displayed on screen.

![110sensors_display](https://github.com/yaapu/FrskyTelemetryScript/blob/master/HORUS/IMAGES/x10sensors.png)

![X9Dsensors_display](https://github.com/yaapu/FrskyTelemetryScript/blob/master/TARANIS/IMAGES/x9dsensors.png)

![X7sensors_display](https://github.com/yaapu/FrskyTelemetryScript/blob/master/TARANIS/IMAGES/x7sensors.png)

More info on setting them up is in the wiki.
- guide for [taranis radios](https://github.com/yaapu/FrskyTelemetryScript/wiki/Support-for-user-selected-Frsky-sensors-on-Taranis-radios)

## MavlinkToPassthru firmware support

![X9Dm2f](https://github.com/yaapu/FrskyTelemetryScript/blob/master/TARANIS/IMAGES/x9_m2f_displayinfo.png)

![X7m2f](https://github.com/yaapu/FrskyTelemetryScript/blob/master/TARANIS/IMAGES/x7_m2f_displayinfo.png)

Version 1.8.0 and above natively support Eric Stockenstrom's [MavlinkToPassthru](https://github.com/zs6buj/MavlinkToPassthru) converter firmware **Plus** version.

By using Eric's Plus version the script can display
- waypoint number, bearing and distance
- airspeed info
- throttle %

To enable this feature please select it from the script config menu by choosing "m2f" as left panel option.

## Voltage Sources

Battery voltage is tracked independentely for 3 battery sources: FLVSS, analog port A2 and flight controller. (The script can use the A2 analog voltage source from X4R and X6R receivers, a2 would be displayed next to cell voltage). In single battery mode a short press of [ENTER] on Taranis or [ENCODER] on Horus cycles between all the sources. Min value is also tracked for the 3 sources and can be shown with a [MENU] short press on Taranis or [SYS] on the Horus.

Note:If you use a second FLVSS voltage sensor the OpenTX variable has to be renamed to "Cel2"

When a second battery is detected the script also tracks "aggregate" battery values and shows a "B1+B2" label in the right panel. Cell value and battery voltage is the "minimum" between the two batteries, current is summed and capacity percent is averaged. A short press of [MENU] on Taranis or [ENCODER] on the Horus will show min/max values for this aggregate view.

In dual battery mode a short press of [ENTER] on the Taranis or [ENCODER] on the Horus switches from single aggregate view to individual dual battery view. Subsequent short presses of [ENTER]/[ENCODER] in this dual view will cycle between voltage sources. In dual view a short press of [MENU] on Taranis or [SYS] on Horus shows individual packs min/max values.

To get back to aggregate view and retain the selected voltage source short press [EXIT] on Taranis or [RTN] on Horus.

**Note:In widget mode voltage source cycling is not available, the voltage source has to be selected from the menu**

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

**Note: (applies to versions 1.7.1 and above) The battery monitoring engine has been modified to allow the voltage to drop below level for up to 4 seconds before triggering the alert. During this period the voltage background will flash to indicate that the alarm is about to fire, if during this "grace" period the voltage raises above level the alarm is reset.**

## Telemetry reset

It's possible to do a full script reset by resetting timer 3.

For the reset to occur 2 conditions must be met
- flight time is greater than 00:00
- vehicle is not armed

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

## ArduPilot Configuration

The two main wiring configurations are

#### ArduPilot sends native frsky passthrough telemetry data

The flight controller is configured to send native frsky passthrough telemetry data either with an inverting cable or without (pixracer). To enable this feature the SERIALn_PROTOCOL of the uart connected to the receiver has to be set to 10, check the ardupilot wiki for [details](http://ardupilot.org/copter/docs/common-frsky-telemetry.html#frsky-telemetry-configuration-in-mission-planner).

This configuration requires a "special" cable that acts as logic level converter and inverter, an example of such a cable is [here](https://discuss.ardupilot.org/t/some-soldering-required/27613)

For the pixracer an inverting cable is not needed but the wiring requires that the TX and RX pin of the frs port be connected together, check this [image](https://docs.px4.io/assets/flight_controller/pixracer/grau_b_pixracer_frskys.port_connection.jpg) for further details.

#### ArduPilot sends mavlink telemetry data

The flight controller is configured to send mavlink messages and an external board (Teensy, Blue Pill,etc) is used to convert mavlink to frsky using Eric Stockenstrom [MavlinkToPassthru](https://github.com/zs6buj/MavlinkToPassthru) firmware. 

This is the default configuration for long range systems (Dragonlink, TBS Crossfire, ULRS to name a few) unable to carry native frsky telemetry but compatible with mavlink.

## Installation on Taranis

Please check the [wiki](https://github.com/yaapu/FrskyTelemetryScript/wiki/Installation-on-Taranis-radios) for more info

## Installation on Horus

Copy the contents of the SD folder to your radio SD Card.
Make sure you have the /SOUNDS/yaapu0, SCRIPTS/YAAPU/CFG, SCRIPTS/YAAPU/LIB, SCRIPTS/YAAPU/IMAGES and WIDGETS/Yaapu folders.

**Power cycle the radio to clear widget caches!**

The script can be started in 2 ways:

- **Widget** (recommended) see this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12-as-a-Widget)

- **One time script** by using the yaapux.lua or yaapux.luac script, see this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12)

**Note:** For the script to control the lcd panel backlight a few extra steps are required, please follow this [guide](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-enable-lcd-panel-backlight-support-on-X10-and-X12)

The script is already compiled and only needs to be copied to the radio SD card. 

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
 - [Harris Aerial](https://www.harrisaerial.com/) (Horus version sponsor)
 - [Jumper](https://www.jumper.xyz) (Jumper T16 version sponsor)
 - Craft&Theory for the passthrough protocol

## Donation

This project is free and will always be.

If you like it you can support it by making a donation!

[![donate](https://user-images.githubusercontent.com/30294218/61724877-16fa7a80-ad6f-11e9-80de-9771e0b820ae.png)](https://paypal.me/yaapu)
