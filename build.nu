#!/usr/bin/env nu
# Build the stack's images, in the one order that works.
#
#   nu build.nu                # gravity, krystallizer, prism
#   nu build.nu krystallizer   # just one (whatever it copies from must already exist)
#
# The Dockerfiles live in their own repos, and every COPY in them addresses a
# WORKSPACE-shaped tree (`aura/`, `gravity/`, `prism/` …) because these repos depend on
# each other by path: aura, effector and induction are not published crates, so a
# repo-shaped context cannot build prism at all. This script assembles that tree once
# and points every build at it.
#
# A copy, not `--file prism/Dockerfile ~/world`: ~/world is 20 GB. The six repos are a
# few MB of sources without target/ and .git/, and a copy means every engine sees the
# same context (podman wants --ignorefile, docker reads .dockerignore, and neither reads
# a per-Dockerfile ignore the same way).
#
# Every build runs with CARGO_HOME=/root/.cargo whatever the base image's own convention
# is (`rust:*` ships /usr/local/cargo), so one mount pair serves both builders — the
# rust one and the python-plus-rustup one.
#
# The host's cargo cache is mounted into every build. Without it a build is a fresh
# download of ~500 crates and three git repositories, and GitHub's git endpoint times
# out on this network often enough that the build fails for no reason of its own. The
# target directories are mounted too, so touching one repo does not recompile five.
use lib.nu *

def main [
    ...wanted: string  # which images (default: gravity, krystallizer, prism)
] {
    let names = if ($wanted | is-empty) { $IMAGE_ORDER } else { $wanted }
    let root = (($env.XDG_CACHE_HOME? | default ($env.HOME | path join ".cache")) | path join "gravitational-prism")
    let context = ($root | path join "context")
    let reg = (registry)
    let engine = ($env.ENGINE? | default "podman")
    let cargo_home = ($env.CARGO_HOME? | default ($env.HOME | path join ".cargo"))
    let src = (world)

    mkdir $context
    mkdir ($root | path join "target")

    for repo in $REPOS {
        let from = ($src | path join $repo)
        let to = ($context | path join $repo)
        # A private checkout is not the deployment's business, and target/ is artifacts
        # the build regenerates anyway.
        let copied = (^rsync -a --delete --exclude "target/" --exclude ".git/" $"($from)/" $"($to)/" | complete)
        if $copied.exit_code != 0 {
            error make { msg: $"rsync of ($repo) failed: ($copied.stderr | str trim)" }
        }
    }

    # The renderer bundle and the venue's layout are DEPLOYMENT INPUTS, not repo contents:
    # the image carries an artifact, not a toolchain and not a second checkout. The bundle is
    # built here, once, with the same trunk fluxen's own image pins — a bundle from a
    # different trunk is a different artifact, and the venue would be serving a front end
    # nobody verified.
    let venue = ($context | path join "venue")
    mkdir ($venue | path join "layout")
    let layout_src = ($env.FILE_PWD | path join "layout")
    let copied_layout = (^rsync -a --delete $"($layout_src)/" $"($venue)/layout/" | complete)
    if $copied_layout.exit_code != 0 {
        error make { msg: $"staging the venue layout failed: ($copied_layout.stderr | str trim)" }
    }
    if ((which trunk | is-empty)) {
        error make { msg: "trunk is not on PATH — the renderer bundle cannot be built (fluxen's Dockerfile pins one; install it host-side for a release build)" }
    }
    let renderer = ($src | path join "fluxen" "examples" "renderer")
    let dist = ($venue | path join "dist")
    let bundle = (do { cd $renderer; ^trunk build --release --dist $dist } | complete)
    if $bundle.exit_code != 0 {
        print ($bundle.stderr | lines | last 15 | str join (char nl))
        error make { msg: "the renderer bundle did not build" }
    }
    print $"venue (ansi green)staged(ansi reset)  bundle + layout → ($venue)"

    for name in $names {
        let target = ($root | path join "target" $name)
        mkdir $target
        print $"(ansi green)=== ($name)(ansi reset)"
        let out = (^$engine build
            --network=host
            --env CARGO_NET_RETRY=10
            --env CARGO_HTTP_TIMEOUT=180
            --env CARGO_HOME=/root/.cargo
            --build-arg $"http_proxy=($env.http_proxy? | default '')"
            --build-arg $"https_proxy=($env.https_proxy? | default '')"
            --build-arg $"RUSTUP_DIST_SERVER=($env.RUSTUP_DIST_SERVER? | default '')"
            --volume $"($cargo_home)/registry:/root/.cargo/registry:z"
            --volume $"($cargo_home)/git:/root/.cargo/git:z"
            --volume $"($target):/src/($name)/target:z"
            --build-arg $"GUESTS_IMAGE=($reg)/gravity:latest"
            -t $"($reg)/($name):latest"
            -f $"($context)/($name)/Dockerfile"
            $context
            | complete)
        if $out.exit_code != 0 {
            print ($out.stdout | lines | last 20 | str join (char nl))
            error make { msg: ($out.stderr | lines | last 20 | str join (char nl)) }
        }
    }

    print ""
    let ours = $IMAGE_ORDER | each {|name| $"($reg)/($name):latest" }
    let sizes = (^$engine images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" | complete | get stdout | lines
        | where {|line| ($ours | any {|image| $line | str starts-with $image }) })
    print ($sizes | str join (char nl))
}