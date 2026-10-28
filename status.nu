#!/usr/bin/env nu
# What is up, where it answers, and where its data lives — the three things to know
# before asking "why did that turn do nothing".
use lib.nu *

def main [] {
    let mem = (k10r-addr)
    let venue = (venue-addr)

    for name in [$K10R_NAME $PRISM_NAME] {
        let row = (^podman ps -a --filter $"name=^($name)$" --format "{{.Names}} {{.Status}}" | complete | get stdout | str trim)
        if ($row | is-empty) {
            print $"($name)  (ansi red)absent(ansi reset)  no container by that name"
        } else {
            print $row
        }
    }

    print ""
    if (door-open $"http://($mem)/graph/1") {
        let tasks = (^curl -fsS --max-time 3 $"http://($mem)/tasks/1" | complete | get stdout | from json)
        print $"store   (ansi green)answers(ansi reset)  ($mem)  ($tasks | length) tasks in scope 1"
    } else {
        print $"store   (ansi red)silent(ansi reset)   ($mem)"
    }

    let code = ((^curl -s -o /dev/null --max-time 3 $"http://($venue)/" | complete).exit_code)
    if $code != 7 {
        print $"venue   (ansi green)listening(ansi reset) ($venue)"
    } else {
        print $"venue   (ansi red)silent(ansi reset)   ($venue)"
    }

    print ""
    for name in [$K10R_NAME $PRISM_NAME] {
        let volume = (^podman volume inspect $"($name)-data" --format "{{.Mountpoint}}" | complete)
        if $volume.exit_code == 0 {
            print $"($name)-data  ($volume.stdout | str trim)"
        }
    }
}