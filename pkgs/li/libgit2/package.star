def package(c):
    pkgs = c.pkgs
    return c.package(
        name = "libgit2",
        uses = ["cmake"],
        cmake = {"defs": {
            "BUILD_TESTS": False,
            "BUILD_CLI": False,
            "REGEX_BACKEND": "pcre2",
            "USE_SSH": "libssh2",
        }},
        dependencies = [pkgs.openssl, pkgs.pcre2, pkgs.zlib, pkgs.libssh2],
        buildDependencies = [c.buildPkgs.pkgconf],
        tests = {"run": False},  # slow and wants the network
    )
