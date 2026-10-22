# Upstream's GHC bindist under our dynamic linker: the compiler that builds Haskell packages until
# ghc is built from source (it needs a GHC). Build tool only, taken from buildPkgs by cabal.nu.
# riscv64: upstream has no bindist, Debian's .deb (LLVM backend, links libnuma)
def package(c):
    pkgs = c.pkgs
    deb = c.platform.cpu == "riscv64"
    spec = dict(
        name = "ghc-bootstrap",
        prebuilt = True,
        platforms = {"cross": False},
        dependencies = [pkgs.gmp, pkgs.ncurses, pkgs.libffi] + c.on(deb, [pkgs.numactl, pkgs.llvm]),
        buildDependencies = c.on(not deb, [c.buildPkgs.cpython]),
        phases = [{
            "name": "install",
            "run": c.lib.text("""
                use ghc-bindist.nu
                ghc-bindist install-deb
            """) if deb else c.lib.text("""
                # configure runs bin/ghc-toolchain-bin and `make install` the installed ghc-pkg: the
                # bindist must already run here, finish's implant over $out then only adjusts paths
                implant $c $c.src
                use ghc-bindist.nu
                ghc-bindist install
            """),
        }],
        bin = ["ghc", "ghc-pkg", "runghc"],
        tests = {"version": "--numeric-version"},
        exports = False,
    )

    # the .deb's version, not the upstream pin
    if deb:
        spec["version"] = "9.10.3"
    return c.package(**spec)
