def package(c):
    return c.package(
        name = "protobuf",
        uses = ["cmake"],
        cmake = {"defs": {
            "protobuf_ABSL_PROVIDER": "package",
            "protobuf_BUILD_SHARED_LIBS": True,
            "protobuf_USE_EXTERNAL_GTEST": True,
        }},
        dependencies = [c.pkgs.googletest, c.pkgs["abseil-cpp"], c.pkgs.zlib],
    )
