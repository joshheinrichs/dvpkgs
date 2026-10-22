def package(c):
    return c.package(
        name = "lz4",
        uses = ["cmake"],
        cmake = {"tool": c.buildPkgs["cmake-bootstrap"], "root": "build/cmake"},  # cmake links this
    )
