def package(c):
    return c.package(
        name = "diffutils",
        uses = ["autotools"],
        bootstrapTools = True,
        patches = [path("upstream-strptime-prototypes.patch")],
        # man/ regenerates *.1 with help2man (perl)
        autotools = {"makeFlags": ["SUBDIRS=lib src"]},
        tests = {"separate": True, "dependencies": [c.buildPkgs.perl]},
        bin = ["diff", "cmp"],
    )
