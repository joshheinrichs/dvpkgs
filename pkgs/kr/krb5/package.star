def package(c):
    return c.package(
        name = "krb5",
        # the Windows port is a separate nmake build
        platforms = {"os": ["linux", "macos"]},
        uses = ["autotools"],
        autotools = {
            "root": "src",
            "outOfTree": False,
            "flags": [
                "--with-crypto-impl=openssl",
                "--sysconfdir=/etc",
                "--localstatedir=/var",
                "--runstatedir=/run",
                # _GNU_SOURCE turns on glibc's const-preserving strchr, which this trips over in many files
                "krb5_cv_cc_flag__dash_Werror_eq_incompatible_dash_pointer_dash_types=no",
            ],
        },
        patches = [
            path("upstream-libdb2-test-dictionary-file.patch"),
            path("upstream-kpropd-loopback-only-listen.patch"),
            path("relocatable.patch"),  # plugin dirs, kprop and kdb5_util relative to the library or daemon
        ],
        phases = {"after": {"autotools.install": [{
            "name": "compile_et-dir",
            "run": "edit $\"($c.out)/bin/compile_et\" { str replace $\"DIR=($c.out)\" 'DIR=$(cd \"$(dirname \"$0\")/..\" && pwd -P)' }",
        }]}},
        tests = {"parallel": False},  # every test directory starts a KDC on the same fixed ports
        buildDependencies = [c.buildPkgs.bison, c.buildPkgs.perl],
        dependencies = [c.pkgs.openssl],
    )
