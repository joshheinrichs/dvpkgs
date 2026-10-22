# double precision. Single and long double are separate builds of the same tree
def package(c):
    windows = c.platform.os == "windows"
    return c.package(
        name = "fftw",
        uses = ["autotools"],
        autotools = {
            "flags": [
                "--enable-threads",
                # AX_CC_MAXOPT adds -mtune=native when CFLAGS is unset: the output would depend on the builder
                "CFLAGS=-O3 -fomit-frame-pointer -fstrict-aliasing",
            ] + c.on(windows, ["--with-combined-threads"]),
            # a DLL cannot leave symbols for the main library to fill in: fold the threads code into
            # libfftw3 itself (what upstream recommends for Windows) and tell libtool nothing is undefined
            "makeFlags": c.on(windows, ["LDFLAGS=-no-undefined"]),
        },
        buildDependencies = [c.buildPkgs.perl],  # tests/check.pl
    )
