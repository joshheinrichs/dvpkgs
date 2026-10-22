def package(c):
    return c.package(
        name = "zstd",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "root": "build/cmake",
            "defs": {
                "ZSTD_BUILD_CONTRIB": False,
                "ZSTD_LEGACY_SUPPORT": False,
                "ZSTD_BUILD_TESTS": False,
            },
        },
        tests = {"run": False},  # 10 min of fuzz tests
        dependencies = [c.pkgs.zlib, c.pkgs.xz, c.pkgs.lz4],
    )
