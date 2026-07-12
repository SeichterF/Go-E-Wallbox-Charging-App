# Architecture: go-e Wallbox iOS App

This file describes how the app's layers work together.
For coding rules, folder structure, tech stack, and implementation state see [`CLAUDE.md`](CLAUDE.md);
for the go-e API field reference and the charge-limit formula see [`CONTEXT.md`](CONTEXT.md).

---

## Pattern

**MVVM** (Model – View – ViewModel), SwiftUI-native. Views are purely declarative,
all state and logic live in `@Observable` ViewModels, HTTP communication is isolated
in the service layer.

---

## Layer Responsibilities

### WallboxAPIClient (`Services/WallboxAPIClient.swift`)
- The **only** place URLSession lives.
- `fetchStatus()` — `GET /api/status`; parses `car`, `nrg[11]` (total power in W),
  `wh` (session energy in Wh), `dwo` (active charge limit in Wh) and maps the `car`
  value to `WallboxStatus.ConnectionState`.
- `setChargeEnergyLimitWh(_:)` — `GET /api/set?dwo=<Wh>`.
- Base URL comes from `AppSettings.apiBaseURLString`.

### WallboxService (`Services/WallboxService.swift`)
- Implements `WallboxServiceProtocol` (used to inject mock services in ViewModel tests).
- Wraps `WallboxAPIClient`: `updateChargingSettings(_:)` takes a `ChargingSettings`
  value, reads its `computedChargeLimitWh`, and sends it as `dwo`.

### Models
- `WallboxStatus` — parsed status (connection state, charging power in W, session
  energy in Wh, active `dwo` limit) plus a localized display label.
- `ChargingSettings` — charge-limit input struct;
  `computedChargeLimitWh = neededBatteryWh × chargingEnergyFactor` (see CONTEXT.md).

### DashboardViewModel
- `@Observable @MainActor`; exposes `isLoading` / `errorMessage`.
- **Polling loop**: `startPolling()` refreshes the status every
  `AppSettings.pollingIntervalSeconds` (15 s) while the Dashboard scene is active.
- Holds current-SOC and target-SOC editing state: draggable dots on the progress bar
  (snapped to `socStepPercent`) and tap-to-type keyboard entry, with range validation.
- **Debounced sync** (450 ms): any SOC/target change recomputes `dwo`, sends it to the
  wallbox, then refreshes the status.
- On the first status response, derives the current SOC back from the wallbox's active
  `dwo` limit.

### SettingsViewModel
- Thin bindings from `SettingsView` into `AppSettings` (charger IP, battery size,
  charging energy factor).

### AppSettings
- `@Observable`; persists every change via `didSet` to iCloud Key-Value Store + UserDefaults
  (read fallback chain: iCloud → UserDefaults → default; both stores injectable for tests —
  see the AppSettings section in `CLAUDE.md`).
- Single source of truth for `chargerIP`, `batterySizeKWh`, `targetSOCPercent`,
  `chargingEnergyFactor`, `pollingIntervalSeconds`, and the SOC bounds
  (`minSOCPercent`, `maxSOCPercent`, `socStepPercent`).
- Injected into the API client, the service, and both ViewModels at app start.

---

## Data Flow

```
DashboardView ──► DashboardViewModel ──► WallboxService ──► WallboxAPIClient ──► go-e HTTP API
                        ▲                                                              │
                        └───────────────────── WallboxStatus ◄────────────────────────┘

SettingsView ──► SettingsViewModel ──► AppSettings ──► (read by API client, service, ViewModels)
```

**Status polling:** `DashboardView` starts `startPolling()` via `.task` while the scene
is active → `fetchStatus()` every 15 s → UI updates.

**Charge-limit update:** user drags the current-SOC or target-SOC dot on the progress
bar (or types a value) → 450 ms debounce → `updateChargingSettings()` sends `dwo` →
status is refreshed to confirm the change.

---

## Remote Access

- Tailscale — same IP approach as the local network, no app code changes needed.
