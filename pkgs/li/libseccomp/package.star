def package(c):
    b = c.buildPkgs
    return c.package(
        name = "libseccomp",
        uses = ["autotools"],
        patches = [path("upstream-tests-tail-pid.patch")],
        platforms = {"os": ["linux"]},
        buildDependencies = [
            b.gperf,
            b.bash,  # tests/regression
            b.which,
            b["util-linux"],
        ],
    )
