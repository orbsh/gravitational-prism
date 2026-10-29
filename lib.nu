# Facts shared by every script here: where the repos live, where the secrets live, and
# the two deployment addresses. Nothing in this file is a policy — each value is what
# this machine does, overridable by an environment variable of the same intent.

# The six repos this stack is built from. aura, effector and induction are not
# published crates: prism depends on them by path, so a build context has to carry all
# six in one tree (see build.nu).
# Every checkout a Dockerfile COPYs or a Cargo.toml points at by path. fluxen is here for the
# WIRE TYPE prism's renderer leg depends on (`content`), not because any of it is shipped from
# these images (the bundle that ships is staged under `venue/`).
export const REPOS = [aura effector induction krystallizer gravity fluxen prism]

export def world []: nothing -> string {
    $env.WORLD? | default ($env.HOME | path join "world")
}

# Which repos get built into images, and in which order: prism copies gravity's two
# binaries out of the gravity image, so gravity has to exist first.
export const IMAGE_ORDER = [gravity krystallizer prism]

export def registry []: nothing -> string {
    $env.REGISTRY? | default "ghcr.io/orbsh"
}

export def stack-env-file []: nothing -> string {
    $env.STACK_ENV? | default ($env.HOME | path join ".secrets" "krystallizer-stack.env")
}

# The secrets file as a record, for the scripts that hand it to a child process
# (`with-env`) instead of to a container (`--env-file`). Values never reach argv.
export def stack-env []: nothing -> record {
    let path = (stack-env-file)
    if not ($path | path exists) {
        error make { msg: $"the secrets file is missing: ($path)" }
    }
    open --raw $path
    | lines
    | where {|line|
        let text = ($line | str trim)
        ($text != "") and (not ($text | str starts-with "#")) and ($text | str contains "=")
    }
    | each {|line|
        let at = ($line | str index-of "=")
        { ($line | str substring 0..<$at | str trim): ($line | str substring ($at + 1).. | str trim) }
    }
    | into record
}

export def k10r-addr []: nothing -> string {
    $env.K10R_ADDR? | default "127.0.0.1:7760"
}

export def venue-addr []: nothing -> string {
    $env.PRISM_ADDR? | default "127.0.0.1:8765"
}

export def model []: nothing -> string {
    $env.GRAVITY_MODEL? | default "deepseek-v4.1-flash-1017"
}

export def endpoint []: nothing -> string {
    $env.GRAVITY_ENDPOINT? | default "https://dashscope.aliyuncs.com/compatible-mode/v1"
}

# Where the embedding model lives on the host. The image's KDL asks for it at
# `$HOME/.local/share/krystallizer/models/...` and the image sets HOME=/data, so the
# container path is fixed and only the host side is a choice.
export def embedding-model []: nothing -> string {
    $env.K10R_MODELS? | default ($env.HOME | path join ".local/share/krystallizer/models/bge-small-zh-v1.5")
}

# Container names are also the DNS names inside the stack's network.
export const K10R_NAME = "k10r"
export const PRISM_NAME = "prism"
export const NETWORK = "gravitational-prism"

# "host:port" split, for a publish spec: the container's own port is fixed by the
# image, the host side is what the caller asked for.
export def split-addr [addr: string]: nothing -> record {
    let parts = ($addr | split row ":")
    if ($parts | length) != 2 {
        error make { msg: $"expected host:port, got ($addr)" }
    }
    { host: $parts.0, port: $parts.1 }
}

export def door-open [url: string]: nothing -> bool {
    (^curl -fsS -o /dev/null --max-time 2 $url | complete | get exit_code) == 0
}

# A door that answers *something* is up. Prism speaks WebSocket only, so a plain GET
# comes back with an empty reply (curl 52) rather than a status line; exit code 7 —
# connection refused — is the one that means nobody is there yet.
export def wait-listening [addr: string, --attempts: int = 100, --delay: duration = 200ms] {
    mut up = false
    for _ in 1..$attempts {
        let code = ((^curl -s -o /dev/null --max-time 2 $"http://($addr)/" | complete).exit_code)
        if $code != 7 { $up = true; break }
        sleep $delay
    }
    if not $up { error make { msg: $"nothing listens on ($addr)" } }
}

# The venue's real readiness: prism binds the port before its WebSocket endpoint can
# serve, and a client that connects in that window is reset (os error 104) — a turn then
# runs against a half-built venue. A completed handshake is the only honest signal, so the
# check is that the upgrade answers 101, not that the port accepts.
export def wait-upgrade [addr: string, --attempts: int = 150, --delay: duration = 200ms] {
    mut ready = false
    for _ in 1..$attempts {
        let out = (^curl -s -o /dev/null -w "%{http_code}" --max-time 2
            -H "Connection: Upgrade"
            -H "Upgrade: websocket"
            -H "Sec-WebSocket-Version: 13"
            -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ=="
            $"http://($addr)/ws?protocol=json"
            | complete)
        if ($out.stdout | str trim) == "101" { $ready = true; break }
        sleep $delay
    }
    if not $ready {
        error make { msg: $"the venue at ($addr) never completed a handshake" }
    }
}

# Wait for a door instead of sleeping a guessed number of seconds.
export def wait-door [url: string, --attempts: int = 100, --delay: duration = 200ms] {
    mut open = false
    for _ in 1..$attempts {
        if (door-open $url) { $open = true; break }
        sleep $delay
    }
    if not $open { error make { msg: $"nothing answered at ($url)" } }
}
# Host-mode pids. Container mode does not need them (podman knows its own children), but a
# process started from a working tree has no supervisor: the file is the only handle a
# later `down.nu` — or the next `dev.nu` — has on it.
export def run-dir []: nothing -> string {
    let dir = ($env.FILE_PWD | path join "run")
    mkdir $dir
    $dir
}

export def write-pid [name: string, pid: int] {
    $"($pid)\n" | save -f ((run-dir) | path join $"($name).pid")
}

export def read-pid [name: string]: nothing -> int {
    let file = ((run-dir) | path join $"($name).pid")
    if not ($file | path exists) { return 0 }
    let pid = (open --raw $file | str trim | into int)
    # A pid file outlives its process; a reused pid would make us kill a stranger.
    if (^kill -0 $pid | complete | get exit_code) != 0 { 0 } else { $pid }
}

# TERM, then wait, then KILL. Never by pattern: a pattern that matches this script's own
# path kills the shell running it.
export def kill-pid [pid: int, --name: string = ""] {
    if $pid <= 0 { return }
    ^kill $pid | complete | ignore
    for _ in 1..50 {
        if (^kill -0 $pid | complete | get exit_code) != 0 { break }
        sleep 100ms
    }
    if (^kill -0 $pid | complete | get exit_code) == 0 {
        ^kill -9 $pid | complete | ignore
    }
    print $"($name)  (ansi yellow)stopped(ansi reset)  pid ($pid)"
}

# Who is listening on a port. A precise handle, unlike a pattern: `ss` reports the pid,
# so stopping a process that was started without a pid file does not mean matching a
# command line this script also contains.
export def pid-on-port [addr: string]: nothing -> int {
    let port = ($addr | split row ":" | last)
    let rows = (^ss -ltnp | complete | get stdout | lines | where {|line| ($line | str contains $":($port) ") })
    if ($rows | is-empty) { return 0 }
    let found = ($rows | get 0 | parse -r 'pid=(\d+)' | get 0.capture0? | default "0")
    $found | into int
}