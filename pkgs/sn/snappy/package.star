def package(c):
    return c.package(
        name = "snappy",
        uses = ["cmake"],
        cmake = {"defs": {"SNAPPY_BUILD_BENCHMARKS": False}},  # wants google/benchmark
        patches = [path("system-gtest.patch")],  # upstream only knows the bundled submodule
        dependencies = [c.pkgs.googletest],
    )
