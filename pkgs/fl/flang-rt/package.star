# The Fortran runtime for the target (libflang_rt.runtime.a, intrinsic .mod files), compiled
# by the build machine's flang, plus jig as bin/{gfortran,flang,fortran} with a jig.json that
# runs that flang against cc's sysroot and this runtime
load("//pkgs/ll/llvm/subproject.star", "subproject")

def package(c):
    platform = c.platform
    flang = "%s/bin/flang" % c.buildPkgs.flang

    # flang rejects the clang-only per-cpu flags (-mabi, -mbranch-protection, ...)
    target = ["--target=" + platform.clangTarget] + [
        f
        for f in platform.march
        if f.startswith("-march=") or f.startswith("-mcpu=")
    ] + ["--sysroot=%s" % c.toolchain.sysroot]
    defs = {
        "LLVM_ENABLE_RUNTIMES": "flang-rt",
        "LLVM_DEFAULT_TARGET_TRIPLE": platform.clangTarget,
        "CMAKE_Fortran_COMPILER": flang,
        "CMAKE_Fortran_COMPILER_WORKS": True,
        "CMAKE_Fortran_FLAGS": " ".join(target),
        "FLANG_RT_INCLUDE_TESTS": False,
    }

    # IEEE long double would need __fixkfti and quadmath support compiler-rt lacks. flang has no
    # REAL(16) on ppc64le, so IBM long double loses nothing
    defs.update(c.on(platform.cpu == "powerpc64le", {
        "CMAKE_CXX_FLAGS": "-mabi=ibmlongdouble",
        "HAVE_LDBL_MANT_DIG_113": False,
        "FOUND_LIBMF128": False,
    }))
    return subproject(c, c.pkgs.llvm, c.buildPkgs.llvm, "runtimes", {
        "name": {"set": "flang-rt"},
        "cmake": {"defs": {"merge": defs}},
        # a static runtime, nothing of llvm is linked (LLVM_DIR still finds its cmake files)
        "dependencies": {"set": []},
        "platforms": {"set": {"os": ["linux"]}},
        "phases": {"after": {"set": {"cmake.install": [
            {
                "name": "gfortran",
                "run": c.lib.text(
                    """
                    # "@/" is jig's own prefix (driver.cc), so the conf survives the move to the store
                    let rt = (files --dirs $"($c.out)/lib/clang/*/lib/*" | first | str replace $c.out "@")
                    let finclude = (files --dirs $"($c.out)/lib/clang/*/finclude/flang/*" | first | str replace $c.out "@")
                    mkdir $"($c.out)/bin" $"($c.out)/etc"
                    let fflags = [-B${toolchain}/bin ${target} $"-resource-dir=($c.platform.sysroot)/lib/clang" -rtlib=compiler-rt -fintrinsic-modules-path $finclude $"-L($rt)"]
                    open "${toolchain}/etc/jig.json" | reject flags cxxflags prefix-map | merge {fc: "${flang}", fflags: $fflags} | save $"($c.out)/etc/jig.json"
                    cp "${toolchain}/etc/roots" $"($c.out)/etc/"
                    cp "${toolchain}/bin/jig" $"($c.out)/bin/"
                    for n in [gfortran flang fortran] { ln -s jig $"($c.out)/bin/($n)" }
                    """,
                    toolchain = c.toolchain,
                    target = " ".join(target),
                    flang = flang,
                ),
            },
            {
                "name": "hello.f90",
                "run": c.lib.text("""
                    "program h\\n use iso_fortran_env\\n print *, compiler_version()\\nend program\\n" | save hello.f90
                    x $"($c.out)/bin/gfortran" hello.f90 -o hello
                    if not $c.platform.cross { x ./hello }
                """),
            },
        ]}}},
        "bin": {"set": ["gfortran"]},
    })
