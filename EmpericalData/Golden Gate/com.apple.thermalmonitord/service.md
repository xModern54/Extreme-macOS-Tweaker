# com.apple.thermalmonitord

## Basics

- **Process names:** `thermalmonitord`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.thermalmonitord.plist`
- **Binary:** `/usr/libexec/thermalmonitord`
- **Category:** `hardware_thermal_sensor_fan_management`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System Hardware Thermal Monitoring & Safety Daemon (`thermalmonitord`).
Interfaces with Apple Silicon PMU / SMC and SoC thermal diode sensors (CPU P-cores, E-cores, GPU clusters, Neural Engine, battery, and chassis).
Responsible for:
1. **Dynamic Fan Speed Regulation**: Controls active cooling fan curves on fan-equipped Macs (MacBook Pro, Mac Studio, Mac mini).
2. **Thermal Budget & Throttling Management**: Coordinates with `powerd` and kernel scheduler to throttle SoC clock frequencies when thermal headroom is exceeded (critical on fanless MacBook Air).
3. **Emergency Thermal Shutdown & Alerts**: Triggers `ThermalTrap.app` ("Mac needs to cool down") and hardware protective shutdowns if junction temperatures exceed safe operating limits (>105°C).

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~5.8 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical hardware protection and thermal safety daemon. Disabling or modifying it risks hardware overheating, throttling failure, and battery thermal stress under sustained heavy compilation or gaming loads.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Hardware Safety Component)**.
