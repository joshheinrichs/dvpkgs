def package(c):
    return c.package(name = "oniguruma", uses = ["autotools"], autotools = {"configureScript": "configure"})
