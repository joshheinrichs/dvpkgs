def package(c):
    return c.package(
        name = "sed",
        uses = ["autotools"],
        bootstrapTools = True,
        autotools = {"flags": ["--disable-acl", "--without-selinux"]},
        tests = {"separate": True, "dependencies": [c.buildPkgs.perl]},
    )
