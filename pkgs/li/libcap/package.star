def package(c):
    return c.package(
        name = "libcap",
        uses = ["make"],
        make = {
            "flags": [
                "lib=lib",
                "sbin=bin",
                "CC=cc",
                "GOLANG=no",
                "PAM_CAP=no",  # no linux-pam yet
                "RAISE_SETFCAP=no",  # setcap on the result, not in a sandbox
            ] + c.on(c.platform.cross, ["BUILD_CC=cc-build"]),  # _makenames runs during the build
            # `make test` also executes libcap.so itself, via a PT_INTERP copied from a probe
            # binary: ours have none (crt-interp locates the loader at run time), so only the
            # library tests
            "testTarget": ["-C", "libcap", "cap_test"],
        },
        buildDependencies = [c.buildPkgs.bash],  # progs/mkcapshdoc.sh
        phases = {"after": {"make.test": [{"name": "test", "run": "x ./libcap/cap_test"}]}},
        platforms = {"os": ["linux"]},
    )
