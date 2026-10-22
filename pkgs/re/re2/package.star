def package(c):
    return c.package(
        name = "re2",
        uses = ["cmake"],
        cmake = {"defs": {"RE2_TEST": True}},  # RE2_BUILD_TESTING also wants google benchmark
        dependencies = [c.pkgs["abseil-cpp"], c.pkgs.googletest],
    )
