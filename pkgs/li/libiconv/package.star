# iconv for the libc without one. Elsewhere its iconv.h would shadow libc's
def package(c):
    return c.package(name = "libiconv", uses = ["autotools"], platforms = {"os": ["windows"]})
