#!/usr/bin/env nu
# Take the stack down.
#
# The volumes survive on purpose: they hold the store and the venue's identity. Killing
# the processes is a restart; dropping the volumes is losing the memory, so that needs
# `--purge` said out loud.
use lib.nu *

def main [
    --purge  # also delete the volumes: the store and the venue's identity go with them
] {
    for name in [$PRISM_NAME $K10R_NAME] {
        let out = (^podman rm -f $name | complete)
        if $out.exit_code == 0 {
            print $"($name)  (ansi yellow)stopped(ansi reset)"
        } else {
            print $"($name)  was not running"
        }
    }

    if $purge {
        for name in [$PRISM_NAME $K10R_NAME] {
            ^podman volume rm $"($name)-data" | complete | ignore
            print $"($name)-data  (ansi red)deleted(ansi reset)"
        }
    }

    # Host mode (dev.nu) leaves the store behind when Ctrl-C beats the cleanup: the pid
    # file covers it, and the venue is found by the port it holds.
    for pair in [[name addr]; [k10r (k10r-addr)] [prism (venue-addr)]] {
        let from_file = (read-pid $pair.name)
        let from_port = (pid-on-port $pair.addr)
        let pid = (if $from_file > 0 { $from_file } else { $from_port })
        if $pid > 0 { kill-pid $pid --name $"($pair.name) [host mode]" }
        rm -f ((run-dir) | path join $"($pair.name).pid") | ignore
    }

    let containers = (^podman ps --format "{{.Names}}" | complete | get stdout | lines)
    if ($containers | is-empty) {
        ^podman network rm $NETWORK | complete | ignore
    }
}