#!/usr/bin/env nu
# One turn through the stack: `nu say.nu Open a task named foo`.
#
# The CLI is a venue client (gravity ADR-0002) — it knows neither a store nor a model,
# so this wrapper is where the two facts a client needs live: the venue's address and
# the name of the variable holding the venue password. The password itself is handed
# over as an environment variable, never as an argument.
use lib.nu *

def main [
    ...text: string  # what to say; `-` reads one line from stdin
] {
    if ($text | is-empty) {
        error make { msg: "usage: nu say.nu <text>… (or `-` for one line of stdin)" }
    }
    let said = if ($text | str join " ") == "-" {
        input
    } else {
        $text | str join " "
    }

    let cli = ((world) | path join "gravity/target/release/gravity")
    if not ($cli | path exists) {
        error make { msg: $"missing: ($cli) — run `cargo build --release -p gravity-cli` in gravity" }
    }

    let session = ($env.GRAVITY_SESSION? | default "1")
    let child = ((stack-env) | merge {
        GRAVITY_CONFIG: ($env.FILE_PWD | path join "gravity.json")
    })

    with-env $child {
        ^$cli --json --session $session --venue $"ws://(venue-addr)" $said
    }
}