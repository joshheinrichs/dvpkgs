def package(c):
    platform = c.platform
    return c.package(
        name = "openssl",
        # engines and providers next to the loaded libcrypto (reloc.h) instead of a configured libdir
        patches = [path("relocatable.patch")],
        cc = {"cflags": ["-DOSSL_RELOCATABLE"]},
        uses = ["make"],
        make = {
            # --openssldir is the ambient path, not a store path
            "configureScript": "Configure",
            "configureFlags": [
                platform.opensslTarget,
                "--libdir=lib",
                "--openssldir=/etc/ssl",
                "shared",
                "no-tests",
            ] + c.on(platform.os == "linux", ["enable-ktls"]),
            "installTarget": [
                "install_sw",
                "install_ssldirs",
                "install_man_docs",  # not install_docs: the HTML copy of the same pages
            ],
            "installFlags": ["OPENSSLDIR=$(prefix)/etc/ssl"],
        },
        # c_rehash is a perl script: perl would become a runtime dependency
        phases = {"after": {"make.install": [{"name": "no-c_rehash", "run": "rm ($c.out)/bin/c_rehash"}]}},
        tests = {"run": False, "version": "version"},
        buildDependencies = [c.buildPkgs.perl],
    )
