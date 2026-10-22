def package(c):
    return c.package(
        name = "test-cabal",
        version = "0.1.0.0",
        source = path("src"),
        uses = ["cabal"],
        cabal = {"exes": ["test-cabal"]},
        tests = {"version": "test-cabal"},
    )
