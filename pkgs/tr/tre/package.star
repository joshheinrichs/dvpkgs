# also stands in for libgnurx/libregex on windows: <regex.h> and -lregex/-lgnurx over TRE's POSIX API
def package(c):
    platform = c.platform
    before_test = []

    # wretest hardcodes en_US.ISO-8859-1, our glibc only carries C.UTF-8
    if platform.libc == "glibc" and not platform.cross:
        before_test = [{
            "name": "latin1-locale",
            "run": c.lib.text(
                """
                let sr = "${sysroot}"
                mkdir locale
                # glibc's own tools keep the build-time interpreter path (pkgs/gl/glibc/bootstrap.nu runs them the same way)
                with-env { I18NPATH: $"($sr)/share/i18n" } {
                  x $"($sr)/lib/${interp}" --library-path $"($sr)/lib" $"($sr)/bin/localedef" --no-archive -i en_US -f ISO-8859-1 ./locale/en_US.ISO-8859-1
                }
                $env.LOCPATH = $"($env.PWD)/locale"
                """,
                sysroot = c.toolchain.sysroot,
                interp = platform.interp,
            ),
        }]
    after_install = []

    # mingw has no regex(3). Like MSYS2's libsystre: the POSIX names as real symbols forwarding to
    # tre_*, so `AC_CHECK_LIB(gnurx, regexec)` links, and a top-level regex.h
    if platform.os == "windows":
        after_install = [{
            "name": "system-regex",
            "run": c.lib.text(
                """
                "#include <tre/regex.h>\\n" | save $"($c.out)/include/regex.h"
                x cc -O2 $"-I($c.out)/include" -c ${systre} -o systre.o
                # -lregex / -lgnurx: the four POSIX symbols plus all of libtre in one archive
                for n in [regex gnurx] {
                  cp $"($c.out)/lib/libtre.a" $"($c.out)/lib/lib($n).a"
                  x llvm-ar q $"($c.out)/lib/lib($n).a" systre.o
                }
                """,
                systre = path("systre.c"),
            ),
        }]
    return c.package(
        name = "tre",
        uses = ["autotools"],
        patches = [path("upstream-llp64-align.patch"), path("upstream-mingw-wchar.patch")],
        autotools = {"flags": ["--disable-agrep", "--enable-static"]},
        phases = {
            "before": {"autotools.test": before_test},
            "after": {"autotools.install": after_install},
        },
    )
