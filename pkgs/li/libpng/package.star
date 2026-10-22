def package(c):
    return c.package(
        name = "libpng",
        uses = ["cmake"],
        # upstreamable: generated under NOT WIN32, installed under NOT CMAKE_HOST_WIN32
        patches = [path("upstream-cmake-install-pc-when-generated.patch")],
        cmake = {"defs": {"PNG_STATIC": False, "PNG_TOOLS": True}},
        dependencies = [c.pkgs.zlib],
    )
