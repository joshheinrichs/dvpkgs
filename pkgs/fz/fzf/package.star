def package(c):
    return c.package(
        name = "fzf",
        uses = ["go"],
        go = {
            "ldflags": ["-X main.version=" + c.sources.version, "-X main.revision=nix1"],
            "packages": ["."],
            "testPackages": ["./src/algo/...", "./src/util/...", "./src/tui/..."],  # src/ reader test spawns $SHELL
        },
    )
