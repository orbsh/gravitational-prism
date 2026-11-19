# PLAN — the stack, integrated

Per-repo PLANs own their own phases (`~/world/<repo>/docs/PLAN.md`) and each ADR owns its own decision. This file owns what none of them can: the order across repos, the units that land together, and what "the stack is usable" means. It is the one place to read before asking "what is left".

## Where it stands — 2026-11-18

| repo | HEAD | owed to the stack |
|:--|:--|:--|
| krystallizer (k10r) | `d2ca692` | nothing. Its own PLAN defers the graph-side blocks — dreaming, community detection, the SKILL walk, document→graph — which are product decisions |
| prism | `698957f` | nothing open: fan-out landed, Phase 2 ruled moot |
| gravity | `50b00b6` | its own PLAN's chain (2.5 → 2.6 → 3 → 4.5 → 5). None of it blocks the venue |
| effector | `f02f859` | its own PLAN: 5, 6, and the container backend of 7 |
| induction | `457b5e0` | nothing blocking |
| fluxen | `4a2f3d1` | `forget()` is still a retry stub; nothing blocking prism |
| aura | `dc9c85f` | its own PLAN's unchecked phases (4.20 residue, 6, 7/8 wiring); no pressure on the stack |

## Order

- [x] 1 — prism's Phase 2 closed as moot — 2026-11-09 — prism `docs/PLAN.md`: the venue ships no client, gravity's binary is the client
- [x] 2 — prism's user→devices fan-out — 2026-11-09 — prism ADR-0018 §3; gates `ui_leg` 13/13, `peer_leg` 4/4
- [x] 3 — the effector's environment model and its token handshake — 2026-11-16 — effector ADR-0003
- [ ] 4 — gravity's chain, in its own numbering — gravity `docs/PLAN.md`
- [ ] 5 — k10r's and fluxen's deferred blocks — product decisions, not the critical path

## What "usable" means

`nu up.nu` prints the two addresses; `http://127.0.0.1:8765/` serves the renderer bundle; the page connects to `/channel` on that same origin and gravity's booth answers `ui:connect` with the shell; the login control draws the two-field form into the `auth` region; a filled submit ends at "signed in as … / sign out"; typing in the stream submits a turn and the answer streams back into the rack; `nu down.nu` stops both.

Measured on the real stack 2026-11-06. Not re-measured since.

## Decisions the plan depends on

- identity, its storage and the token are prism's: accounts, devices, the node registry, tokens and the idle clock in prism's own okm instance — prism ADR-0017
- authentication is the venue's and the proof is a booth's; the gate is declared on the receive, read from the route table, and fails open — prism ADR-0017, MODELING
- the layout is the application's answer to `ui:connect`; there is no `init` verb and no layout file — prism ADR-0019
- the browser leg speaks the renderer's wire (downstream an action list, upstream `Outflow`), `{ev, args}` stays the peer/CLI/effector leg — fluxen ADR-0021
- a stream's format is the producer's call argument (`protocol`)
- a conversation is not the venue's key: the address is a device, the authentication a user — prism ADR-0018
- trust posture is declared, never defaulted (`PRISM_IDENTITY=required|open`)
- the node's transport, environment and resource model — effector ADR-0003

## Units — where each landed

| unit | outcome |
|:--|:--|
| U1 prism's UI leg | landed: the bundle is the origin, the layout is pushed on connect, `/channel` speaks the renderer's wire (`tests/ui_leg.rs`) |
| U2 fluxen's structure split | landed: `ui-core` + `boot`, the host lives under `examples/` |
| U3 the layout document | retired 2026-10-31 — prism ADR-0019 |
| U4 the node handshake | landed, then replaced by a dial token — effector ADR-0003 §11 |
| U5 the turn's view format | landed: `protocol` on the call, gravity emitting per-turn frames |
| U6 usable by a stranger | closed: a bubble is addressed by row (gravity), the login surface is the auth booth's one reserved region |
| U7 sessions on the leg | closed as a direction error — prism ADR-0018 |
| U8 gravity's remaining phases | open, in gravity's own PLAN |
| U9 k10r's deferred work | open, in k10r's own PLAN |

## Running it

`README.md` — `up.nu` / `status.nu` / `say.nu` / `down.nu`, `dev.nu`, `build.nu`, the secrets file, and `probe.nu` for diagnosing a turn that does nothing.