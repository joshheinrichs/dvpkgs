def package(c):
    return c.package(name = "gperf", uses = ["autotools"], bootstrapTools = True)
