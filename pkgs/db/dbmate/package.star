# cgo against sqlite via mattn/go-sqlite3: the modules tree propagates our sqlite and go.nu adds
# the `libsqlite3` tag (builder/sys-libs.nu), nothing here names it
def package(c):
    return c.package(
        name = "dbmate",
        # cgo has no msvc support
        platforms = {"abi": ["gnu", "apple"]},
        uses = ["go"],
        go = {
            "packages": ["."],
            # the other drivers' tests want running database servers
            "testPackages": ["./pkg/dbutil/...", "./pkg/driver/sqlite/..."],
        },
        buildDependencies = [c.buildPkgs.sqlite],  # tests dump schemas through the sqlite3 cli
        tests = {"version": True},
    )
