def package(c):
    return c.package(
        name = "test-tz",
        version = "1",
        source = path("src"),
        phases = [{
            "name": "build",
            "run": c.lib.text("""
                mkdir $"($c.out)/bin"
                x cc tz.c -o $"($c.out)/bin/tz"
            """),
        }],
    )
