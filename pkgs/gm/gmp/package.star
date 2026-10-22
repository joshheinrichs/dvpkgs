def package(c):
    return c.package(
        name = "gmp",
        uses = ["autotools"],
        patches = [path("upstream-loongarch-int128.patch")],
        autotools = {"flags": ["--enable-cxx", "--with-pic"]},
        buildDependencies = [c.buildPkgs.m4],
    )
