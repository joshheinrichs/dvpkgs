# The package set for one platform. `package_set(...)` is a lazy set: `pkgs.zlib` is evaluated
# when first used, once, and cached across runs with what it read (docs in dv). Every directory
# pkgs/<first two letters>/<name>/ with a package.star becomes attribute <name>:
#
#   def package(c):
#       return c.package(name = "<name>", …, dependencies = [c.pkgs.zlib])
#
# `c` has package variant pkgs buildPkgs platform fetch sources toolchain lib on features has_pkg.
# Attribute names with a dash are read with `c.pkgs["cmake-bootstrap"]`.

load("//bootstrap/default.star", "bootstrap")
load("//nix/features.star", resolve_features = "resolve")
load("//nix/fetch.star", "make_fetch", "producers")
load("//nix/lib.star", "join", "lines", "merge", "on", "per", "to_string", "text")
load("//nix/overrides.star", ov_apply = "apply", ov_apply_one = "apply_one", ov_merge = "merge", ov_unknown = "unknown")
load("//nix/package.star", "make_package", "set_common")
load("//nix/platforms.star", "BY_NAME", "for_system")
load("//nix/sources.star", "read_sources")

def _args(system, platform, seed, overrides, packages, features):
    return {
        "system": system,
        "platform": platform or system,
        "seed": seed,
        # one tree or a list of them: {"zlib": {"autotools": {"flags": {"append": [ … ]}}}} (nix/overrides.star)
        "overrides": ov_merge(overrides),
        # out-of-tree packages: name -> directory with package.star (+ sources.toml), called like
        # in-tree ones. A name that exists in the tree is replaced
        "packages": packages,
        # set-wide feature values, for every package that declares the name (nix/features.star)
        "features": features,
    }

def pkg_dir(name):
    return "//pkgs/" + name[:2] + "/" + name

def package_names(packages = {}):
    """Every attribute of the set: package directories, `packages`, aliases."""
    names = {}
    for shard in read_dir("//pkgs"):
        if shard == "aliases.toml":
            continue
        for n in read_dir("//pkgs/" + shard):
            if path_exists("//pkgs/%s/%s/package.star" % (shard, n)):
                names[n] = True
    for n in packages:
        names[n] = True
    for n in from_toml(read_file("//pkgs/aliases.toml")):
        names[n] = True
    return sorted(names)

def package_set(system = None, platform = None, seed = None, overrides = {}, packages = {}, features = {}, listed = False):
    """The set for `platform` (default: `system`, default: this machine's). `listed`: with its
    names, for `dir(pkgs)` and `"x" in pkgs`, which costs a look at every package directory on
    each run."""
    args = _args(system or current_system(), platform, seed, overrides, packages, features)
    return lazy_attrs(call, args, names = package_names(packages) if listed else None)

def call(name, args):
    return _call(name, args, False)

def call_tests(name, args):
    return _call(name, args, True)

# ---- set-wide values, computed once per set and cached --------------------------------------

def shared_attr(what, args):
    sh = lazy_attrs(shared_attr, args)
    system = args["system"]
    target = BY_NAME.get(args["platform"]) or fail("no platform " + args["platform"])
    if what == "stage":
        sdk = None
        if target.libc == "msvc":
            b = bootstrap(system, args["seed"])
            build = _build_pkgs(args)
            sdk = make_fetch(b.stage0.jig, b.seed, system, target.cpu, sh.producers, sevenzip = build["7zip"]).windowsSdk(
                manifest = read_sources(pkg_dir("windows-sdk") + "/sources.toml", b.seed, system).fetch("default"),
                arch = target.cpu,
            )
        return getattr(bootstrap(system, args["seed"], sdk), args["platform"])
    if what == "platform":
        p = sh.stage.platform
        fields = {k: getattr(p, k) for k in dir(p)}
        cross = args["platform"] != system
        os = target.os

        # its address cap is $QEMU_RESERVED_VA (builder/prepare.nu), build systems want one word here
        emulator = []
        if cross and os == "linux":
            emulator = ["%s/bin/qemu-%s" % (_build_pkgs(args).qemu, p.names.qemu)]
        elif cross and os == "windows" and target.cpu == "x86_64":
            emulator = ["%s/bin/wine" % _build_pkgs(args).wine]
        fields.update(
            system = system,
            cross = cross,
            buildRustTriple = for_system(system, "glibc").rustTriple,
            emulator = emulator,
        )
        return struct(**fields)
    if what == "common":
        stage = force(sh.stage)
        return set_common(sh.platform, stage.cc, getattr(stage, "launch", None), getattr(stage, "dlaudit", None), bootstrap(system, args["seed"]).seed)
    if what == "tree":
        # the builder modules every script imports
        return path("//builder", name = "build")
    if what == "producers":
        return producers()
    if what == "aliases":
        # unversioned names for the default line of multi-version packages (pkgs/aliases.toml)
        return from_toml(read_file("//pkgs/aliases.toml"))
    if what == "check":
        unknown = ov_unknown(partial(_has_pkg, args), args["overrides"])
        if unknown:
            fail("overrides: no packages named " + " ".join(unknown))
        return True
    if what == "context":
        return _context(args)
    fail("no shared value " + what)

def _build_pkgs(args):
    """The set whose programs run on the build machine: itself unless cross compiling."""
    if args["platform"] == args["system"]:
        return lazy_attrs(call, args)
    return lazy_attrs(call, _args(args["system"], args["system"], args["seed"], args["overrides"], args["packages"], {}))

def _has_pkg(args, n):
    if n in args["packages"] or path_exists(pkg_dir(n) + "/package.star"):
        return True
    return n in force(lazy_attrs(shared_attr, args).aliases)

# ---- one package --------------------------------------------------------------------------

def _edit(ov_ctx, tree, name, spec):
    return ov_apply(ov_ctx, tree, name, spec)

def _tests_of(args, name):
    return getattr(lazy_attrs(call_tests, args), name)

def _context(args):
    """What every package of the set is made with (nix/package.star's `S`) and what package.star
    files are handed (`c`, less sources, features and the package/variant functions). Data,
    made once per set (`shared_attr("context")`)."""
    sh = lazy_attrs(shared_attr, args)
    system = args["system"]
    pkgs = lazy_attrs(call, args)
    build_pkgs = _build_pkgs(args)
    b = bootstrap(system, args["seed"])
    seed = force(b.seed)
    stage = force(sh.stage)
    platform = force(sh.platform)

    fetch = make_fetch(b.stage0.jig, seed, system, platform.cpu, sh.producers, sevenzip = build_pkgs["7zip"])
    has_pkg = partial(_has_pkg, args)
    ov_ctx = struct(pkgs = pkgs, has_pkg = has_pkg)
    tree = args["overrides"]

    # On PATH after the toolchain and the build systems' tools. GNU userland precedes the seed
    # because build scripts in the wild need more than toybox. llvm brings the object tools, the
    # seed bsdtar, nu, sh. `bootstrap` is what the base userland itself is built with
    # (`bootstrapTools = True`).
    base_tools = struct(
        full = [build_pkgs[n] for n in ["coreutils", "sed", "grep", "gawk", "diffutils", "findutils", "patch", "gnumake", "bash", "pkgconf"]] + [b.stage1.llvm, seed],
        bootstrap = [b.stage1.llvm, seed],
    )
    S = struct(
        platform = platform,
        toolchain = stage.cc,
        # build systems that spawn `sh` by name get the seed's dash
        sh = seed,
        fetch = fetch,
        base_tools = base_tools,
        # `prebuilt = True` patches upstream ELFs with it (builder/implant.nu)
        reloc_tools = [build_pkgs.formatelf],
        common = force(sh.common),
        tree = force(sh.tree),
        edit = None if not tree else partial(_edit, ov_ctx, tree),
        pkgs = pkgs,
        buildPkgs = build_pkgs,
        has_pkg = has_pkg,
        tests_of = partial(_tests_of, args),
    )
    scope = dict(
        fetch = fetch,
        toolchain = stage.cc,
        buildPkgs = build_pkgs,
        platform = platform,
        pkgs = pkgs,
        lib = struct(on = on, per = per, join = join, lines = lines, text = text, to_string = to_string, merge = merge),
        on = on,
        # `n in pkgs`: lazy sets list no names inside a package
        has_pkg = has_pkg,
    )
    return struct(S = S, scope = scope, ov_ctx = ov_ctx, seed = seed)

def _call(name, args, tests_mode):
    sh = lazy_attrs(shared_attr, args)
    if not sh.check:
        fail("unreachable")
    if name in args["packages"]:
        dir = args["packages"][name]
    else:
        aliases = force(sh.aliases)
        if name in aliases:
            if path_exists(pkg_dir(name) + "/package.star"):
                fail("alias %s shadows a package directory" % name)
            target = getattr(lazy_attrs(call_tests if tests_mode else call, args), aliases[name])
            return force(target)
        dir = pkg_dir(name)
    if not path_exists(dir + "/package.star"):
        fail("no package named " + name)
    ctx = force(sh.context)
    st = dir + "/sources.toml"
    sources = read_sources(st, ctx.seed, args["system"]) if path_exists(st) else None
    return _call_with(ctx, tests_mode, args, dir + "/package.star", dir, name, sources, None)

def _call_with(ctx, tests_mode, args, fn, dir, name, sources, edit0):
    """One package.star (`fn`) evaluated under `name`: `edit0` is what `variant` adds on top of
    the spec (None for the package itself). `variant(pkgs.llvm, { … })` re-enters here with
    llvm's package.star, so the base body sees this name's sources and features."""
    mod = load_module(fn)
    local = args["overrides"].get(name, {}).get("features", {}) if type(args["overrides"].get(name)) == "dict" else {}

    # default <- set-wide <- overrides.<name>.features, for a package.star with FEATURES
    decl = getattr(mod, "FEATURES", {})
    features = resolve_features(name, decl, args["features"], local) if decl or local else {}

    def package(**spec):
        return make_package(ctx.S, sources, dir, features, fn, spec if edit0 == None else edit0(spec), tests_mode)

    # another package's spec under this name, edited with override verbs: its package.star with
    # this name. Own sources.toml when the directory has one (llvm22: another pin), else the
    # base's (rust-std: same tarball). A list of trees merges
    def variant(base, tree):
        base = force(base)
        base_sources = read_sources(base.sources, ctx.seed, args["system"]) if base.sources != None else None

        def edit(spec):
            spec = spec if edit0 == None else edit0(spec)
            spec = dict(spec, name = name)
            return ov_apply_one(ctx.ov_ctx, name, ov_merge(tree), spec)

        return _call_with(ctx, tests_mode, args, base.fn, base.dir, name, sources if sources != None else base_sources, edit)

    c = dict(ctx.scope)
    c.update(package = package, variant = variant, sources = sources, features = features)
    return mod.package(struct(**c))
