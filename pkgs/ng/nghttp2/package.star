def package(c):
    return c.package(
        name = "nghttp2",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {"ENABLE_LIB_ONLY": True, "BUILD_TESTING": False},
        },
    )
