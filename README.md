# Gravitational Prism

引力棱镜. The substance is gravity — what the agent does to the world is a turn, and the
turn is gravity's. The prism is the carrier it rides: identity, booths, the wire. Nothing
in here is a new mechanism between the two; this repository is where the agent lives and
how it is brought up.

Today it carries the deployment entry: two services, their images, and the scripts that
start, stop and observe them.

    k10r    the memory core's HTTP face (krystallizer/mem-server)   :7760
    prism   the venue — identity, booths, the turn                  :8765

gravity has no daemon. prism spawns `gravity-turn` once per turn and `gravity-provider`
once per inference round, so there is no third service to run.

## Running it

    nu up.nu        # both containers, in order
    nu status.nu    # what is up, whether the store answers, where its volume lives
    nu say.nu Open a task named something
    nu down.nu      # stop. --purge also deletes the volumes

`up.nu` waits for the store's door before starting the venue, and for a completed
WebSocket handshake before reporting the venue up. The handshake is the readiness signal
that matters: prism binds the port before its endpoint can serve, and a client connecting
in that window gets its connection reset — which surfaces as a turn that answers plausibly
and does nothing.

The store is not published. prism reaches it as `http://k10r:7760` on the stack's own
network `gravitational-prism`; only the venue's port leaves the machine.

Volumes hold everything worth keeping — `k10r-data` is the memory, `prism-data` is the
venue's identity. `down.nu` keeps them; `--purge` is the only way to lose them.

## Building the images

    nu build.nu                # gravity, krystallizer, prism — in that order

prism copies `gravity-turn` and `gravity-provider` out of the gravity image, so gravity
has to exist first.

The Dockerfiles live in their own repos (`krystallizer/`, `gravity/`, `prism/`), and every
`COPY` in them addresses a workspace-shaped tree. That shape is not a style choice: aura,
effector and induction are not published crates, and prism depends on them by path, so a
repo-shaped context cannot build prism at all. `build.nu` assembles the tree from the six
repos once, at `~/.cache/gravitational-prism/context`, and points every build at it.

## Running it without images

    nu dev.nu       # the same two processes, from target/release, in this terminal

For working on the code: no image rebuild between changes. prism stays in the foreground;
k10r runs as a job with its log in `logs/k10r.log`. Ctrl-C stops prism, and `down.nu` from
another terminal stops the store — a process started from a working tree has no supervisor,
so the pid file in `run/` is the only handle on it.

## Secrets

`~/.secrets/krystallizer-stack.env`, mode 0600, outside every repo. Container mode hands
it over as `--env-file`; host mode parses it and passes it to the child's environment.
Neither puts a value on a command line.

    OPENAI_API_KEY      the model key; prism names it in GRAVITY_KEY_ENV
    PRISM_PASSWORD      the venue password the CLI logs in with
    OPENAI_BASE_URL     not read by the stack — kept because it belongs to the same endpoint

The model endpoint and the model itself are deployment facts and live in `up.nu`/`dev.nu`
with environment overrides: `GRAVITY_ENDPOINT`, `GRAVITY_MODEL`.

## Diagnosing a turn that does nothing

    nu probe.nu                 # ask the endpoint directly, with tools
    nu probe.nu --question "..."

A turn with no reply and no effect has two possible halves: the model never asked for the
tool, or the ask was lost on the way. `probe.nu` bypasses the stack entirely and answers
the first half.

## Layout

    lib.nu      shared facts: repo list, addresses, the secrets file as a record, doors
    up.nu       containers up        down.nu    containers (and host processes) down
    status.nu   what is up           dev.nu     host processes, foreground
    say.nu      one turn             build.nu   the three images
    probe.nu    direct model probe
    gravity.json  the CLI's venue address, account, and the password variable's name