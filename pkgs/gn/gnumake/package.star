def package(c):
    return c.package(
        name = "gnumake",
        uses = ["autotools"],
        bootstrapTools = True,
        # `include`/-l search and locale dir named the install prefix
        patches = [path("relocatable.patch")],
        autotools = {"flags": ["--without-guile"], "makeFlags": ["MAKEINFO=true"]},
        # src/w32 passes message buffers as format strings
        cc = {"hardening": {"format": c.platform.os != "windows"}},
        tests = {"separate": True, "dependencies": [c.buildPkgs.perl]},
        # general4 unsets PATH and expects confstr(_CS_PATH) to hold a shell
        phases = {"before": {"autotools.test": [{
            "name": "skip-general4",
            "run": "rm ($c.src)/tests/scripts/misc/general4",
        }]}},
        bin = ["make"],
    )
