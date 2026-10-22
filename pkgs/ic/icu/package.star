def package(c):
    platform = c.platform
    return c.package(
        name = "icu",
        uses = ["autotools"],
        autotools = {
            "root": "source",
            "flags": ["--disable-icu-config"] +
                     # icu.nu cross-buildroot makes that directory. /build is the sandbox's build dir on every Linux Nix
                     c.on(platform.cross, ["--with-cross-build=/build/native-icu"]) +
                     # without it mh-darwin's install_name is a bare file name, which dyld looks up in the cwd
                     c.on(platform.os == "macos", ["--enable-rpath"]),
        },
        patches = [path("upstream-ssearch-snprintf-bound.patch")],  # a test trips _FORTIFY_SOURCE=3
        phases = {
            "before": {"autotools.configure": c.on(platform.cross, ["icu.cross-buildroot"])},
            "after": {"autotools.install": ["icu.relative-prefix"]},
        },
        buildDependencies = c.on(platform.cross, [c.buildPkgs.icu]),
    )
