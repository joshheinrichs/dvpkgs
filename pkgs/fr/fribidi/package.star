def package(c):
    return c.package(
        name = "fribidi",
        uses = ["meson"],
        meson = {"defs": {"docs": False}},
        buildDependencies = [c.buildPkgs.cpython],  # test runner
    )
