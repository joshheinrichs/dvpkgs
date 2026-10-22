def package(c):
    return c.package(
        name = "abseil-cpp",
        uses = ["cmake"],
        cmake = {"defs": {
            "CMAKE_CXX_STANDARD": "17",
            "ABSL_PROPAGATE_CXX_STD": True,
            "ABSL_BUILD_TESTING": True,
            "ABSL_USE_EXTERNAL_GOOGLETEST": True,
        }},
        # time_test loads named zones. The bazel build points TZDIR at the bundled copy, cmake does not
        env = {"TZDIR": "%s/absl/time/internal/cctz/testdata/zoneinfo" % c.sources.fetch("default")},
        dependencies = [c.pkgs.googletest],
    )
