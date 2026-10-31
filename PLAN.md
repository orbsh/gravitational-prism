# PLAN — the stack, integrated

Per-repo PLANs own their own phases (`~/world/<repo>/docs/PLAN.md`). This file owns what none of
them can: the ORDER across repos, the units that only land together, and what "the stack is
usable" means. It is the one place to read before asking "what is left".

## Where it stands (2026-10-29)

| Repo | State | Open work that this plan sequences |
|:--|:--|:--|
| krystallizer (k10r) | clean, main. mem-server HTTP face + `GET /export` (ADR-0013) landed; tests green at the last recorded gate | nothing owed to the stack. Deferred by ruling: dreaming/community detection, the SKILL topological walk, Actor nodes |
| prism | clean, main. Gateway, identity, turns, mount, `/code`, and the RENDERER LEG landed (bundle at the origin, layout PUSHED on connect, `view` forwarding, `turn.submit` → view frames) | the renderer leg's next cuts (per-turn slot, login form, sessions — U6/U7), the node handshake (U4), CLI (Phase 2). All but the handshake WAIT on fluxen's envelope removal |
| gravity | clean, main. The turn executes end to end through the induction guests; the skill walk landed 2026-10-26 | Phases 2.5 (transcript/history split + cold-call declaration), 2.6 (progress as data), 3 (the idle/no-turn trigger is all that is left), 4.5 (unified call model), 5 (weight write-back + ordering/retry) |
| effector | clean, main; one unpushed docs commit | Phase 3 remaining (domain allowlists, seccomp, `command_exec` mechanism, read-denial patterns, cold-call over the wire) + the node identity CLI (`keygen`/`register`) that prism's handshake needs |
| induction | clean, main. protocol + host + guest landed | nothing blocking |
| fluxen | main. `ui-core`/`boot` split landed 2026-10-29; the transport bridge now queues frames instead of keeping the latest (a pushed batch used to lose all but its last frame) | IN PROGRESS, by the user: REMOVING THE WIRE ENVELOPE. Everything on prism's renderer leg and gravity's `protocol=fluxen` is written against today's envelope and is re-derived after it lands |
| aura | clean, main. The realm, the induction carrier branch, the mounted effector gateway for local mode | Phases 4.20 leftovers, 6 (TTL/cold re-entry), 7/8 wiring (the implementations live in gravity/prism), slate-engine option (no pressure) |

## Units, in order

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

**U6 — the venue becomes usable by a stranger** (prism). Two cuts, one purpose:
(a) THE TEXT SLOT MUST BE PER TURN — `UI_TEXT` is the constant `say`, so a second turn's `set` and
patches rewrite the region the first turn's bubble also binds (`kind: source`): every frame is
right and the history smears. Fix is a per-device counter (`say.<n>`) plus a TWO-TURN e2e that
fails today. (b) LOGIN AS A COMPONENT IN THE LAYOUT — the verbs exist and answer; the layout has no
form, so a stranger can look but not ask (`turn` is user-gated). Typing after logging in is the
acceptance.

**U7 — sessions instead of devices, and history on connect** (prism + an application booth). The
leg partitions by device id today; sessions are the real key. "Connect and see the history" is the
`event:ui_init` path already ruled: the venue emits, a booth projects k10r's session into view
frames. Needs the session concept before it needs code.

**U8 — gravity's remaining phases**, then **U9 — k10r's deferred work**. Neither blocks the UI
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

- prism's faces are two env vars, both DEFAULTS in its image: `PRISM_ASSETS` (the bundle
  directory — the bundle IS the origin, so `/` is its `index.html`) and `PRISM_INIT`
  (`file:<path>` | `event:<name>`, where the event is emitted on every renderer connect). A
  deployment overrides either with `-e`; both absent is legal and the venue says so.
- **The bundle route is decided: build.nu stages it.** `venue/` in the build context carries
  the renderer bundle (built once, host-side, with trunk — an artifact, not a toolchain) and
  this repo's `layout/`, and prism's Dockerfile COPYs both (`/app/dist`, `/app/layout`). The
  bundle is therefore built by the trunk that fluxen's own image pins, and the venue never
  rebuilds a front end inside its image.
- `up.nu` reports the venue up only after `/` answers 200 — a venue without a bundle serves
  identity and turns fine and looks exactly like a broken page in a browser, so the failure
  belongs in the boot, not in the user's screen. `dev.nu` points the same two variables at the
  tree (`fluxen/examples/renderer/dist`, `layout/venue.yaml`), so host mode and container mode
  show the same page.

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

> **THE MARKER IS `ui:` (2026-10-31, prism ADR-0017's Update).** Every marked event above is
> `ui:<name>` — the rule, the direction and the stripping are unchanged, only the word is (in this
> stack `view` also names krystallizer's session projection and fluxen's forcegraph view). Read the
> 2026-10-29 entry's `view:<name>` as `ui:<name>`; `layout/venue.yaml` still speaks fluxen's
> vocabulary upstream and needs no change.

## THE LAYOUT FILE IS GONE 2026-10-31

`layout/venue.yaml` and its staging step (`build.nu`'s mkdir + rsync into `venue/layout`) are deleted. The file's own header said prism had no consumer for it (the `init` source is deleted: no verb, no `PRISM_INIT`, no `init.rs`), and the two-column shell it described is drawn by gravity's booth at `ui:connect` — so it was a second home for the screen, and prism's image shipped a directory nothing reads (`COPY venue/layout/` + `PRISM_INIT=file:/app/layout/venue.yaml` are gone from the Dockerfile as well).

What the build stages now is ONE artifact: the renderer bundle, built here with the trunk fluxen's own image pins (`trunk build --release --dist venue/dist`), copied into the image and served from the origin.
