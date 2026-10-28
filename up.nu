#!/usr/bin/env nu
# Bring the stack up. This is the deployment entry: two containers, in order.
#
# k10r is the memory core's HTTP face. prism is the venue — identity, booths, the turn.
# gravity has no daemon: prism spawns `gravity-turn` per turn and `gravity-provider` per
# inference round, so two containers is the whole stack.
#
# The store is not published. prism reaches it as `http://k10r:7760` on the stack's own
# network, and only the venue's port leaves the machine.
use lib.nu *

def main [
    --host-addr: string  # where the venue listens on this machine (default 127.0.0.1:8765)
] {
    let reg = (registry)
    let mem = (split-addr (k10r-addr))
    let venue = (split-addr ($host_addr | default (venue-addr)))
    let models = (embedding-model)
    if not ($models | path exists) {
        error make { msg: $"the embedding model is missing: ($models)" }
    }
    if not ((stack-env-file) | path exists) {
        error make { msg: $"the secrets file is missing: (stack-env-file)" }
    }

    let net = ((^podman network exists $NETWORK | complete).exit_code)
    if $net != 0 { ^podman network create $NETWORK | complete | ignore }

    # Replacing a container is a replace, not a reset: the store lives on a named volume,
    # so `-f` costs the process and nothing else. `--rm` is deliberately absent.
    ^podman rm -f $K10R_NAME | complete | ignore
    run-container [
        "run" "-d" "--name" $K10R_NAME "--network" $NETWORK
        "-p" $"($mem.host):($mem.port):7760"
        "--env-file" (stack-env-file)
        "-v" $"($models):/data/.local/share/krystallizer/models/bge-small-zh-v1.5:ro"
        "-v" $"($K10R_NAME)-data:/data"
        $"($reg)/krystallizer:latest"
    ]
    wait-door $"http://($mem.host):($mem.port)/graph/1"
    print $"k10r   (ansi green)up(ansi reset)  ($mem.host):($mem.port)  volume ($K10R_NAME)-data"

    # A venue that boots first just fails its first tool call, so the store's door
    # decides when this one starts.
    ^podman rm -f $PRISM_NAME | complete | ignore
    run-container [
        "run" "-d" "--name" $PRISM_NAME "--network" $NETWORK
        "-p" $"($venue.host):($venue.port):8765"
        "--env-file" (stack-env-file)
        "-e" "PRISM_ADDR=0.0.0.0:8765"
        "-e" "PRISM_DATA=/data"
        "-e" "PRISM_IDENTITY=open"
        "-e" $"GRAVITY_STORE_URL=http://($K10R_NAME):7760"
        "-e" $"GRAVITY_ENDPOINT=(endpoint)"
        "-e" $"GRAVITY_MODEL=(model)"
        "-e" "GRAVITY_KEY_ENV=OPENAI_API_KEY"
        "-e" "GRAVITY_MEMORY_SCOPE=1"
        "-e" "GRAVITY_TURN_BIN=/usr/local/bin/gravity-turn"
        "-e" "GRAVITY_PROVIDER_BIN=/usr/local/bin/gravity-provider"
        "-v" $"($PRISM_NAME)-data:/data"
        $"($reg)/prism:latest"
    ]
    wait-upgrade $"($venue.host):($venue.port)"
    print $"prism  (ansi green)up(ansi reset)  ($venue.host):($venue.port)  volume ($PRISM_NAME)-data"
    print "one turn: nu say.nu <text>"
}

# One place that decides what a failed container start looks like: the engine's own
# message, not a bare exit code.
def run-container [args: list<string>] {
    let out = (^podman ...$args | complete)
    if $out.exit_code != 0 {
        error make { msg: $"podman ($args.0) failed: ($out.stderr | str trim)" }
    }
}