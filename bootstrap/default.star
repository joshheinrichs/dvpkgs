# From the seed to a configured `cc` per platform:
#   stage0  seed clang, musl    -> jig and a cc for the build machine
#   stage1  seed clang, glibc   -> a cc to host cmake and llvm (clang+lld, all targets, toolchain.nu)
#   stage2  our clang           -> compiler-rt, libc, libc++, cc and launch for every platform
# Each derivation is `nu run.nu <recipe>.nu` with structured attrs as its environment. Recipes
# live with their package (pkgs/<name>/bootstrap.nu, pkgs/ll/llvm/*.nu) or here (sysroot.nu).
#
# `bootstrap(system, seed)` is a lazy set: `seed`, `stage0`, `stage1`, and per platform name its
# stage2 chain, each computed once and cached as a whole.

load("//nix/lib.star", "to_string")
load("//nix/platforms.star", "BY_NAME", "for_system")
load("//nix/sources.star", "read_sources")
load("//pkgs/ll/llvm/defs.star", "DEFS")

def bootstrap(system, seed = None, sdk = None):
    """`sdk`: the windows SDK msvc toolchains are built on (nix/set.star fetches it)."""
    return lazy_attrs(bootstrap_attr, {"system": system, "seed": seed, "sdk": sdk})

def _pkg(name):
    return "//pkgs/" + name[:2] + "/" + name

def _seed_path(a):
    seed = a["seed"]
    if seed == None:
        # the seed's own sources.toml is read without an unpacker: it is the unpacker
        return read_sources(_pkg("seed") + "/sources.toml", None).fetch(a["system"])
    if type(seed) == "string":
        return store_path(seed)
    return seed

def bootstrap_attr(name, a):
    b = bootstrap(a["system"], a["seed"], a["sdk"])
    if name == "seed":
        return _seed_path(a)
    s = _Stages(a, b.seed)
    if name == "stage0":
        return s.stage0()
    if name == "stage1":
        return s.stage1(b.stage0)
    if name in BY_NAME:
        return s.chain_for(BY_NAME[name], b.stage0, b.stage1, a["sdk"], lambda: getattr(b, s.build_platform.name).cc)
    fail("bootstrap has no " + name)

_RECIPES = {
    "sysroot": "//bootstrap/sysroot.nu",
    "compiler-rt": _pkg("llvm") + "/compiler-rt.nu",
    "runtimes": _pkg("llvm") + "/runtimes.nu",
    "cc": _pkg("llvm") + "/cc.nu",
    "llvm": _pkg("llvm") + "/toolchain.nu",
    "cmake": _pkg("cmake-bootstrap") + "/bootstrap.nu",
    "linux-headers": _pkg("linux") + "/bootstrap.nu",
}

_GLIBC_PATCHES = [
    "glibc-prefix-relative.patch",
    "upstream-ppc64le-clang.patch",
    "upstream-debug-after-misc.patch",
    "upstream-verneed-dst.patch",
    "glibc-unwind-origin.patch",
    "glibc-tzdir-etc-zoneinfo.patch",
    "upstream-const-generic-extension.patch",
    "glibc-loongarch-rtld-bcmp.patch",
    "upstream-ldbl128-literal.patch",
]

# `derivation` plus the attributes later stages read off a step
_KEEP = ["sysroot"]

def mk_drv(**attrs):
    return with_attrs(derivation(**attrs), **{k: attrs[k] for k in _KEEP if k in attrs})

def _Stages(a, seed):
    system = a["system"]
    seed_s = to_string(seed)

    def source(name):
        return read_sources(_pkg(name) + "/sources.toml", seed, system).fetch("default")

    # per recipe, so that editing jig rebuilds jig and cc, not glibc
    def recipe_inputs(name):
        if name == "jig":
            return {
                "jig": path(_pkg("jig") + "/src", name = "jig-src"),
                "blake3": source("blake3"),
                "zstd": source("zstd"),
                "json_hpp": source("nlohmann-json"),
                "storeDir": "/nix/store",
            }
        if name == "launch":
            return {"launch": path(_pkg("launch") + "/src/launch.cc"), "json_hpp": source("nlohmann-json")}
        if name == "cc":
            return {
                "crt_interp": path(_pkg("crt-interp") + "/src/crt_interp.c"),
                "reloc": path(
                    _pkg("crt-interp") + "/src",
                    name = "reloc",
                    filter = lambda p, _t: p.rpartition("/")[2].startswith("reloc"),
                ),
            }
        if name == "dlaudit":
            return {"dlaudit": path(_pkg("dlaudit") + "/src/dlaudit.cc")}
        if name == "llvm":
            return {
                "src": source("llvm"),
                "zstd": source("zstd"),
                "zlib": source("zlib"),
                "patches": [
                    path(_pkg("llvm") + "/upstream-x86-vastart-stack-probe.patch"),
                    path(_pkg("llvm") + "/jig-absent-log.patch"),
                ],
                "targets": DEFS["LLVM_TARGETS_TO_BUILD"],
            }
        if name == "cmake":
            return {"src": source("cmake-bootstrap")}
        if name in ("compiler-rt", "runtimes"):
            return {"src": source("llvm")}
        if name in ("linux-headers", "musl", "mingw-w64", "apple-sdk"):
            return {"src": source({"linux-headers": "linux"}.get(name, name))}
        if name == "glibc":
            return {"src": source("glibc"), "patches": [path(_pkg("glibc") + "/" + p) for p in _GLIBC_PATCHES]}
        return {}

    # the recipe plus what it imports, laid out as in the tree (bootstrap/, builder/, pkgs/x/x/)
    # so `use ../../bootstrap/lib.nu` resolves and an edit to one recipe rebuilds only its step
    def recipe(name):
        file = _RECIPES.get(name, _pkg(name) + "/bootstrap.nu")
        rel = "bootstrap/" + name + ".nu" if name == "sysroot" else "pkgs/x/x/" + name + ".nu"
        layout = {
            "bootstrap/run.nu": path("//bootstrap/run.nu"),
            "bootstrap/lib.nu": path("//bootstrap/lib.nu"),
            "builder/glob.nu": path("//builder/glob.nu"),
            "builder/log.nu": path("//builder/log.nu"),
            rel: path(file),
        }
        return struct(rel = rel, path = mk_drv(
            name = "recipe-" + name,
            system = system,
            builder = seed_s + "/bin/nu",
            layout = to_json(layout),
            args = [
                "--no-config-file",
                "-c",
                "$env.layout | from json | items {|rel, src| mkdir ($\"($env.out)/($rel)\" | path dirname); cp $src $\"($env.out)/($rel)\" }",
            ],
            preferLocalBuild = True,
        ))

    common = {
        "system": system,
        "__structuredAttrs": True,
        "__contentAddressed": True,
        "outputHashMode": "recursive",
        "outputHashAlgo": "sha256",
        "outputs": ["out"],
        "seed": seed,
        "builder": seed_s + "/bin/nu",
        "JIG_STORE_IDENTITY": "content",
        "M4": "m4",
        "BISON_PKGDATADIR": seed_s + "/share/bison",
        "CONFIG_SITE": path("//nix/config.site"),
    }

    # `mk_stage(...)(extra_tools, recipe, args)`: one recipe run. PATH is extra_tools (jig's
    # clang shim first once it exists), stage.tools, the seed. JIG_CC is the clang behind the shim
    def mk_stage(platform, clang = None, tools = [], suffix = None):
        clang = seed if clang == None else clang
        suffix = "-" + platform.name if suffix == None else suffix
        per_stage = dict(common)
        per_stage.update(
            clangTarget = platform.clangTarget,
            cpu = platform.cpu,
            libc = platform.libc,
            os = platform.os,
            binfmt = platform.binfmt,
            interp = platform.interp,
            karch = platform.names.kernel,
            site_libc = platform.libc,
            flags = to_string(platform.march),
            llvm = clang,
            JIG_CC = to_string(clang) + "/bin/clang",
        )

        def bin_path(ts):
            return ":".join([to_string(t) + "/bin" for t in ts])

        base_path = bin_path(tools + [seed])

        def run(extra_tools, recipe_name, args):
            r = recipe(recipe_name)
            attrs = dict(per_stage)
            attrs.update(
                name = recipe_name + ("-headers" if "headersOnly" in args else "") + suffix,
                args = ["--no-config-file", to_string(r.path) + "/bootstrap/run.nu", to_string(r.path) + "/" + r.rel],
                PATH = base_path if not extra_tools else bin_path(extra_tools) + ":" + base_path,
            )
            attrs.update(recipe_inputs(recipe_name))
            attrs.update(args)
            return mk_drv(**attrs)

        return run

    # libc headers -> compiler-rt -> libc -> (kernel headers) -> libc++/libunwind -> sysroot -> cc.
    # The libc is a recipe run twice (headersOnly first) or `libc_given`, an SDK that also brings
    # the C++ library. `extra_parts(compiler_rt, libc)`: more sysroot parts, which may be built
    # on the libc. `with_cc = False` for a caller that makes its own.
    def chain(platform, run, libc_recipe = None, libc_args = {}, libc_given = None, linux_headers = None, extra_parts = None, cc_args = {}, with_cc = True):
        given = libc_given != None

        def libc_step(args):
            if given:
                return libc_given
            a = dict(libc_args)
            a.update(args)
            return run([], libc_recipe, a)

        builtins_list = path(_pkg("llvm") + "/builtins-" + (platform.cpu if platform.os == "linux" else platform.name) + ".txt")
        crt_args = {"libcHeaders": libc_step({"headersOnly": "1"}), "list": builtins_list}
        if linux_headers != None:
            crt_args["linuxHeaders"] = linux_headers
        compiler_rt = run([], "compiler-rt", crt_args)

        def sysroot(parts):
            return run([], "sysroot", {"parts": [p for p in parts if p != None], "resource": compiler_rt})

        libc = libc_step({"compiler-rt": compiler_rt})
        base = [libc, linux_headers] + (extra_parts(compiler_rt, libc) if extra_parts else [])
        runtimes = None if given else run([], "runtimes", {"sysroot": sysroot(base)})
        full = sysroot(base + [runtimes])
        cc = None
        if with_cc:
            cc_a = {"sysroot": full}
            cc_a.update(cc_args)
            cc = run([], "cc", cc_a)
        return dict(platform = platform, compiler_rt = compiler_rt, libc = libc, runtimes = runtimes, cc = cc, sysroot = full)

    build_platform = for_system(system, "glibc")

    # `with_launch = False` for stage1, whose launch and dlaudit nothing uses
    def linux_chain(platform, run, cc_args, with_launch = True):
        linux_headers = run([], "linux-headers", {})
        c = chain(
            platform,
            run,
            cc_args = cc_args,
            libc_recipe = "glibc",
            libc_args = {
                "linuxHeaders": linux_headers,
                # C.UTF-8 is compiled by running the fresh localedef
                "locale": platform.clangTarget == build_platform.clangTarget,
            },
            linux_headers = linux_headers,
        )
        c.update(
            glibc = c["libc"],
            linux_headers = linux_headers,
            launch = run([c["cc"]], "launch", {}) if with_launch else None,
            dlaudit = run([c["cc"]], "dlaudit", {}) if with_launch else None,
        )
        return c

    # no jig yet. Linux headers install with musl's own tools here, so they come after libc
    def stage0():
        platform = for_system(system, "musl")
        run = mk_stage(platform, suffix = "")
        headers = []

        def extra(compiler_rt, libc):
            headers.append(run([], "linux-headers", {
                "sysroot": run([], "sysroot", {"parts": [libc], "resource": compiler_rt}),
            }))
            return headers

        c = chain(platform, run, libc_recipe = "musl", extra_parts = extra, with_cc = False)
        jig = run([], "jig", {"sysroot": c["sysroot"]})
        c.update(
            jig = jig,
            linux_headers = headers[0],
            musl = c["libc"],
            cc = run([jig], "cc", {"sysroot": c["sysroot"], "prebuilt": jig}),
        )
        return struct(**c)

    def stage1(stage0):
        run = mk_stage(build_platform, tools = [stage0.jig, stage0.cc], suffix = "-boot")
        c = linux_chain(build_platform, run, {"prebuilt": stage0.jig}, with_launch = False)
        cmake = run([c["cc"]], "cmake", {"sysroot": c["sysroot"]})
        c.update(cmake = cmake, llvm = run([cmake, c["cc"]], "llvm", {"sysroot": c["sysroot"]}))
        return struct(**c)

    # stage2. stage1's cc stays on PATH as the host compiler (HOSTCC, cc-build)
    def chain_for(platform, stage0, stage1, sdk, native_cc):
        run = mk_stage(platform, clang = stage1.llvm, tools = [stage0.jig, stage1.llvm, stage1.cc])
        cc_args = {"prebuilt": stage0.jig}
        if platform != build_platform:
            cc_args["native"] = native_cc()

        def with_launch(c):
            c["launch"] = run([c["cc"]], "launch", {})
            return c

        if platform.libc == "glibc":
            c = linux_chain(platform, run, cc_args)
        elif platform.libc == "msvc":
            vcruntime = run([], "vcruntime", {"sdk": sdk})
            c = with_launch(chain(platform, run, cc_args = cc_args, libc_given = sdk, extra_parts = lambda _c, _l: [vcruntime]))
        elif platform.libc == "apple":
            c = chain(platform, run, cc_args = cc_args, libc_given = run([], "apple-sdk", {}))
        else:
            c = with_launch(chain(platform, run, cc_args = cc_args, libc_recipe = "mingw-w64"))
        return struct(**c)

    return struct(stage0 = stage0, stage1 = stage1, chain_for = chain_for, build_platform = build_platform)
