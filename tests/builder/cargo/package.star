def package(c):
    return c.package(
        name = "test-cargo",
        version = "0.1.0",
        source = path("src"),
        uses = ["cargo"],
        cargo = {"deps": None},  # no third-party crates
        tests = {"version": "test-cargo"},
    )
