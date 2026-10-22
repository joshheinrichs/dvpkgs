def package(c):
    return c.package(
        name = "test-go",
        version = "1",
        source = path("src"),
        uses = ["go"],
        go = {
            "packages": ["."],
            "deps": None,  # no third-party modules, no go.sum
        },
        tests = {"version": "hello"},
    )
