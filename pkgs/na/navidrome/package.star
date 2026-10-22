# mixed: go server embedding a vite-built UI from ui/; cgo against taglib, which the modules tree
# propagates (builder/sys-libs.nu)
def package(c):
    return c.package(
        name = "navidrome",
        uses = ["go", "npm"],
        npm = {
            "root": "ui",
            "deps": c.fetch.npmDeps(source = c.sources.fetch("default"), root = "ui"),
        },
        go = {
            "tags": ["netgo", "sqlite_fts5"],
            "ldflags": [
                "-X github.com/navidrome/navidrome/consts.gitTag=v" + c.sources.version,
                "-X github.com/navidrome/navidrome/consts.gitSha=nix",
            ],
            "packages": ["."],
        },
        phases = ["npm.build", "go.build", "go.install"],  # go tests want a music library fixture set
    )
