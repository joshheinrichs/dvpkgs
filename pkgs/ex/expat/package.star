def package(c):
    return c.package(
        name = "expat",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {"EXPAT_BUILD_DOCS": False, "EXPAT_BUILD_EXAMPLES": False},
        },
    )
