def package(c):
    return c.package(
        name = "m4",
        uses = ["autotools"],
        bootstrapTools = True,
        tests = {"separate": True},  # the suite wants a real awk and diff, m4 is built with the seed only
    )
