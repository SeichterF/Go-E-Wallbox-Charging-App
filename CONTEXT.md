# Project Context: go-e Wallbox iOS App

## Purpose
This app provides a custom iOS interface for a go-e Wallbox home EV charger.
It replaces manual iOS Shortcuts with a native UI and adds push notification support for charging initiation.

## Hardware
- **Device**: go-e Charger [PLACEHOLDER: model, e.g. HOME+ 11kW]
- **API Version**: go-e API v2 (local HTTP)
- **Local IP**: [PLACEHOLDER: e.g. 192.168.1.100]
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
| `car` | int | Car connection state: 1=idle, 2=charging, 3=waiting, 4=complete |
| `amp` | int | Current charging amperage (A) |
| `dwo` | int | Charge energy limit in Wh (0 = disabled) |
| `nrg` | array | Energy array: nrg[11] = total power kW, nrg[12] = imported kWh this session |
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
| `currentSOC` | Current battery state of charge (%) | 20 |
| `targetSOC` | Maximum charge target (%) | 80 |
| `batteryCapacity` | Vehicle battery size (kWh) | 77 |
| `lossFactor` | Charging loss compensation factor | 1.1 |

### Formula
```swift
let deltaSOC = targetSOC - currentSOC          // e.g. 60%
let netEnergy = deltaSOC / 100 * batteryCapacity  // e.g. 46.2 kWh
let grossEnergy = netEnergy * lossFactor           // e.g. 50.82 kWh
let dwoValue = Int(grossEnergy * 1000)             // e.g. 50820 Wh → sent to API
```

### User-Configurable Parameters (stored in app Settings)
- `batteryCapacity` (kWh) – vehicle specific
- `targetSOC` (%) – default e.g. 80%
- `lossFactor` – default e.g. 1.1

### Runtime Input (entered per charging session)
- `currentSOC` (%) – entered by user when starting a session

---

## MVP Feature Scope

### Status Display
- Car connection state (human-readable: disconnected / plugged in / charging / complete)
- Current charging power (kW)
- Energy charged this session (kWh)
- Active charge limit (kWh and %)

### Charge Limit Control
- Input: current SOC
- Calculated output: energy limit in kWh (shown before confirming)
- Action: send `dwo` value to wallbox API

### Settings
- Wallbox IP address
- Battery capacity (kWh)
- Target SOC (%)
- Loss factor

---

## Post-MVP: Push Notification Flow

### Trigger
Wallbox `car` status changes from 1 (idle) → 2/3 (plugged in)

### Architecture
```
Synology NAS
  └── Python poller (every 15–20s)
      └── detects plug-in event
          └── HTTP POST → Supabase Edge Function
              └── sends APNs push notification → iPhone
                  └── user opens app, enters SOC, starts charging
```

### Notes
- iPhone may be offline (no signal) on arrival → APNs queues notification, delivered on WiFi connect
- APNs retains notifications up to 30 days
- Supabase also used for charging session history (post-MVP)

---

## Out of Scope (for now)
- Multi-vehicle support
- Scheduling / time-based charging
- Energy price integration
- Android
