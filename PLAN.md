# PLAN — the stack, integrated

Per-repo PLANs own their own phases (`~/world/<repo>/docs/PLAN.md`). This file owns what none of them can: the ORDER across repos, the units that only land together, and what "the stack is usable" means. It is the one place to read before asking "what is left".

## Where it stands (2026-11-09)

All eight repos are clean on `main` with nothing unpushed. The gates named below are the last RECORDED ones; the only suite re-measured today is prism's (71/71, twelve binaries).

| Repo | HEAD | State | Open work this plan sequences |
|:--|:--|:--|:--|
| krystallizer (k10r) | `cedc1c7` 2026-11-06 | mem-server's HTTP face, the session projection, the checkpoint door and `/export`; the reverse membership read is a lead face (okm ADR-0054) | nothing owed to the stack. Its own PLAN defers dreaming/community detection, the SKILL topological walk, Actor nodes, and document→graph population (a product decision before a model one) |
| prism | `2473d85` 2026-11-07 | one accept loop; identity (device, user, token, the `Activity` clock); the auth booth's seam and its one surface; the renderer leg; the `/effector/<alias>` handshake; `/code`; `/admin`; the bundle at the origin. Suite 71/71, measured today | user→devices fan-out (MODELING promises it, `ui.rs::forward` addresses one device), and Phase 2 — which is a ruling, not code: the venue ships no CLI, and gravity's `gravity` binary IS the venue client |
| gravity | `b24d5d8` 2026-11-07 | the turn runs end to end through the induction guests; the shell and its forms answer `ui:connect`; the CLI is a venue client, emitting `ui:turn.submit` with the conversation as a payload field | its own PLAN: 2.5 (transcript/history split + cold-call declaration), 2.6 (progress as data), 3 (the turn-loop half landed 2026-10-26; the idle/no-turn trigger remains), 4.5 (unified call model), 5 (skill pull-through + weight write-back) |
| effector | `2cc2b51` 2026-11-07 | executors and the remote-gateway frames; the `keygen`/`register` CLI; the deployable runner scripts; the mount served from prism | its own PLAN: 4 (operation dispatch — the `inline`/`link` payload forms), 5's residue (a declared scope field must name its enforcement point), 6 (data-path discipline) |
| induction | `6d5f423` 2026-11-07 | protocol + host + guest; a framed peer channel is a `Link` | nothing blocking |
| fluxen | `f0acae6` 2026-11-03 | the `ui-core`/`boot` split; the action list IS the downstream wire; the example host a page boots from | its own PLAN: `forget()` is still a retry stub; nothing blocking prism |
| aura | `34af958` 2026-11-07 | the realm, the carriers, the executor registry, the local effector gateway | its own PLAN's unchecked phases: 4.20 residue, 6 (TTL/cold re-entry), 7/8 wiring, the slate-engine option (no pressure) |

## What is left, in the order it should land

1. **prism's Phase 2 is closed as moot** (ruled 2026-11-09, prism's own PLAN carries the reasoning): the venue ships no client — its binary is a server — and gravity's `gravity` binary already is the venue client, kubectl-shaped on the one wire. What prism owes its clients is the wire itself, not a second client. Reopen this only if a consumer needs something the wire cannot express.
2. **prism's user→devices fan-out — or narrow the sentence.** MODELING says a user may be reached through the devices bound to it; `forward` reads one `device`, `PeerDeliver` takes a single `Option<&str>`, and `Registry::devices_of` has no caller outside its own test. Either it becomes a `forward` + `PeerDeliver` change with a two-device e2e, or the model's sentence is narrowed to what the code does. One ruling, one small commit.
3. **gravity's chain, in its own numbering** (2.5 → 2.6 → 3 → 4.5 → 5). Each unit names its seam: 4.5 is aura's call surface, 5 is k10r's rows and the weight write-back. None of it blocks the venue.
4. **k10r's and fluxen's deferred blocks are product decisions**, not the stack's critical path.

## What "usable" means

`nu up.nu` prints the two addresses; `http://127.0.0.1:8765/` serves the renderer bundle; the page connects to `/channel` on that same origin and gravity's booth answers `ui:connect` with the shell; the login control draws the two-field form into the `auth` region; a filled submit ends at "signed in as … / sign out"; typing in the stream submits a turn and the answer streams back into the rack; `nu down.nu` stops both.

Measured on the real stack 2026-11-06 (prism + fluxen's bundle + gravity's shell + headless chromium). Not re-measured since — what was measured today is the suite, 71/71.

## Deployment

`nu build.nu` builds the three images in the one order that works — gravity, krystallizer, prism (`IMAGE_ORDER` in `lib.nu`) — and the renderer bundle is a build INPUT, not repo content: `trunk` (the version fluxen's own image pins) runs inside the build context and the artifact lands at `venue/dist`, which prism's Dockerfile copies and serves as the origin (`PRISM_ASSETS=/app/dist`).

`nu up.nu` runs k10r and prism on one podman network and lets only the venue's port leave the machine (`-p 127.0.0.1:8765:8765`, `PRISM_ADDR=0.0.0.0:8765`, `PRISM_DATA=/data`, `PRISM_IDENTITY=open`). It declares the venue up only after `/` answers — a venue without a bundle serves identity and looks exactly like a broken page, so that failure belongs in the boot, not on the user's screen. `nu dev.nu` runs the same two processes from `target/release` with a pid file as the only handle (nothing is stopped by pattern); `status.nu` and `down.nu` follow it. `probe.nu` asks the endpoint one question directly, which is how "the model never asked" is separated from "the ask was lost on the way"; `say.nu` is one turn through gravity's CLI.

## Decisions the plan depends on (do not re-litigate)

- Identity and its storage are prism's: accounts (ns 50), devices (51), the node registry (52), tokens (53) and the idle clock (54) live in prism's own okm instance, while the credential verifier (55) belongs to the auth booth's own table. Aura receives the authenticated sender as payload metadata only.
- Authentication is the venue's and the PROOF is a booth's: one call (`verify` | `register`) answers with the user id, and prism then binds the device and rotates the token. The gate is declared ON THE RECEIVE and read from the route table, and it fails open — anonymous connections are legitimate and never evicted. A refusal says `ui:auth.required {event}` beside the `notice`, and that is what opens the login surface.
- The layout is the application's answer to `ui:connect`. There is no `init` verb, no `PRISM_INIT` and no layout file: the venue says two facts (`token`, `connect`), and whichever booth declared `ui:connect` draws.
- The browser leg speaks the renderer's wire — downstream an action list (`Vec<Content>`), upstream `content::Outflow` — and the adaptation is prism's: fluxen is pure UI and carries no per-host adapter. `{ev, args}` stays the peer/CLI/effector leg. One shape per leg, never two on one leg.
- A stream's format is the producer's call argument: gravity's turn takes `protocol` (`data` default | `fluxen` frames against slots the CALLER names), so the streaming region is per turn and never a constant.
- The marker is `ui:` in both directions, and a conversation is not the venue's key: the address is a device, the authentication a user, and the conversation is the application's own data.
- Trust posture is declared, never defaulted (`PRISM_IDENTITY=required|open`), and the effector handshake is host-first and posture-blind on the wire.

## Units — where each landed

| unit | outcome |
|:--|:--|
| U1 prism's UI leg | landed: the bundle is the origin, the layout is pushed on connect, `/channel` speaks the renderer's wire (`tests/ui_leg.rs`) |
| U2 fluxen's structure split | landed: `ui-core` + `boot`, the host lives under `examples/` |
| U3 the layout document | retired 2026-10-31: `layout/venue.yaml` deleted; gravity's booth draws the shell |
| U4 the node handshake | landed and verified: `effector_handshake` 6/6, `admin_nodes` 4/4 |
| U5 the turn's view format | landed: `protocol` on the call, gravity emitting per-turn frames |
| U6 usable by a stranger | closed: the per-turn region moved to gravity (a bubble is addressed by row), and the login surface is the auth booth's one reserved region |
| U7 sessions on the leg | closed as a direction error: a conversation is the application's data, not the venue's key |
| U8 gravity's remaining phases | open, in gravity's own PLAN |
| U9 k10r's deferred work | open, in k10r's own PLAN |

## Ledger — the gate that formed this plan (as written)

Spellings here read as the rulings that replaced them: `view:` reads `ui:`, `channel_id` reads `device`, and `session` in the effector's sense reads `executor`.

> **THE WIRE IS SETTLED 2026-10-29:** both directions are `view:<name>` (marker = a page cannot
> forge an internal event); a booth never answers into the page — it emits `view:<name>` with
> `{name, channel_id, sender, data}`, and prism strips the envelope and forwards, drawing an
> operation list and injecting anything else into the slot named by the event. `layout/venue.yaml`
> speaks the current fluxen vocabulary (`kind: uplink, slot: turn.submit`, tree address `slot`).
> What a venue build must still track: prism's uplink is still an `invoke` rather than an emit —
> when that moves, `turn.submit` becomes `view:turn.submit` and gravity's turn booth declares it.
>
> **UNBLOCKED 2026-10-29 (fluxen `460d867`): the wire envelope is GONE.** prism's `/channel` was
> ported in the same pass (downstream = the action list; the venue's speech = `inject` into
> `identity`/`notice`; no `ev != draw` verbs, no `init.result`), and U4's handshake is now VERIFIED
> by `tests/effector_handshake.rs`. What remains gated is nothing: U6 and U7 start from the shapes
> that landed. The paragraph below records what the gate was, for the reader who finds this plan
> mid-history. U1/U3/U5 landed against
> today's wire (`content::Message` down, `content::Outflow` up, prism wrapping answers as
> `Message{ev:"draw"}`; gravity's view-protocol item carries `frames` inside the turn envelope).
> U6 and U7 are written against those shapes, so they start AFTER the refactor and after
> re-deriving the contract from fluxen. U4 (node handshake) is untouched by it — that is the unit
> to pick up while waiting. Prism's own ledger names the exact files to revisit:
> `~/world/prism/docs/PLAN.md`, "Next, in order — and what is WAITING on fluxen".

## THE LAYOUT FILE IS GONE 2026-10-31

`layout/venue.yaml` and its staging step (`build.nu`'s mkdir + rsync into `venue/layout`) are deleted. The file's own header said prism had no consumer for it (the `init` source is deleted: no verb, no `PRISM_INIT`, no `init.rs`), and the two-column shell it described is drawn by gravity's booth at `ui:connect` — so it was a second home for the screen, and prism's image shipped a directory nothing reads (`COPY venue/layout/` + `PRISM_INIT=file:/app/layout/venue.yaml` are gone from the Dockerfile as well).

What the build stages now is ONE artifact: the renderer bundle, built here with the trunk fluxen's own image pins (`trunk build --release --dist venue/dist`), copied into the image and served from the origin.