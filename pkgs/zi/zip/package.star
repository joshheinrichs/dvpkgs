# Info-ZIP 3.0 (2008). unix/configure probes with K&R test programs a current compiler rejects
# and then claims glibc lacks memset, mktemp, dirent …, so the flags are given directly.
def package(c):
    return c.package(
        name = "zip",
        # unix/Makefile
        platforms = {"posix": True},
        # glibc's fortified printf macro hid these from -Wformat-security
        patches = [path("upstream-format-security.patch")],
        phases = [{
            "name": "build",
            "run": c.lib.text("""
                let cflags = "-O2 -I. -DUNIX -DUIDGID_NOT_16BIT -DLARGE_FILE_SUPPORT -DUNICODE_SUPPORT -DHAVE_DIRENT_H -DHAVE_TERMIOS_H -std=gnu89 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-deprecated-non-prototype"
                x make -f unix/Makefile zip CC=cc "CPP=cc -E" $"CFLAGS=($cflags)" OCRCU8=crc32_.o LFLAGS2= $"-j($c.njobs)"
            """),
        }],
        install = {"bin/zip": "zip"},
        tests = {"version": "-v"},
    )
