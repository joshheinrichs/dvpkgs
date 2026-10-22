def package(c):
    return c.package(
        name = "test-npm",
        version = "2.0.0",
        source = path("src"),
        uses = ["npm"],
        npm = {"script": None},
        tests = {"version": "test-npm"},
    )
