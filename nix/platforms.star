# CPU facts, the only place they live. `forSystem` / `mk(cpu, libc)` add the libc-dependent
# fields (clangTarget/gnuTriple/rustTriple, dynamic linker name) and `binfmt` (elf | macho |
# coff), which is what decides linker flavour, PIC, crt objects, interp/RUNPATH and whether
# launchers apply. `march` ends up in every cc invocation via jig.json, on linux with `cf`, the
# cpu's control-flow hardening. `hardening` is the cpu's verdict on builder/hardening.nu names it
# cannot take. `names`: what other ecosystems call the cpu (kernel ARCH=, GOARCH, rust triple
# prefix, meson cpu_family, qemu-user binary, gyp/V8 dest-cpu, apple's clang arch) where it
# differs from ours, and `osNames` the same for the os (cmake CMAKE_SYSTEM_NAME, meson system and
# kernel, GOOS, gyp/node --dest-os). A platform is a struct; it goes into every derivation.

def _ext(binfmt, libc):
    """File name pieces per binary format (and import library convention)."""
    return struct(
        exe = ".exe" if binfmt == "coff" else "",
        shared = {"elf": ".so", "macho": ".dylib", "coff": ".dll"}[binfmt],
        static = ".lib" if libc == "msvc" else ".a",
        # what -l<name> finds for a shared library where that is not the library itself
        **{"import": {"msvc": ".lib", "mingw": ".dll.a"}.get(libc)}
    )

_OSES = {
    "linux": struct(cmake = "Linux", meson = "linux", mesonKernel = "linux", go = "linux", gyp = "linux", uname = "Linux"),
    "windows": struct(cmake = "Windows", meson = "windows", mesonKernel = "nt", go = "windows", gyp = "win", uname = "Windows_NT"),
    "macos": struct(cmake = "Darwin", meson = "darwin", mesonKernel = "xnu", go = "darwin", gyp = "mac", uname = "Darwin"),
}

CPUS = {
    "x86_64": {
        "names": {"kernel": "x86", "go": "amd64", "gyp": "x64", "openssl": "linux-x86_64"},
        "march": ["-march=x86-64-v3"],
        "cf": ["-fcf-protection=full"],
        "interp": {"glibc": "ld-linux-x86-64.so.2"},
    },
    "aarch64": {
        "names": {"kernel": "arm64", "go": "arm64", "gyp": "arm64", "clang": "arm64", "openssl": "linux-aarch64"},
        "march": ["-march=armv8.2-a+lse"],
        "cf": ["-mbranch-protection=standard"],
        "interp": {"glibc": "ld-linux-aarch64.so.1"},
    },
    "riscv64": {
        "names": {"kernel": "riscv", "rust": "riscv64gc"},
        # -mno-relax: lld 21 leaves R_RISCV_IRELATIVE addends unadjusted after relaxation, so
        # ld.so jumps into the middle of memcpy instead of the ifunc resolver
        "march": ["-march=rv64gc", "-mabi=lp64d", "-mno-relax"],
        # clang 23.1 SIGSEGVs in prologue/epilogue insertion on frames over 4 KiB with it
        "hardening": {"zerocallusedregs": False},
        "interp": {"glibc": "ld-linux-riscv64-lp64d.so.1"},
    },
    # Loongson 3A5000+ (LA464): the LA64 v1.0 baseline every shipped core has
    "loongarch64": {
        "names": {"kernel": "loongarch", "go": "loong64", "gyp": "loong64"},
        "march": ["-march=loongarch64", "-mabi=lp64d"],
        # clang has it for x86, arm and riscv only
        "hardening": {"zerocallusedregs": False},
        "interp": {"glibc": "ld-linux-loongarch-lp64d.so.1"},
    },
    # POWER9 and later, little endian, ELFv2, IEEE long double (what current distros ship)
    "powerpc64le": {
        "names": {"kernel": "powerpc", "go": "ppc64le", "meson": "ppc64", "gyp": "ppc64", "qemu": "ppc64le", "openssl": "linux-ppc64le"},
        # clang defaults to the IBM long double unless built with PPC_LINUX_DEFAULT_IEEELONGDOUBLE,
        # and warns about -mabi= unless it finds a glibc >= 2.32 at /lib64/ld64.so.2
        "march": ["-mcpu=power9", "-mabi=ieeelongdouble", "-Wno-unsupported-abi"],
        "hardening": {"zerocallusedregs": False},
        "interp": {"glibc": "ld64.so.2"},
    },
}

_NAME_KEYS = ["clang", "gyp", "go", "kernel", "meson", "openssl", "qemu", "rust"]

def _names(cpu):
    c = CPUS[cpu]["names"]
    return struct(**{n: c.get(n, cpu) for n in _NAME_KEYS})

def mk(cpu, libc):
    """Linux on `cpu` with `libc` (glibc or musl)."""
    c = CPUS[cpu]
    names = _names(cpu)
    clang_target = cpu + "-unknown-linux-" + {"glibc": "gnu", "musl": "musl"}[libc]
    return struct(
        abi = "gnu",
        binfmt = "elf",
        # three spellings of one platform, named by consumer: clang -target, configure --host
        # (config.sub), rustc/cargo. They coincide on linux and diverge on macos
        clangTarget = clang_target,
        cpu = cpu,
        ext = _ext("elf", libc),
        gnuTriple = clang_target,
        hardening = c.get("hardening", {}),
        interp = "ld-musl-" + cpu + ".so.1" if libc == "musl" else c["interp"]["glibc"],
        libc = libc,
        march = c["march"] + c.get("cf", []),
        name = cpu + "-linux",
        names = names,
        opensslTarget = c["names"].get("openssl", "linux64-" + cpu),  # its Configure's own table
        os = "linux",
        osNames = _OSES["linux"],
        posix = True,
        rustTriple = names.rust + "-unknown-linux-" + ("musl" if libc == "musl" else "gnu"),
    )

# The non-Linux targets. PE and Mach-O find libraries beside the binary / by install name, so
# there is no interp and finish/launchers have nothing to do. macOS and msvc take libc, C++
# library and SDK as given (pkgs/ap/apple-sdk, pkgs/wi/windows-sdk); windows gnu is mingw-w64 on
# UCRT with our libc++. `abi` tells the two windows apart, `posix` is what packages needing
# fork/signals/ttys ask for. `minos` is the deployment target.
def _given(cpu, **o):
    fields = {
        "cpu": cpu,
        "names": _names(cpu),
        "osNames": _OSES[o["os"]],
        "name": cpu + "-" + o["os"],
        "posix": o["os"] != "windows",
        "interp": "",
        "ext": _ext(o["binfmt"], o["libc"]),
        "march": CPUS[cpu]["march"],
        "hardening": {},
    }
    fields.update(o)
    return struct(**fields)

def _msvc(cpu):
    t = cpu + "-pc-windows-msvc"
    return _given(
        cpu,
        name = cpu + "-windows-msvc",
        os = "windows",
        binfmt = "coff",
        libc = "msvc",
        abi = "msvc",
        clangTarget = t,
        gnuTriple = t,
        rustTriple = t,
        opensslTarget = "VC-WIN64-CLANGASM-ARM" if cpu == "aarch64" else "VC-WIN64A",
    )

def _mingw(cpu):
    t = cpu + "-w64-mingw32"
    return _given(
        cpu,
        name = cpu + "-windows-gnu",
        os = "windows",
        binfmt = "coff",
        libc = "mingw",
        abi = "gnu",
        clangTarget = t,
        gnuTriple = t,
        rustTriple = cpu + "-pc-windows-gnullvm",
        opensslTarget = "mingwarm64" if cpu == "aarch64" else "mingw64",
    )

def _macos(cpu):
    minos = "14.0"
    clang = CPUS[cpu]["names"].get("clang", cpu)
    return _given(
        cpu,
        os = "macos",
        abi = "apple",
        binfmt = "macho",
        libc = "apple",
        minos = minos,
        clangTarget = clang + "-apple-macos" + minos,
        gnuTriple = cpu + "-apple-darwin",
        rustTriple = cpu + "-apple-darwin",
        opensslTarget = "darwin64-" + clang,
        march = ["-mcpu=apple-m1"],
    )

def for_system(system, libc):
    return mk(system.split("-")[0], libc)

def _by_name():
    ps = [mk(cpu, "glibc") for cpu in sorted(CPUS)] + [
        _msvc("x86_64"),
        _msvc("aarch64"),
        _mingw("x86_64"),
        _mingw("aarch64"),
        _macos("aarch64"),
    ]
    return {p.name: p for p in ps}

# every target platform by its name. glibc linux for all cpus, the rest as listed
BY_NAME = _by_name()
