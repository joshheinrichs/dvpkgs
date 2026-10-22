def package(c):
    return c.package(
        name = "bison",
        uses = ["autotools"],
        bootstrapTools = True,
        buildDependencies = [c.buildPkgs.m4],
        dependencies = [c.pkgs.m4],
        autotools = {
            "flags": ["M4=%s/bin/m4" % c.pkgs.m4],
            # 764: the glr2.cc skeleton reads an uninitialized lookahead, which
            # -ftrivial-auto-var-init turns into a trap. Fixed after 3.8.2
            "makeFlags": ["TESTSUITEFLAGS=-j$(NIX_BUILD_CORES) 1-763 765-776"],
        },
        # share/bison and locale via reloc.h. gnulib's --enable-relocatable keeps the configured
        # prefix in the binary to compute the new one from
        patches = [path("relocatable.patch")],
        tests = {"separate": True, "dependencies": [c.buildPkgs.perl]},  # autom4te
        # the .yy.stamp rule touches into a directory only in-tree builds have
        phases = {"before": {"autotools.test": [{"name": "example-dirs", "run": "mkdir examples/c++/glr"}]}},
    )
