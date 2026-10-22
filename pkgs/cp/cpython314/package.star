# CPython itself, the interpreter package. The python *build system* module is what builds wheels.
# Environments and projects on top of it: nix/python.star.
def package(c):
    pkgs = c.pkgs
    platform = c.platform
    msvc = platform.abi == "msvc"
    return c.package(
        name = "cpython314",
        # configure: "cross build not supported" for mingw
        platforms = {"libc": ["glibc", "musl", "apple", "msvc"]},
        uses = ["vcxproj" if msvc else "autotools"],
        autotools = {} if msvc else {"flags": [
            "--disable-test-modules",
            "--without-ensurepip",
            "--with-openssl=%s" % pkgs.openssl,
            "--with-system-libmpdec",
            "ac_cv_file__dev_ptmx=yes",
            "ac_cv_file__dev_ptc=no",
            # by name: AC_PATH_TOOL would record the toolchain's store path in _sysconfigdata
            "ac_cv_path_LLVM_PROFDATA=llvm-profdata",
            "ac_cv_path_ac_pt_LLVM_PROFDATA=llvm-profdata",
            "ac_cv_path_LLVM_AR=llvm-ar",
            "ac_cv_path_ac_pt_LLVM_AR=llvm-ar",
        ] + c.on(platform.cross, [
            # cross: configure needs a same-version build-machine python and cannot run test programs
            "--with-build-python=python3",  # by name: _sysconfigdata records CONFIG_ARGS
            "ac_cv_buggy_getaddrinfo=no",
        ])},
        # no compiled-in PREFIX: an installed python is where its binary (/proc/self/exe, as macOS
        # asks the OS) or libpython is, a build tree one uses the source dir. sysconfig data and
        # .pyc paths relative, python-config from $0. LIBPL gets no copy of the build Makefile and
        # python-config.py (records of the build, nothing reads them)
        patches = [path("relocatable.patch"), path("upstream-darwin-cross-xopen.patch")],
        # pcbuild.proj is the solution's traversal project. _freeze_module is a build-machine tool
        # (cpython.frozen-modules stands in), the py launcher and shell extension are installer material
        vcxproj = {} if not msvc else {
            "projects": ["PCbuild/pcbuild.proj"],
            "exclude": ["_freeze_module", "pylauncher", "pywlauncher", "pyshellext"],
            # PCbuild compiles these libraries in from source directories it is pointed at
            "properties": {
                "bz2Dir": "%s/" % pkgs.bzip2.src,
                "mpdecimalDir": "%s/" % pkgs.mpdecimal.src,
                "lzmaDir": "%s/" % c.sources.fetch("xz"),
                "sqlite3Dir": "%s/" % c.sources.fetch("sqlite"),
                "zstdDir": "%s/" % pkgs.zstd.src,
                "zlibNgDir": "%s/" % c.sources.fetch("zlib-ng"),
            },
            "install": {"DynamicLibrary": "DLLs", "Application": "."},
        },
        phases = {
            "before": {"vcxproj.configure": c.on(msvc, ["cpython.properties", "cpython.frozen-modules", "cpython.zlib-ng-headers"])},
            "after": {
                "vcxproj.install": c.on(msvc, ["cpython.windows-layout"]),
                "autotools.install": c.on(not msvc, ["cpython.build-details"]),
            },
        },
        tests = {"run": False},  # hours
        dependencies = [] if msvc else [
            pkgs.zlib,
            pkgs.xz,
            pkgs.bzip2,
            pkgs.libffi,
            pkgs.openssl,
            pkgs.expat,
            pkgs.sqlite,
            pkgs.mpdecimal,
        ],
        buildDependencies = c.on(platform.cross, [c.buildPkgs.cpython]),
        bin = ["python" if msvc else "python3"],
        # bin/ is where finish.nu looks; the Windows layout has python.exe at the root
        links = c.on(msvc, {"bin/python": "python"}),
    )
