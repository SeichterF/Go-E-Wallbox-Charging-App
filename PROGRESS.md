# Progress: go-e Wallbox iOS App

## Status: 🟡 MVP in Progress (Features 1–2 done)

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
  - Display of connection state, charging power, session energy, and active `dwo` limit
  - Auto-refresh on Dashboard open
- [x] Default wallbox IP updated to `192.168.178.69` in `AppSettings`
- [x] Feature 2 implemented: charge limit from current SOC (Dashboard)
  - Formula: needed battery Wh to target SOC ÷ `chargingEnergyDivisor` → `dwo` (Wh), `GET /api/set?dwo=…`, then status refresh
  - Numeric **Current SOC** text field beside label (number pad, digits only, default 0%), **%** suffix, debounced auto-sync to wallbox (no separate apply button)
  - Renamed setting: `chargingEnergyDivisor` (default 0.85); `CONTEXT.md` and related docs aligned

---

## In Progress
- [ ] Feature 3: Settings persistence and validation hardening

---

## Up Next
1. Persist settings via `@AppStorage` (or equivalent) in `AppSettings`
2. Add polling loop in Dashboard ViewModel (15–20 seconds) if continuous updates are desired without manual refresh
3. Improve error surfacing UX (network/API errors in views)
4. Optional: toolbar “Done” above number pad to dismiss keyboard

---

## Backlog (Post-MVP)
- [ ] Push notifications on plug-in event
- [ ] Synology poller script (Python)
- [ ] Supabase Edge Function for APNs relay
- [ ] Charging session history / log
- [ ] Deep link from notification into charge-limit flow
- [ ] Tailscale remote access setup (no app code changes needed)

---

## Known Issues / Open Questions
- go-e API version needs to be confirmed (v2 assumed) – verify field names against live response
- iOS deployment target: 17 preferred, confirm device compatibility
- Local environment issue: Xcode simulator launch can fail with `NSPOSIXErrorDomain Code 3` (No such process); requires local simulator cleanup/restart workflow

---

## Decisions Log
_See DECISIONS.md for rationale behind architectural choices._
