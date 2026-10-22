# cabal-install from hackage, built by ghc-bootstrap and upstream's cabal binary
def package(c):
    return c.package(
        name = "cabal",
        uses = ["cabal"],
        cabal = {"tool": c.buildPkgs["cabal-bootstrap"], "exes": ["cabal"]},
        # the suites need Cabal-described, in cabal's repo but not on hackage
        tests = {"run": False, "version": "--numeric-version"},
    )
