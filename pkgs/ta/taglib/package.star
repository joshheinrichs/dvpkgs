def package(c):
    return c.package(
        name = "taglib",
        uses = ["cmake"],
        patches = [path("relocatable.patch")],
        cmake = {"defs": {"WITH_ZLIB": True}},
        tests = {"run": False},  # needs cppunit
        dependencies = [c.pkgs.zlib, c.pkgs.utf8cpp],
    )
