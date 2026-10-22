def package(c):
    return c.package(
        name = "lowdown",
        # oconfigure knows ELF and Mach-O shared libraries
        platforms = {"posix": True},
        uses = ["make"],
        patches = [path("upstream-portable-make.patch")],
        # oconfigure takes KEY=value, not --prefix. seccomp probes the build machine's uname -m
        make = {
            "configureScript": "none",
            "testTarget": ["regress"],
            "installTarget": ["install", "install_shared"],
        },
        phases = {"before": {"make.build": [{
            "name": "oconfigure",
            "run": c.lib.text(
                """
                "HAVE_SECCOMP_FILTER=0\\nHAVE_SANDBOX_INIT=0\\nHAVE_PLEDGE=0\\n" | save configure.local
                # dash: it relies on echo expanding \\n
                x sh ./configure $"PREFIX=($c.out)" $"MANDIR=($c.out)/share/man" LINK_METHOD=shared LINKER_SOSUFFIX=${suffix}
                $env.LD_LIBRARY_PATH = $env.PWD # for regress
                """,
                suffix = "dylib" if c.platform.os == "macos" else "so",
            ),
        }]}},
        bin = ["lowdown", "lowdown-diff"],
    )
