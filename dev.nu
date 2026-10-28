#!/usr/bin/env nu
# Run the stack from the working trees, in this terminal, without images.
#
# Same two processes as the deployment, built by `cargo build --release` instead of by a
# container. prism stays in the foreground so its output is visible; k10r runs as a job
# with its log in logs/k10r.log.
#
# Ctrl-C stops prism but not necessarily the store: nu has no signal hook to run cleanup
# from — an external child of a job outlived its parent in testing. That is why the pids
# are written down: `nu down.nu` stops both modes, and the next `dev.nu` clears a leftover
# before starting. Nothing is ever stopped by pattern; the pid file is the only handle.
use lib.nu *

def main [] {
    let root = (world)
    let bin = {
        k10r: ($root | path join "krystallizer/target/release/krystallizer")
        k10r_cfg: ($root | path join "krystallizer/config/krystallizer.kdl")
        prism: ($root | path join "prism/target/release/prism")
        turn: ($root | path join "gravity/target/release/gravity-turn")
        provider: ($root | path join "gravity/target/release/gravity-provider")
    }
    for path in ($bin | values) {
        if not ($path | path exists) {
            error make { msg: $"missing: ($path) — cargo build --release in that repo first" }
        }
    }

    let stale = (read-pid "k10r")
    if $stale > 0 { kill-pid $stale --name "k10r (leftover)" }

    let mem = (k10r-addr)
    let venue = (venue-addr)
    let logs = ($env.FILE_PWD | path join "logs")
    mkdir $logs
    mkdir ($env.HOME | path join ".local/share/prism")

    let store_log = ($logs | path join "k10r.log")
    let store_bin = $bin.k10r
    let cfg = $bin.k10r_cfg
    job spawn { ^$store_bin --config $cfg --addr $mem out> $store_log err> $store_log }
    sleep 300ms
    let pid = (job list | where type == "thread" | last | get pids.0? | default 0)
    if $pid > 0 { write-pid "k10r" $pid }
    wait-door $"http://($mem)/graph/1"
    print $"k10r   (ansi green)up(ansi reset)  ($mem)  log ($store_log)"

    let child = ((stack-env) | merge {
        PRISM_ADDR: $venue
        PRISM_DATA: ($env.HOME | path join ".local/share/prism")
        PRISM_IDENTITY: "open"
        GRAVITY_STORE_URL: $"http://($mem)"
        GRAVITY_ENDPOINT: (endpoint)
        GRAVITY_MODEL: (model)
        GRAVITY_KEY_ENV: "OPENAI_API_KEY"
        GRAVITY_MEMORY_SCOPE: "1"
        GRAVITY_TURN_BIN: $bin.turn
        GRAVITY_PROVIDER_BIN: $bin.provider
    })
    let prism_bin = $bin.prism
    print $"prism  (ansi green)foreground(ansi reset)  ($venue)  — Ctrl-C, or nu down.nu from another terminal"
    with-env $child { ^$prism_bin }
}