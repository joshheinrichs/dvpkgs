# host-side daemon for jig's build cache. Run outside the sandbox: jigd $XDG_RUNTIME_DIR/jigd/socket
def package(c):
    return c.package(
        name = "jigd",
        # unix sockets and syscall.Flock
        platforms = {"posix": True},
        version = "3",
        source = path("src"),
        uses = ["go"],
        go = {"cgo": False},
        tests = {"version": False},  # a daemon, no --version
        phases = {"remove": ["go.test"]},
    )
