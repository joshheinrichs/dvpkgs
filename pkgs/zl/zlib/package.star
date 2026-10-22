def package(c):
    return c.package(
        name = "zlib",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {"ZLIB_BUILD_EXAMPLES": False},
            # coverage-summary wants gcov. The cmake-integration tests spawn a fresh native cmake+run
            "skipTests": ["coverage"] + c.on(c.platform.cross, ["add_subdirectory", "find_package"]),
        },
        tests = {"parallel": False},  # its cmake-integration tests race each other
    )
