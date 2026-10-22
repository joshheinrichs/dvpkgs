def package(c):
    return c.package(
        name = "grep",
        uses = ["autotools"],
        bootstrapTools = True,
        autotools = {
            "flags": ["--disable-perl-regexp"],
            # spencer1 feeds patterns through `echo`, and dash's expands backslashes
            "makeFlags": ["SHELL=$(CONFIG_SHELL)"],
        },
        tests = {"separate": True, "dependencies": [c.buildPkgs.perl]},
        phases = {"after": {"autotools.install": [{
            # deprecated sh wrappers whose #! would be the build shell
            "name": "drop-egrep",
            "run": "cd $c.out; rm bin/egrep bin/fgrep",
        }]}},
    )
