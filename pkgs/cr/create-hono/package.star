def package(c):
    return c.package(
        name = "create-hono",
        uses = ["bun"],
        tests = {"run": False, "version": True},  # its tests prompt for a package manager and time out
    )
