# LLVM's OpenMP host runtime (libomp.so, omp.h) for packages built with -fopenmp. A separate
# package rather than part of `cc`. The compiler-facing ABI (__kmpc_*, GOMP_*) is append-only,
# so this pin may differ from the toolchain's LLVM version
def package(c):
    spec = dict(
        name = "libomp",
        uses = ["cmake"],
        cmake = {
            "root": "runtimes",
            "defs": {
                "LLVM_ENABLE_RUNTIMES": "openmp",
                "LLVM_INCLUDE_TESTS": False,
                "OPENMP_ENABLE_LIBOMPTARGET": False,  # no device offload
                "LIBOMP_OMPD_SUPPORT": False,  # debugger plugin, needs libpython
                "LIBOMP_INSTALL_ALIASES": False,  # libgomp.so/libiomp5.so compatibility symlinks
                "OPENMP_ENABLE_OMPT_TOOLS": False,  # libarcher (TSan annotations)
                "OPENMP_ENABLE_TESTING": False,
            },
        },
        buildDependencies = [c.buildPkgs.cpython],  # generates the message catalog and .def files
        tests = {"run": False},  # the tests need lit and FileCheck
    )

    # kmp_wrapper_getpid.h only typedefs pid_t under a cl-style driver, ours is gcc-style on msvc too
    if c.platform.libc == "msvc":
        spec["cc"] = {"cflags": ["-Dpid_t=int"]}

    # not on x86_64 Windows yet: z_Windows_NT-586_asm.asm needs MASM (llvm-ml, added to cc separately)
    if c.platform.cpu == "x86_64":
        spec["platforms"] = {"os": ["linux", "macos"]}
    return c.package(**spec)
