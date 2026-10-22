def package(c):
    return c.package(
        name = "libevdev",
        uses = ["meson"],
        meson = {"defs": {
            "documentation": "disabled",  # doxygen
            "tests": "disabled",  # libcheck
        }},
        buildDependencies = [c.buildPkgs.cpython],
        platforms = {"os": ["linux"]},
    )
