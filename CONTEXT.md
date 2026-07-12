# Project Context: go-e Wallbox iOS App

## Purpose
This app provides a custom iOS interface for a go-e Wallbox home EV charger.
It replaces manual iOS Shortcuts with a native UI.

## Hardware
- **Device**: go-e Charger
- **API Version**: go-e API v2 (local HTTP)
- **Local IP**: `192.168.178.69` (default in `AppSettings`, changeable in the app's Settings tab)
- **Remote Access**: Tailscale (same IP approach, no code changes needed)

---

## go-e API Reference

### Base URL
```
http://<wallbox-ip>/api/
```

### Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/status` | GET | Full device status |
| `/api/set?<key>=<value>` | GET | Set a single parameter |

### Relevant Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `car` | int | Car state: 0=unknown/error, 1=idle (no vehicle connected), 2=charging, 3=waitcar, 4=complete, 5=error, 6=initializing |
| `amp` | int | Current charging amperage (A) |
| `dwo` | int | Charge energy limit in Wh (0 = disabled) |
| `nrg` | array | Energy array: nrg[11] = total power in **W** (the app divides by 1000 for kW display); other indices unused |
| `wh` | float | Energy charged in this session (Wh) |
| `alw` | bool | Allow charging (true/false) |
| `eto` | int | Total energy charged ever (Wh) |
| `err` | int | Error state (0 = no error) |

### Setting the Charge Limit
```
GET /api/set?dwo=<value_in_Wh>
```
Example: to charge 20 kWh → `dwo=20000`

To disable limit: `dwo=0`

---

## Charge Limit Calculation Logic

This replicates the existing iOS Shortcut logic:

### Inputs
| Parameter | Description | Example |
|-----------|-------------|---------|
| `currentSOC` | Current battery state of charge (%) | 37 |
| `targetSOC` | Maximum charge target (%) | 80 |
| `batteryCapacity` | Vehicle battery size (kWh) | 42 |
| `chargingEnergyFactor` | Multiply needed battery Wh by this to get wallbox `dwo` Wh | 0.85 |

### Formula (implemented in `ChargingSettings.computedChargeLimitWh`)
```swift
let deltaSOC = targetSOC - currentSOC                     // e.g. 43%
let neededBatteryKWh = deltaSOC / 100 * batteryCapacity   // kWh still to fill in the pack
let neededBatteryWh = neededBatteryKWh * 1000
let wallboxWh = neededBatteryWh * chargingEnergyFactor    // e.g. × 0.85
let dwoValue = Int(wallboxWh.rounded())                   // Wh → sent to API
```

Example: current 37%, target 80%, battery 42 kWh, factor 0.85 → `dwo` = 15351 Wh.

If `deltaSOC ≤ 0` (target already reached) or `chargingEnergyFactor ≤ 0`, the result is `0` (no limit sent).

### User-Configurable Parameters
- `batteryCapacity` (kWh) – vehicle specific, set in the Settings tab (default 42)
- `chargingEnergyFactor` – set in the Settings tab (default 0.85, must be > 0)
- `targetSOC` (%) – default 80, adjusted directly on the Dashboard progress bar (drag the target dot or tap to type)

### Runtime Input (entered per charging session)
- `currentSOC` (%) – set by the user on the Dashboard progress bar (drag the current-SOC dot or tap to type); on first status fetch it is derived back from the wallbox's active `dwo` limit

---

## MVP Feature Scope

### Status Display
- Car connection state (human-readable: disconnected / plugged in / charging / complete)
- Current charging power (kW)
- Energy charged this session (kWh)
- Active charge limit (kWh and %)

### Charge Limit Control
- Input: current SOC and target SOC via draggable dots on the Dashboard progress bar (snapped to 5% steps) or tap-to-type keyboard entry
- Calculated output: energy limit in kWh (live preview)
- Action: send `dwo` to wallbox API after a short debounce when the value changes

### Settings
- Wallbox IP address
- Battery capacity (kWh)
- Charging energy factor

---

## Out of Scope (for now)
- Multi-vehicle support
- Scheduling / time-based charging
- Energy price integration
- Android
