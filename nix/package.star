# The `package` function: spec -> derivation (+ `.tests` when tests.separate).
# Validates field and option names at eval time, then generates the nu script
#   use core.nu *; use prepare.nu; use finish.nu; use implant.nu; use <bs>.nu …; prepare; <bs> setup …; <phase> …; finish
# that nu executes in a single nu process. Vocabulary: README.md "Writing a package".

load("//nix/build_systems.star", "SYSTEMS", bs_defaults = "defaults", bs_dependencies = "dependencies", bs_tools = "tools", bs_unsupported = "unsupported")
load("//nix/features.star", features_ = "bad")
load("//nix/lib.star", "base_name", "lines", "to_string", "without")

RESERVED = [
    "name",
    "features",
    "platforms",
    "version",
    "source",
    "patches",
    "uses",
    "phases",
    "buildDependencies",
    "dependencies",
    "sys",
    "bin",
    "tests",
    "exports",
    "env",
    "root",
    "cc",
    "bootstrapTools",
    "prebuilt",
    "debug",
    "install",
    "links",
    "completions",
]

# `completions.<shell> = [ files ]`, sugar for `install`: each file goes where that shell looks.
# bash and zsh find completions by command name (`<cmd>`, `_<cmd>`), fish and nu keep the file
# name. A path beside package.star arrives with a store hash prefix, dropped here
COMPLETION_DIRS = {
    "bash": "share/bash-completion/completions",
    "zsh": "share/zsh/site-functions",
    "fish": "share/fish/vendor_completions.d",
    "nu": "share/nushell/vendor/autoload",
}

_SUB_FIELDS = {
    "tests": ["run", "separate", "parallel", "version", "dlopen", "dependencies"],
    "cc": ["cflags", "cxxflags", "ldflags", "hardening"],
    "completions": sorted(COMPLETION_DIRS),
}

_LOWER = "abcdefghijklmnopqrstuvwxyz"
_LETTERS = _LOWER + _LOWER.upper()

def _phase_name(s):
    """"cmake.install" as ("cmake", "install"): a lowercase name (letters, digits), a dot, a
    verb (letters, dashes). None for anything else."""
    m, dot, v = s.partition(".")
    if not dot or not m or not v:
        return None
    if m[0] not in _LOWER or m.lstrip(_LOWER + "0123456789") != "":
        return None
    if v[0] not in _LETTERS or v.lstrip(_LETTERS + "-") != "":
        return None
    return m, v

def set_common(platform, toolchain, launch, dlaudit, nu):
    """The part of every derivation that is the same across the set: built once."""
    elf = platform.binfmt == "elf"
    tc = to_string(toolchain)
    sysroot = to_string(toolchain.sysroot)
    p = {k: getattr(platform, k) for k in [
        "name",
        "cpu",
        "os",
        "binfmt",
        "names",
        "osNames",
        "clangTarget",
        "gnuTriple",
        "rustTriple",
        "opensslTarget",
        "buildRustTriple",
        "cross",
        "emulator",
        "abi",
        "libc",
        "posix",
        "ext",
        "hardening",
    ]}
    p.update(
        sysroot = toolchain.sysroot,
        probe = sysroot + "/lib/" + platform.interp if platform.cross else "",
        # `prebuilt`: upstream ELFs get our dynamic linker implanted (true) or via launch ("ldso")
        interp = sysroot + "/lib/" + platform.interp,
        launch = to_string(launch) + "/bin/launch" if elf else (to_string(launch) + "/bin/launch.exe" if platform.os == "windows" else ""),
        # finish.nu runs the version check under it: a failed dlopen fails the build
        dlaudit = to_string(dlaudit) + "/lib/dlaudit.so" if elf else "",
        relocStub = tc + "/lib/reloc_stub.bin",
    )
    return {
        "system": platform.system,
        "__structuredAttrs": True,
        # content-addressed: rebuilds that change no bytes do not propagate
        "__contentAddressed": True,
        "outputHashMode": "recursive",
        "outputHashAlgo": "sha256",
        "builder": to_string(nu) + "/bin/nu",
        # platform facts autoconf would otherwise probe (or guess, when cross): nix/config.site
        "CONFIG_SITE": path("//nix/config.site"),
        "platform": p,
    }

def _completion_name(shell, f):
    # a file beside package.star arrives as <32-char store hash>-<name>
    name = base_name(f)
    if name[32:33] == "-" and name[:32].lstrip(_LOWER + "0123456789") == "":
        name = name[33:]
    stem = name.removesuffix("." + shell)
    if shell == "bash":
        return stem
    if shell == "zsh":
        return stem if stem.startswith("_") else "_" + stem
    return name

def _completions_install(shells):
    out = {}
    for shell in sorted(shells):
        for f in shells[shell]:
            out[COMPLETION_DIRS[shell] + "/" + _completion_name(shell, f)] = f
    return out

def _get(d, *keys, default = None):
    """`d.a.b or default` over dicts."""
    for k in keys:
        if type(d) != "dict" or k not in d:
            return default
        d = d[k]
    return d

def _sub_keys(prefix, s):
    if type(s) != "dict":
        return []
    out = []
    for k in sorted(s):
        p = prefix + "." + k
        if k not in _SUB_FIELDS[prefix]:
            out.append(p)
        elif p in _SUB_FIELDS:
            out += _sub_keys(p, s[k])
    return out

def _as_list(x):
    return x if type(x) == "list" else [x]

def _fail(name, msg):
    fail(name + ": " + msg)

# an edit gated off with `on(cond, [ … ])` names a phase of the other platform's build system
def _non_empty(s):
    return [n for n in sorted(s) if s[n] != []]

def _stack_before(S, name, stack):
    """A build system's `stack` (tools that are themselves built with it): a member sees only
    the members before it, everyone else sees all of it."""
    out = []
    for n in stack:
        if n == name:
            break
        out.append(S.buildPkgs[n])
    return out

def _phase(s, name, uses, workdir, bs_phases):
    """A phase as { test, body }: inline ones and package-module ones built here, a build
    system's come ready. An inline phase's env changes carry over to later phases, its cwd
    does not."""
    if type(s) == "dict":
        return struct(
            test = s["name"] == "test",
            body = "note phase %s\nlet pwd = $env.PWD\ndo --env {\ncd (%s)\nlet c = (ctx)\n%s\n}\ncd $pwd" % (s["name"], workdir, s["run"]),
        )
    if s in bs_phases:
        return bs_phases[s]
    p = _phase_name(s)
    if p == None:
        _fail(name, "phase '%s' is not <build system or module>.<phase>" % s)
    if p[0] in uses:
        return struct(test = False, body = "note phase %s\ndo {\ncd (%s workdir)\n%s %s\n}" % (s, p[0], p[0], p[1]))
    return struct(test = p[1] == "test", body = "note phase %s\n%s %s" % (s, p[0], p[1]))

def _phase_line(p, tests_run, separate):
    """Phase `p` in the build script: test phases drop out when disabled or separate, and
    otherwise ask prepare (cross without binfmt decides at build time that tests cannot run)."""
    if not p.test:
        return p.body
    if not tests_run or separate:
        return ""
    return "if (ctx).testsRun {\n%s\n}" % p.body

def _store_module(dir, m):
    """<store dir>/<m>.nu: nu names a module after its file, a bare store path would be <hash>-<m>."""
    return path(dir, name = "module", filter = lambda p, _t: base_name(p) == m + ".nu") + "/" + m + ".nu"

def _build_deps(S, args, name, uses, spec, prebuilt, tests, base):
    """PATH order: the base tools (GNU userland, then the seed) go last and only once, so a
    build system that lists the seed as its `sh` does not pull toybox ahead of coreutils and grep."""
    ds = (
        [S.toolchain] +
        args.get("buildDependencies", []) +
        tests +
        (S.reloc_tools if prebuilt == True else []) +
        [d for u in uses for d in bs_tools(S, u, spec) + _stack_before(S, name, SYSTEMS[u].stack)]
    )
    return [d for d in ds if d not in base] + base

def make_package(S, sources0, dir, features, fn, args0, tests_mode = False):
    """One package. `S`: the set (nix/set.star). `sources0`: the package's sources.toml (a
    struct from read_sources) or None; it supplies version and source unless the spec sets them.
    `dir`: the package's directory, where a phase prefix that is no build system finds
    <prefix>.nu. `fn`: the package.star it came from, for `variant`. `tests_mode`: the `.tests`
    derivation instead of the package."""
    platform = S.platform
    bss = SYSTEMS
    edited = args0 if S.edit == None else S.edit(args0["name"], args0)

    # an override may repin the package: `pin.merge = {"version": "…"}` plus
    # `hash.merge = {"default": "sha256-…"}` re-read sources.toml under the new [pin]
    repinned = S.edit != None and sources0 != None and ("pin" in edited or "hash" in edited)
    sources = sources0.repin(edited.get("pin", {}), edited.get("hash", {})) if repinned else sources0

    args = {}
    if sources != None:
        # one tarball for all, or one per platform ("x86_64-linux", "aarch64-macos")
        args["version"] = sources.version
        args["source"] = "default" if sources.has("default") else platform.cpu + "-" + platform.os
    args.update(without(edited, ["pin", "hash"]) if repinned else edited)
    if "completions" in edited:
        inst = _completions_install(edited["completions"])
        inst.update(edited.get("install", {}))
        args["install"] = inst

    name = args["name"]
    uses = args.get("uses", [])

    unknown_uses = [u for u in uses if u not in bss]

    # `<bs> = on(cond, {…})` for a build system used on some platforms only leaves {} on the others
    unknown_fields = [k for k in sorted(args) if k not in RESERVED and k not in uses and args[k] != {}]
    for f in ("tests", "cc", "completions"):
        if f in args:
            unknown_fields += _sub_keys(f, args[f])

    # a library among the build tools or a tool among the libraries: natively both platforms
    # coincide and nothing would notice, so it is checked here
    wrong_platform = [
        "dependencies: %s is built for %s" % (d.pname, d.platform)
        for d in args.get("dependencies", [])
        if getattr(d, "platform", platform.name) != platform.name
    ] + [
        "buildDependencies: %s is built for %s" % (d.pname, d.platform)
        for d in args.get("buildDependencies", [])
        if getattr(d, "platform", platform.system) != platform.system
    ]

    platforms = args.get("platforms", {})
    unknown_platform_keys = [k for k in sorted(platforms) if k not in ("cpu", "os", "abi", "libc", "posix", "cross")]

    # the declaration's shape. Values from outside are checked where they are resolved (nix/features.star)
    bad_features = features_(args["features"]) if "features" in args else []
    if bad_features:
        _fail(name, "features %s: want { default (bool, string, list or int), values? (a list the default is from), doc? }" % " ".join(bad_features))
    if unknown_uses:
        _fail(name, "unknown build systems %s (have: %s)" % (" ".join(unknown_uses), " ".join(sorted(bss))))
    if unknown_fields or unknown_platform_keys:
        _fail(name, "unknown fields " + " ".join(unknown_fields + ["platforms." + k for k in unknown_platform_keys]))
    if wrong_platform:
        _fail(name, "; ".join(wrong_platform))

    # `install`/`links` alone (prebuilt binaries, data): the one phase is copying them into $out.
    # `phases` is the whole list, or edits to the first build system's list (README):
    # { before.<phase> = [..]; after.<phase> = [..]; replace.<phase> = phase | [..]; remove = [..]; }
    given_phases = args.get("phases", [])
    if given_phases == []:
        if len(uses) == 1:
            phases = bss[uses[0]].phases
        elif uses == [] and ("install" in args or "links" in args):
            phases = []
        else:
            _fail(name, "'phases' is required with more than one build system (a list, or edits to the first one's)")
    elif type(given_phases) == "list":
        phases = given_phases
    else:
        e = given_phases
        known = bss[uses[0]].phases

        named = _non_empty(e.get("before", {})) + _non_empty(e.get("after", {})) + sorted(e.get("replace", {})) + e.get("remove", [])
        unknown = [n for n in named if n not in known]
        bad = [n for n in sorted(e) if n not in ("before", "after", "replace", "remove")]
        if bad:
            _fail(name, "phases: unknown edit %s (before, after, replace, remove)" % bad[0])
        if unknown:
            _fail(name, "phases: %s is not a phase of %s (%s)" % (unknown[0], uses[0], " ".join(known)))
        phases = []
        for p in known:
            if p in e.get("remove", []):
                continue
            phases += _as_list(e.get("before", {}).get(p, [])) + _as_list(e.get("replace", {}).get(p, p)) + _as_list(e.get("after", {}).get(p, []))

    # `supported` without the derivation (docs/design.md): platforms.{cpu,os,abi,libc,posix,cross},
    # a per-cpu tarball in sources.toml, and the dependencies' own verdicts
    bad_cpu = "cpu" in platforms and platform.cpu not in platforms["cpu"]
    bad_os = "os" in platforms and platform.os not in platforms["os"]
    bad_abi = "abi" in platforms and platform.abi not in platforms["abi"]
    bad_libc = "libc" in platforms and platform.libc not in platforms["libc"]
    needs_posix = platforms.get("posix", False) and not platform.posix
    native_only = platforms.get("cross", True) == False and platform.cross
    bs_reasons = [r for r in [bs_unsupported(u, platform) for u in uses] if r != None]

    # `source` as a plain string names a sources.toml key; a cpu the file has no tarball for is
    # unsupported. Paths and derivations are the source itself
    s = args.get("source")
    source_key = s if type(s) == "string" and not s.startswith("/") else None
    no_tarball = source_key != None and not sources.has(source_key)

    reason = None
    if bad_cpu:
        reason = "%s: not for %s (platforms.cpu)" % (name, platform.cpu)
    elif bad_os:
        reason = "%s: not for %s (platforms.os)" % (name, platform.os)
    elif bad_abi:
        reason = "%s: not for the %s ABI (platforms.abi)" % (name, platform.abi)
    elif bad_libc:
        reason = "%s: not on %s (platforms.libc)" % (name, platform.libc)
    elif needs_posix:
        reason = "%s: needs a POSIX system (platforms.posix)" % name
    elif native_only:
        reason = "%s: runs its own binaries while installing, cannot be cross-built (platforms.cross)" % name
    elif bs_reasons:
        reason = "%s: %s" % (name, bs_reasons[0])
    elif no_tarball:
        reason = "%s: sources.toml has no '%s' source" % (name, source_key)

    # an unsupported package still has its source (cpython's msvc build compiles bzip2's in)
    src = None
    if not no_tarball:
        src = sources.fetch(source_key) if source_key != None else s

    tests = args.get("tests", {})
    tests_run = tests.get("run", True)

    # tests.separate: the build derivation skips *.test and keeps its tree in output `tree`;
    # `<pkg>.tests` restores it and runs only the test phases: a test failure fails that
    # derivation, not the package, and a retry does not rebuild
    separate = tests.get("separate", False)

    # tools only the suite runs. With tests.separate they stay off the build derivation, which is
    # how the base tools test with perl (built with them) without a cycle
    test_deps = tests.get("dependencies", []) if tests_run else []

    # an upstream-binary package says `prebuilt`, or one of its build systems does (pyapp: wheels)
    prebuilt = args.get("prebuilt", any([bss[u].prebuilt == True for u in uses]))

    # DWARF goes to the `debug` output (finish.nu). false when the build cannot be made to keep it
    debug = args.get("debug", prebuilt == False)

    # [pin] sys of sources.toml. None: no sources.toml, dependencies are all by hand
    sys = args.get("sys", None if sources == None else sources.sys)

    spec = without(args, ["source", "patches", "buildDependencies", "dependencies", "bootstrapTools"])
    if "tests" in args:
        spec["tests"] = without(args["tests"], ["dependencies"])
    for u in uses:
        given = args.get(u, {})
        rec = bs_defaults(S, u, src, given)
        rec.update(given)
        spec[u] = rec
    spec.update(phases = phases, prebuilt = prebuilt, debug = debug, sys = sys)

    # resolved values, for phases: `(ctx).spec.features.tls`
    if features:
        spec["features"] = features

    # [pin] sys: libraries the lock files can link (builder/sys-libs.nu). Those the set lacks
    # here are left to the locked package (vendored copy or feature off)
    dependencies = (
        args.get("dependencies", []) +
        [S.pkgs[n] for n in (sys or []) if S.has_pkg(n) and getattr(S.pkgs[n], "supported", False)] +
        [d for u in uses for d in bs_dependencies(S, u)]
    )

    if reason == None:
        bad_deps = [
            d
            for d in dependencies + args.get("buildDependencies", []) + [t for u in uses for t in bs_tools(S, u, spec)]
            if not getattr(d, "supported", True)
        ]
        if bad_deps:
            reason = "%s -> %s" % (name, bad_deps[0].unsupportedReason)

    # what the package is besides its derivation: for `variant`, lints, `pkgs.x.supported`
    attrs = dict(
        pname = name,
        platform = platform.name,
        dir = dir,
        fn = fn,
        sources = sources0.file if sources0 != None else None,
        features = features,
        supported = reason == None,
        unsupportedReason = reason,
        version = args.get("version"),
        src = src,
    )
    if reason != None:
        if tests_mode:
            fail(reason)
        return poison(reason, **attrs)

    tree = S.tree

    # same flags as treefmt's nu-typecheck, so what lints clean parses the same way here
    # include path: a package's own module says `use core.nu *` wherever it lives
    nu_args = ["--no-config-file", "--include-path=" + tree, "--experimental-options=[cell-path-types]", "-c"]

    # every phase starts in a known directory: `<bs> workdir` for a build system's phases, the
    # first build system's for inline phases and package modules. setup exports env, hence --env
    workdir = "(ctx).src" if uses == [] else uses[0] + " workdir"

    # "<bs>.<verb>" -> { test, body } for the build systems in use, ready made in build_systems.star
    bs_phases = {}
    for u in uses:
        bs_phases.update(bss[u].phase)

    # a phase "zig.restore" whose prefix is no `uses` entry is the package's own module zig.nu
    # next to package.star, for phases too long to read inline. It imports the builder by bare name
    modules = []
    if "phases" in args:
        for s in phases:
            p = None if type(s) == "dict" else _phase_name(s)
            m = p[0] if p != None else None
            if m != None and m not in uses and m not in modules:
                modules.append(m)

    prelude = (
        ["use %s/core.nu *\nuse %s/prepare.nu\nuse %s/finish.nu\nuse %s/implant.nu" % (tree, tree, tree, tree)] +
        ["use %s/%s" % (tree, bss[u].module) for u in uses] +
        ["use " + _store_module(dir, m) for m in modules]
    )

    # each build system's OPTIONS table for prepare.nu to merge the spec over
    systems_arg = "{%s}" % ", ".join(["%s: $%s.OPTIONS" % (u, u) for u in uses])
    setups = [bss[u].setup for u in uses]

    common = dict(S.common)
    common.update(
        src = src,
        version = args["version"],
        patches = args.get("patches", []),
        spec = spec,
        buildDependencies = _build_deps(S, args, name, uses, spec, prebuilt,
            tests = [] if separate else test_deps,
            base = S.base_tools.bootstrap if args.get("bootstrapTools", False) else S.base_tools.full,
        ),
        dependencies = dependencies,
    )

    if tests_mode:
        if not separate:
            _fail(name, "has no separate tests (tests.separate)")
        drv = S.pkgs[name]
        test_script = lines(
            prelude +
            ["prepare %s --from-tree %s" % (systems_arg, drv.tree)] +
            setups +
            [p.body for p in [_phase(s, name, uses, workdir, bs_phases) for s in phases] if p.test] +
            ["finish tests"],
        )
        common.update(
            name = drv.name + "-tests",
            outputs = ["out"],
            buildDependencies = _build_deps(S, args, name, uses, spec, prebuilt, tests = test_deps, base = S.base_tools.full),
            package = drv.out,
            args = nu_args + [test_script],
        )
        return derivation(**common)

    # also `pkg.script`: lints/package-scripts.nu has nu parse it before anything builds
    script = lines(
        prelude +
        ["prepare " + systems_arg] +
        setups +
        [_phase_line(_phase(s, name, uses, workdir, bs_phases), tests_run, separate) for s in phases] +
        ["finish --keep-tree" if separate else "finish"],
    )
    common.update(
        name = name + "-" + platform.name if platform.cross else name,
        outputs = ["out", "debug"] + (["tree"] if separate else []),
        args = nu_args + [script],
    )
    drv = derivation(**common)
    attrs["script"] = script
    if separate:
        attrs["tests"] = S.tests_of(name)
    return with_attrs(drv, **attrs)
