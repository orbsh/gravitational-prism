# PLAN — the stack, integrated

Per-repo PLANs own their own phases (`~/world/<repo>/docs/PLAN.md`). This file owns what none of
them can: the ORDER across repos, the units that only land together, and what "the stack is
usable" means. It is the one place to read before asking "what is left".

## Where it stands (2026-10-29)

| Repo | State | Open work that this plan sequences |
|:--|:--|:--|
| krystallizer (k10r) | clean, main. mem-server HTTP face + `GET /export` (ADR-0013) landed; tests green at the last recorded gate | nothing owed to the stack. Deferred by ruling: dreaming/community detection, the SKILL topological walk, Actor nodes |
| prism | clean, main. Gateway, identity (device+account, argon2id in prism's OWN okm), turns, `/effector/<alias>` mount, `/code` export landed | `/assets` + `init` (Phase 1.10); the node handshake (Phase 1.8 step 2, unblocked 2026-10-29); CLI (Phase 2) |
| gravity | clean, main. The turn executes end to end through the induction guests; the skill walk landed 2026-10-26 | Phases 2.5 (transcript/history split + cold-call declaration), 2.6 (progress as data), 3 (the idle/no-turn trigger is all that is left), 4.5 (unified call model), 5 (weight write-back + ordering/retry) |
| effector | clean, main; one unpushed docs commit | Phase 3 remaining (domain allowlists, seccomp, `command_exec` mechanism, read-denial patterns, cold-call over the wire) + the node identity CLI (`keygen`/`register`) that prism's handshake needs |
| induction | clean, main. protocol + host + guest landed | nothing blocking |
| fluxen | main; the tree carries uncommitted drag/dock work (ADR 0019/0020, in progress). Renderer + release bundle (`dist-release/`) landed | the `ui-core`/`boot` split (ADR 0021; `~/world/fluxen/docs/PLAN.md` last section) — the structural precondition for a host that re-wraps the core |
| aura | clean, main. The realm, the induction carrier branch, the mounted effector gateway for local mode | Phases 4.20 leftovers, 6 (TTL/cold re-entry), 7/8 wiring (the implementations live in gravity/prism), slate-engine option (no pressure) |

## Units, in order

**U1 — prism's UI leg: `/assets` + `init` + the browser wire** (prism). **LANDED 2026-10-29 in part**:
the static face, the `/ui` leg speaking fluxen's wire, and `init` from `file:`/`event:` are in and
tested (`tests/ui_leg.rs`), with `webhook:` refused at boot. The layout is PUSHED on connect (no client-side
`init`), an `event:` source is an emit whose resulting view events prism forwards to the
renderers (booth `renderer`, event `view`), and the leg's identity verbs are in as well (verbs `login`/`signup`/`logout` on the leg with `user:<id>` in the
`connected`/`.result` sender; every other uplink calls the booth named by the event and its
answer arrives as view frames; revocation kicks renderer sockets too). Still owed on this
unit: the turn's `protocol=fluxen` stream landing in the layout's slot, and the bundle's
route into the image. Three things in one unit, because they meet
on one socket:

- The static face on the existing accept loop (`/assets/<rel>`, entry document at `/assets` and
  `/assets/`; canonical-root check; no listing; hashed names immutable).
- The `init` answer from a declared source — `PRISM_INIT=file:<path>` (YAML or JSON, read at boot) or
  `event:<type>/<handler>` (the booth's SINGLETON instance: a GLOBAL booth). Both deliver the layout
  as ordinary `create` frames and close with `init.result {frames: N}`. `webhook:` is refused by
  ruling. Absent = the standard error VALUE naming the config.
- The wire itself: the browser leg speaks the RENDERER's format — downstream `content::Message`,
  upstream `content::Outflow` — while `{ev, args}` stays the CLI/effector/peer shape. One shape per
  leg. Prism supplies the transport and the boot in a small front-end crate that mounts fluxen's
  `ui-core`; fluxen carries no per-host adapter (fluxen ADR 0021, `fluxen/docs/external-integration.md`).

Testable before any front end exists: the route, the answer shape, and the wire are all lockable with
a raw WS client.

**U2 — fluxen's structure split** (fluxen). **LANDED 2026-10-29** — `crates/ui_core` (the core) and
`examples/renderer` + `examples/transport-ws` (our host); the facade now re-exports the core only.
Prism depends on the core, never on those two. `ui_leptos` → **`ui-core`** (`ctx` / `render` /
`components` / `widgets`; no `#main`, no `transport-ws`) + **`boot`** (`#main` reader, WS wiring,
`mount()`, `window.fluxen.send`); the `fluxen` facade re-exports core always and boot behind a
feature. This is the structural precondition for U1: a host can only re-wrap the core once the core
stops owning a boot. The boot and `transport-ws` then move to `examples/` (our host is not a library
surface; `stage` stays a crate as a debugging tool — fluxen ADR 0021 「归属」). Two consumers, two
styles — prism mounts the core with its own transport, reflux keeps consuming the example boot's
bundle at the page root. fluxen ADR 0021 + `docs/external-integration.md`
(en + zh).

**U3 — the default layout document** (here). **CREATED 2026-10-29**: `layout/venue.yaml` is the
two-column shell (left `forcegraph`, right the stream rack + input bound to `turn.submit`), verified
rendering in headless chromium from a locally run prism. It is application CONTENT: the framework carries no layout, the
renderer ships no application shape, this repo is where a deployment says what its application
looks like. It also DECLARES the stream's landing slot (the chat column's slot name), which is what
`protocol=fluxen` writes into — the booth gets the name from the caller, never from a constant.

**U4 — the node handshake** (prism + effector, one landing). `Challenge{nonce}` + signed
`Register` on `/effector/<alias>`; effector `keygen`/`register` CLI with `identity_file`;
`credential` retired on both ends; prism's `required` posture gates on `NodeStore::verdict`
three-way. Plan: `~/world/prism/docs/handshake-plan.md`. Both ends must merge together — `required`
with half a handshake answers every node as keyless.

**U5 — the turn's view format** (gravity + prism). **LANDED 2026-10-29**: `protocol` on the turn
call — `data` (default, raw deltas for the CLI and every non-UI consumer) or `fluxen` (frames
against slots the CALLER names). gravity's guest builds them (question line, `set` of the text
region, answer bubble, then one `patch` per round); prism's renderer leg asks for `fluxen` with
its own declared slots (`chat`/`say`) and forwards the batches as `draw` frames. Verified end to
end against the SSE stub: typing on the renderer leg produces a streamed answer in the rack.

**U6 — gravity's remaining phases**, then **U7 — k10r's deferred work**. Neither blocks the UI
milestone; both are what makes the assistant useful once the venue has a face.

## Precedents to imitate, not to invent around

- **stage** (`~/world/fluxen/crates/stage`) is the server-side reference: a WS mirror that never
  inspects payloads, routes raw frames between peers, and serves the UI. Prism's browser leg is the
  same shape plus identity.
- **reflux** (`~/world/reflux`) is the host-side reference: a Python producer, a pinned renderer
  bundle, `window.fluxen.send` as the only uplink, and `reflux/wire.py` as the frame gate that
  checks shape where the frame is built. Its wire is already fluxen's `Message {ev, sender, content}`.
  Under fluxen's ADR 0021 it consumes the `boot` crate; the two adjustments it owes (a root-relative
  public URL, and following `boot`'s uplink handle) are recorded in
  `fluxen/docs/external-integration.md` §5.

## The UI milestone (what U1–U3 buy)

Open `http://<venue>:8765/assets/` → the two-column shell renders from the `init` layout and nothing
else; the connection is anonymous (device identity, no login wall — authentication is a business
decision, and this layout declares none); typing in the stream submits a turn on the same socket and
the answer streams back into the same column. Login is a component IN the layout, not a gate.

Done means measured on the running stack, not on the tests alone: `nu up.nu`, open the URL, one
turn round trip, then `nu down.nu`.

## Deployment facts that move with these units

- prism gains two env vars: `PRISM_ASSETS` (bundle directory, canonical path) and `PRISM_INIT`
  (`file:<path>` | `event:<type>/<handler>`). Both absent = the plane serves identity/turns with no
  UI, and says so at boot.
- The fluxen bundle has to reach the prism container: either baked into prism's image at build time
  or mounted as a volume. `build.nu` builds gravity → k10r → prism because prism copies gravity's
  guest binaries; the bundle is a fourth input this repo must supply.
- `up.nu`'s readiness check currently completes on the WS handshake. The UI milestone adds one
  check: `GET /assets/` answers 200 before the venue is reported up.

## Decisions the plan depends on (do not re-litigate)

- Identity and its storage are prism's: account registry, device anchors, argon2id, login — in
  prism's own okm instance. Aura receives the authenticated sender as payload metadata only.
- Authentication is a business-layer decision per event (`interface_schema.auth`); anonymous
  connections are legitimate and never evicted.
- The `init` source is a deployment fact with two forms (`file:`, `event:`); both deliver the layout
  as ordinary `create` frames (then `init.result {frames:N}`), so the client has no layout path of its
  own. The webhook form is refused (Fluxora's generation).
- The browser leg speaks the renderer's wire (`Message`/`Outflow`), and the adaptation is prism's:
  fluxen is pure UI and carries no per-host adapter. `{ev,args}` stays the CLI/effector/peer shape —
  one shape per leg, never two on one leg.
- A stream's format is the producer's call argument: gravity's turn takes `protocol` (`data` default |
  `fluxen` view frames against the layout-declared slot); application knowledge stays in the booth.
- Trust posture is declared, never defaulted (`PRISM_IDENTITY=required|open`), and the startup log
  states it.