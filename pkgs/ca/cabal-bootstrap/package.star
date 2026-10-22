# Upstream's cabal-install binary under our dynamic linker, build tool of the cabal build system.
def package(c):
    return c.package(
        name = "cabal-bootstrap",
        prebuilt = True,
        dependencies = [c.pkgs.gmp, c.pkgs.zlib],
        install = {"bin/cabal": "cabal"},
        bin = ["cabal"],
        tests = {"version": "--numeric-version"},
    )
