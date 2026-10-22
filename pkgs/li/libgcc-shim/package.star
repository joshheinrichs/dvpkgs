# lib/libgcc_s.so.1 with the GCC_* symbol versions upstream-built binaries link, backed by our
# libunwind. Only `prebuilt` packages need it, our libc loads libunwind.so.1 directly.
def package(c):
    return c.package(
        name = "libgcc-shim",
        version = "1",
        source = path("src"),
        platforms = {"os": ["linux"]},
        phases = [{
            "name": "build",
            "run": c.lib.text(
                """
                mkdir $"($c.out)/lib"
                (x cc -shared -O2 -o $"($c.out)/lib/libgcc_s.so.1" $"($c.src)/gcc_s.c"
                  $"-Wl,--version-script=($c.src)/gcc_s.ver" -Wl,-soname,libgcc_s.so.1
                  -Wl,--whole-archive $"${sysroot}/lib/libunwind.a" -Wl,--no-whole-archive -nostdlib++)
                """,
                sysroot = c.toolchain.sysroot,
            ),
        }],
        exports = {"libs": []},
    )
