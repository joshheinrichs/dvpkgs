def package(c):
    return c.package(
        name = "test-cmake",
        version = "1.2",
        source = path("src"),
        uses = ["cmake"],
        tests = {"version": "hello"},
    )
