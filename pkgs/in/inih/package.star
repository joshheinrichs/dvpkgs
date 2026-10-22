def package(c):
    return c.package(name = "inih", uses = ["meson"], meson = {"defs": {"with_INIReader": True}})
