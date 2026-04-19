# Architecture: go-e Wallbox iOS App

## Pattern
**MVVM** (Model – View – ViewModel)

SwiftUI-native pattern. Views are purely declarative, all state and logic lives in ViewModels, HTTP communication is isolated in a Service layer.

---

## iOS App Structure

```
WallboxApp/
├── WallboxApp.swift              # App entry point
│
├── Services/
│   └── WallboxService.swift     # All HTTP calls to go-e API (GET status, SET dwo, SET amp)
│
├── Models/
│   └── WallboxStatus.swift      # Codable struct mapping go-e API response fields
│
├── ViewModels/
│   ├── WallboxViewModel.swift   # Main state: polling, status updates, error handling
│   └── ChargeLimitViewModel.swift # Charge limit calculation logic + API write
│
├── Views/
│   ├── ContentView.swift        # Root view / tab container
│   ├── StatusView.swift         # Live status display
│   ├── ChargeLimitView.swift    # SOC input + calculated limit + confirm action
│   └── SettingsView.swift       # IP, battery capacity, target SOC, charging energy divisor
│
└── Settings/
    └── AppSettings.swift        # @AppStorage wrapper for user preferences
```

---

## Layer Responsibilities

### WallboxService
- Owns URLSession
- Exposes async functions: `fetchStatus() async throws -> WallboxStatus`, `setChargeLimit(wh: Int) async throws`
- No UI logic, no state
- Base URL is injected from AppSettings (supports IP change + Tailscale)

### WallboxStatus (Model)
- Codable struct
- Maps only the fields the app actually uses (see CONTEXT.md for field reference)
- Computed properties for derived display values (e.g. `connectionStateLabel: String`)

### WallboxViewModel
- `@Observable` class (iOS 17+) or `ObservableObject` (iOS 16 fallback)
- Holds current `WallboxStatus?`
- Owns polling timer (15–20s interval)
- Exposes loading/error state to views

### ChargeLimitViewModel
- Holds input state: `currentSOC`, reads `batteryCapacity`, `targetSOC`, `chargingEnergyDivisor` from AppSettings
- Computed property: `calculatedLimitKWh` and `calculatedLimitPercent`
- `confirmAndSend()` calls WallboxService and handles result

### AppSettings
- `@AppStorage` for all user-configurable values
- Single source of truth for: wallbox IP, batteryCapacity, targetSOC, chargingEnergyDivisor
- Injected into Service and ViewModels via environment or init

---

## Data Flow

```
WallboxService (HTTP)
    │
    ▼
WallboxViewModel (polls every 15s)
    │
    ▼
StatusView (read-only display)

AppSettings ──► ChargeLimitViewModel ◄── user input (currentSOC)
                        │
                        ▼ (on confirm)
                WallboxService.setChargeLimit()
                        │
                        ▼
                WallboxViewModel.refresh()
```

---

## Backend (Post-MVP)

### Components

| Component | Technology | Responsibility |
|-----------|-----------|----------------|
| Poller | Python on Synology NAS | Polls wallbox every 15–20s, detects plug-in event |
| Notification relay | Supabase Edge Function (Deno) | Receives event, sends APNs push |
| Push delivery | Apple APNs | Delivers notification to iPhone |
| Session storage | Supabase Postgres | Logs charging sessions (kWh, timestamp) |

### Poller Logic (Python, simplified)
```python
prev_state = None
while True:
    status = get("/api/status")
    if prev_state == 1 and status["car"] in [2, 3]:
        trigger_push_notification()
    prev_state = status["car"]
    sleep(15)
```

### APNs Notes
- Requires Apple Developer Account (99€/yr)
- Supabase Edge Function handles APNs auth (JWT, p8 key)
- Notifications are queued by APNs if device is offline – delivered on next WiFi connect
- Notification payload should deep-link directly into ChargeLimitView

---

## Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| iOS App | Swift, SwiftUI, async/await |
| Minimum iOS | iOS 16 (iOS 17 preferred for @Observable) |
| Local API | go-e HTTP API v2 |
| Remote Access | Tailscale (no app code changes) |
| Poller | Python 3.x on Synology NAS |
| Notification Backend | Supabase (Edge Functions + Postgres) |
| Push | Apple APNs |

---

## Agent Instructions

- Do not put business logic in Views
- Do not put URLSession calls in ViewModels – always go through WallboxService
- All user preferences must go through AppSettings, never hardcoded
- Handle async errors explicitly – show error state in UI, never silently fail
- Keep each file focused on a single responsibility
- When adding a new API field, update WallboxStatus model and CONTEXT.md field table
