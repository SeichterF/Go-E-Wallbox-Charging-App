# Progress: go-e Wallbox iOS App

## Status: 🟡 MVP in Progress (Feature 1 done)

---

## MVP Scope
1. Status display (connection state, power, session energy, active limit)
2. Charge limit control (SOC input → kWh calculation → send to wallbox)
3. Settings (IP, battery capacity, target SOC, charging energy divisor)

---

## Completed
- [x] Xcode project and MVVM folder structure created
- [x] Core project docs and guardrails added:
  - `CONTEXT.md`
  - `ARCHITECTURE.md`
  - `.cursorrules`
- [x] Base app flow and UI shell implemented:
  - `MainTabView` with Dashboard + Settings
  - Shared components (`PrimaryButton`, `StatusBadge`, `ChargingCardView`)
- [x] Initial app architecture implemented:
  - `AppSettings`, `WallboxStatus`, `ChargingSettings`
  - `WallboxServiceProtocol`, `WallboxService`, `WallboxAPIClient`
  - `DashboardViewModel`, `SettingsViewModel`
- [x] Feature 1 implemented: live wallbox status display in Dashboard
  - Real `GET /api/status` call in `WallboxAPIClient.fetchStatus()`
  - Mapping of `car` state to human-readable status labels
  - Display of connection state, charging power, and session energy
  - Auto-refresh on Dashboard open
- [x] Default wallbox IP updated to `192.168.178.69` in `AppSettings`
- [x] Branch synced with latest `main` (fast-forward merge)

---

## In Progress
- [ ] Feature 2: Charge limit control (SOC input -> calculation -> API set)
- [ ] Feature 3: Settings persistence and validation hardening

---

## Up Next
1. Implement `ChargeLimitViewModel` calculation flow (current SOC -> `dwo` in Wh)
2. Add wallbox SET call (`/api/set?dwo=...`) in API client/service
3. Refresh status automatically after successful SET call
4. Add/complete `ChargeLimitView` for SOC input and confirmation UX
5. Persist settings via `@AppStorage` in `AppSettings`
6. Add polling loop in Dashboard ViewModel (15-20 seconds)
7. Improve error surfacing UX (network/API errors in views)

---

## Backlog (Post-MVP)
- [ ] Push notifications on plug-in event
- [ ] Synology poller script (Python)
- [ ] Supabase Edge Function for APNs relay
- [ ] Charging session history / log
- [ ] Deep link from notification into ChargeLimitView
- [ ] Tailscale remote access setup (no app code changes needed)

---

## Known Issues / Open Questions
- go-e API version needs to be confirmed (v2 assumed) – verify field names against live response
- iOS deployment target: 17 preferred, confirm device compatibility
- Local environment issue: Xcode simulator launch can fail with `NSPOSIXErrorDomain Code 3` (No such process); requires local simulator cleanup/restart workflow

---

## Decisions Log
_See DECISIONS.md for rationale behind architectural choices._
