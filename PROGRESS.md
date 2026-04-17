# Progress: go-e Wallbox iOS App

## Status: 🟡 In Setup

---

## MVP Scope
1. Status display (connection state, power, session energy, active limit)
2. Charge limit control (SOC input → kWh calculation → send to wallbox)
3. Settings (IP, battery capacity, target SOC, loss factor)

---

## Completed
_Nothing yet._

---

## In Progress
- [ ] Xcode project created
- [ ] CONTEXT.md, ARCHITECTURE.md, .cursorrules added to project root

---

## Up Next
1. `WallboxStatus` model (Codable struct, relevant API fields only)
2. `WallboxService` – `fetchStatus()` + `setChargeLimit(wh:)`
3. `AppSettings` – @AppStorage wrapper
4. `WallboxViewModel` – polling, status state, error handling
5. `StatusView` – live display
6. `ChargeLimitViewModel` – calculation logic
7. `ChargeLimitView` – SOC input + confirm
8. `SettingsView` – IP + vehicle params

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

---

## Decisions Log
_See DECISIONS.md for rationale behind architectural choices._
