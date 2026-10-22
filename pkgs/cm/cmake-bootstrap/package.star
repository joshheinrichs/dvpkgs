# cmake built by its ./bootstrap (make, bundled libraries), for the build machine only: the cmake
# that builds zlib, zstd, expat, curl, libarchive and then cmake proper, which link those
def package(c):
    return c.package(
        name = "cmake-bootstrap",
        uses = ["make"],
        make = {
            "configureScript": "bootstrap",
            "configureFlags": [
                "--no-system-libs",
                "--no-qt-gui",
                "--docdir=share/doc/cmake",
                "--mandir=share/man",
                "--",
                "-DCMAKE_USE_OPENSSL=OFF",
                "-DBUILD_TESTING=OFF",
                "-DCMake_BUILD_LTO=OFF",
                "-DCMAKE_SYSTEM_PREFIX_PATH=%s" % c.toolchain.sysroot,
            ],
        },
        platforms = {"cross": False},
        tests = {"run": False},
        bin = ["cmake", "ctest", "cpack"],
    )
