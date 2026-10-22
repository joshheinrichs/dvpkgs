def package(c):
    return c.package(
        name = "libuv",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {"LIBUV_BUILD_TESTS": False},
        },
        # static libuv.lib beside the DLL's uv.lib: FindLibUV picks it and nobody links its userenv/ws2_32
        phases = {"after": {"cmake.install": c.on(c.platform.abi == "msvc", [{
            "name": "shared-only",
            "run": 'rm $"($c.out)/lib/libuv.lib" $"($c.out)/lib/pkgconfig/libuv-static.pc"',
        }])}},
    )
