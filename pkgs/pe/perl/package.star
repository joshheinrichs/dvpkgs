def package(c):
    return c.package(
        # perl-cross has no win32 configuration
        platforms = {"posix": True},
        name = "perl",
        dependencies = [c.pkgs.zlib],
        uses = ["autotools"],
        bootstrapTools = True,
        autotools = {"outOfTree": False},
        phases = {
            "replace": {"autotools.configure": "perl.configure"},
            "after": {"autotools.install": "perl.scrub"},
        },
        env = {} if not c.platform.cross else {
            "PERL_CROSS": "%s" % c.sources.fetch("cross"),
            "PERL_CROSS_PATCH": path("upstream-cross-darwin.patch"),
            "PERL_SYSROOT": "%s" % c.toolchain.sysroot,
            # under perl-cross MakeMaker's fixin sees "env perl", not "perl", and resolves env on PATH
            "PERL_MM_SHEBANG": "relocatable",
        },
        tests = {"run": False},  # hours; t/ wants a hostname, /etc/protocols, ...
    )
