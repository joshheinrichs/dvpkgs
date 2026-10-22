def package(c):
    return c.package(
        name = "mimalloc",
        uses = ["cmake"],
        cmake = {"defs": {"MI_INSTALL_TOPLEVEL": True}},  # lib/ and include/, not lib/mimalloc-x.y/
    )
