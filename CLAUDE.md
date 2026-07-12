# CLAUDE.md – go-e Wallbox iOS App

This file is the primary reference for AI assistants working in this repository. Read it fully before making any changes.

---

## Project Overview

iOS app (SwiftUI, MVVM) that provides a native UI for controlling a **go-e Wallbox** EV charger via its local HTTP API v2. Replaces manual iOS Shortcuts with a proper native app. Written in Swift (Swift 5 language mode), targets iOS 26.

See [`CONTEXT.md`](CONTEXT.md) for API field reference and charge-limit formula. See [`ARCHITECTURE.md`](ARCHITECTURE.md) for architectural diagrams and layer responsibilities.

---

## Tech Stack

| Concern | Technology |
|---|---|
| Language | Swift (Swift 5 language mode) |
| UI | SwiftUI, async/await — no Combine, no callbacks |
| State | `@Observable` — not `ObservableObject` |
| Minimum iOS | iOS 26 |
| Third-party packages | None |
| Testing | Swift Testing framework (`@Test`, `#expect`) |
| Hardware API | go-e HTTP API v2 (local network) |

---

## Folder Structure

```
Go-E-Wallbox-Charging-App/
├── App/
│   └── Go_E_Wallbox_Charging_AppApp.swift   # @main entry point, wires dependencies
├── Configuration/
│   └── AppSettings.swift                    # @Observable config – single source of truth
├── Core/
│   ├── Constants/AppConstants.swift         # All UI strings (no hardcoded strings in views)
│   ├── Extensions/                          # (placeholder)
│   └── Utilities/                           # (placeholder)
├── Models/
│   ├── WallboxStatus.swift                  # API response model + ConnectionState enum
│   └── ChargingSettings.swift               # Charge-limit input struct
├── Resources/
│   └── Localization/
│       ├── en.lproj/Localizable.strings     # English UI strings
│       └── de.lproj/Localizable.strings     # German UI strings
├── Services/
│   ├── WallboxServiceProtocol.swift         # Protocol for testability
│   ├── WallboxService.swift                 # Business-logic wrapper (implements protocol)
│   └── WallboxAPIClient.swift               # Raw HTTP calls – the ONLY place URLSession lives
├── ViewModels/
│   ├── DashboardViewModel.swift             # Status polling, isLoading/errorMessage state
│   └── SettingsViewModel.swift              # Settings form state, delegates save to AppSettings
└── Views/
    ├── MainTabView.swift                    # Tab container (Dashboard + Settings)
    ├── Dashboard/
    │   └── DashboardView.swift
    └── Settings/
        └── SettingsView.swift
```

---

## Architecture Rules (non-negotiable)

- **Views** contain zero business logic – layout and user-interaction forwarding only.
- **ViewModels** contain zero URLSession / HTTP code – always call through `WallboxService`.
- **`WallboxAPIClient`** is the only place that knows about the go-e API and URLSession.
- **`WallboxService`** wraps `WallboxAPIClient` and implements `WallboxServiceProtocol`.
- **`AppSettings`** is the single source of truth for all user preferences and config.
- Never bypass the ViewModel to call a Service directly from a View.

Data-flow diagrams and per-layer details: see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Code Style

- `struct` for models, `final class` with `@Observable @MainActor` for ViewModels.
- No force unwraps (`!`) — use `guard let` or `if let`.
- No `try?` — explicit error handling always.
- No `DispatchQueue` — async/await throughout.
- No hardcoded IP addresses or numeric constants — all go through `AppSettings`.
- All UI strings live in `AppConstants.UI` — never hardcode strings in Views. See **Localization** section below for the full three-step process.
- Every ViewModel exposes `isLoading: Bool` and `errorMessage: String?`.
- Error states must be surfaced to the UI — never fail silently.

---

## Localization

The app supports English and German based on the device language. All UI strings flow through `AppConstants.UI`, which uses `String(localized:)` to look up values at runtime.

**When adding a new string, always update all three places:**

1. Add a `static let` in `Core/Constants/AppConstants.swift`:
   ```swift
   static let myNewLabel = String(localized: "my_new_label")
   ```
2. Add the key + English value to `Resources/Localization/en.lproj/Localizable.strings`:
   ```
   "my_new_label" = "My New Label";
   ```
3. Add the key + German value to `Resources/Localization/de.lproj/Localizable.strings`:
   ```
   "my_new_label" = "Meine neue Bezeichnung";
   ```

Missing a `.strings` entry causes the key itself to be shown at runtime — always add both languages.

---

## AppSettings

`AppSettings` is `@Observable`. Key properties:

| Property | Type | Default |
|---|---|---|
| `chargerIP` | `String` | `"192.168.178.69"` |
| `batterySizeKWh` | `Double` | `42.0` |
| `targetSOCPercent` | `Int` | `80` |
| `chargingEnergyFactor` | `Double` | `0.85` |
| `pollingIntervalSeconds` | `TimeInterval` | `15.0` |
| `minSOCPercent` (constant) | `Int` | `10` |
| `maxSOCPercent` (constant) | `Int` | `100` |
| `socStepPercent` (constant) | `Int` | `5` |

Settings persist via **iCloud Key-Value Store + UserDefaults**. Read fallback chain in `init`: iCloud → UserDefaults → hardcoded default. Every change is written to both stores in `didSet`. Both are injectable (`init(defaults:cloudStore:)`) — tests use an isolated `UserDefaults` suite and a `MockCloudStore` (conforming to `CloudKeyValueStore`). Requires the `com.apple.developer.ubiquity-kvstore-identifier` entitlement (`Go-E-Wallbox-Charging-App.entitlements`). `@AppStorage` is deliberately not used — it does not work inside `@Observable` classes without breaking observation.

---

## go-e API Conventions

- Base URL: `http://<chargerIP>/api/` — always from `AppSettings.apiBaseURLString`.
- Status endpoint: `GET /api/status`
- Set endpoint: `GET /api/set?<key>=<value>`
- Charge-limit field: `dwo` in **Wh** (multiply kWh × 1000 — never send kWh directly).
- Always refresh status after a successful SET call.
- Polling interval: 15–20 seconds (from `AppSettings.pollingIntervalSeconds`).

### Car connection states (`car` field)

Official go-e enum: `Unknown/Error=0, Idle=1, Charging=2, WaitCar=3, Complete=4, Error=5, Initializing=6`. **`Idle` (1) means no vehicle is connected** — the wallbox is ready and waiting.

| Value | go-e meaning | `ConnectionState` | Label |
|---|---|---|---|
| 0 | Unknown/Error | `.unknown` | "Unknown" |
| 1 | Idle (no vehicle) | `.disconnected` | "Disconnected" |
| 2 | Charging | `.charging` | "Charging" |
| 3 | WaitCar | `.waiting` | "Waiting" |
| 4 | Complete | `.complete` | "Charge Complete" |
| 5 | Error | `.unknown` | "Unknown" |
| 6 | Initializing | `.unknown` | "Unknown" |

`isConnected` is true only for values 2, 3, and 4 (vehicle physically plugged in).

---

## Testing

- Framework: **Swift Testing** (`import Testing`, `@Test`, `#expect`).
- Test files live in `Go-E-Wallbox-Charging-AppTests/` mirroring the source tree.
- Use `WallboxServiceProtocol` to inject mock services in ViewModel tests.
- Current tests: `WallboxServiceTests`, `WallboxAPIClientTests`, `DashboardViewModelTests`, `AppSettingsTests`.

---

## Current Implementation State

### Done
- MVVM project structure and all shared components.
- `AppSettings`, `WallboxStatus`, `ChargingSettings` models.
- `WallboxServiceProtocol`, `WallboxService`, `WallboxAPIClient`.
- `DashboardViewModel`, `SettingsViewModel`.
- **Feature 1**: Live wallbox status display — `GET /api/status`, `car` state mapping, power and session energy display, polling loop (every 15 s while the Dashboard is active).
- **Feature 2**: Charge-limit control — current SOC and target SOC set via draggable dots on the Dashboard progress bar (or tap-to-type) → `dwo` calculation → `GET /api/set?dwo=...`, debounced wallbox sync on input change, status refresh after each SET.
- **Feature 3 (persistence part)**: Settings persistence via iCloud KV Store + UserDefaults in `AppSettings` (fallback chain iCloud → UserDefaults → default, written to both in `didSet`).

### In Progress
- Feature 3 (remaining part): settings validation hardening.

### Backlog (post-MVP)
- Push notifications on plug-in event (Synology poller → Supabase → APNs).
- Charging session history via Supabase Postgres.
- Deep link from notification into the charge-limit flow on the Dashboard.

---

## Git Workflow

- **Never commit directly to `main`** — all work on dedicated branches.
- Branch naming:
  - Features: `feature/<short-kebab-description>` (e.g. `feature/charge-limit-control`)
  - Bug fixes: `bugfix/<short-kebab-description>`
- New branches start from an up-to-date `main`.
- Commit after each working feature, not after every file change.
- If the agent breaks something, revert to the last commit — do not try to fix forward.
- Pull requests: **non-draft** by default. Use draft only if explicitly asked.
- GitHub access via the **GitHub MCP server** (`mcp__github__*`) — not `gh` CLI.

---

## What You Must Never Do

- Do not put business logic in Views.
- Do not put URLSession calls in ViewModels.
- Do not install third-party packages without asking first.
- Do not refactor files outside the scope of the current task.
- Do not change the project structure without explicit instruction.
- Do not use `DispatchQueue`, deprecated APIs, or force unwraps.
- Do not hardcode IP addresses, strings, or magic numbers.
- Do not create new files without listing them first and getting confirmation.
- Do not add features beyond what is explicitly requested.

---

## When Unsure

- Ask before creating new files or adding dependencies.
- Check `CONTEXT.md` for API field reference before touching model/service code.
- Implement only the minimal version of anything not explicitly discussed, and flag it.
