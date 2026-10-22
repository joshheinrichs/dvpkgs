# What `uses = ["<name>"]` means at eval time: builder/systems/<name>.nu implements the phases
# and declares the options (its OPTIONS, merged and checked by prepare.nu, read as `options
# <name>`). Here is only what forms derivation inputs: `phases`, the default order (build test
# install unless said otherwise), `tool` (swappable per package as `<name>.tool`) and `tools` on
# PATH, `dependencies` added to the package's, `deps` (source -> the fetched tree of locked
# dependencies, by default from the package's own lock file, a package overrides it as
# `<name>.deps`), `prebuilt` as the package's default for that field, and `unsupported`, a reason
# (or None) why no user of it can build on this platform. Every system also takes
# `<name>.root`, the directory below the source the project lives in. `sh` is for tools that
# spawn a shell by name (ninja, npm run, libtool). `stack`: names of tools that are themselves
# built with the system (a member sees only the members before it).
#
# The table is data, made once when this file loads: packages are named, "build:<name>" in the
# build machine's set, "host:<name>" in the package's own, "sh" the seed. What a package uses is
# resolved against its set by the functions below, for its build systems only.

_VERBS = ["configure", "build", "test", "install"]

# bin scripts say #!/usr/bin/env node, prebuilt .node addons (rollup, esbuild) link libgcc_s.so.1
_NODE_DEPS = ["host:nodejs", "host:libgcc-shim"]

# the same addons while building (builder/node-common.nu)
_NODE_TOOLS = ["build:libgcc-shim"]

_SPECS = {
    "make": dict(
        phases = ["configure", "build", "test", "install"],
        tools = ["sh"],
    ),
    "autotools": dict(
        phases = ["configure", "build", "test", "install"],
        # make and bash come with baseTools (or the seed's for bootstrapTools packages)
        tools = ["sh"],
    ),
    "cmake": dict(
        phases = ["configure", "build", "test", "install"],
        tool = "build:cmake",
        tools = ["build:ninja", "sh"],
    ),
    "vcxproj": dict(
        phases = ["configure", "build", "install"],
        tools = ["build:ninja"],
    ),
    "meson": dict(
        phases = ["configure", "build", "test", "install"],
        tool = "build:meson",
        tools = ["build:ninja", "sh"],
    ),
    "python": dict(
        phases = ["build", "install", "test"],  # tests import the installed module
        # the PEP 517 front end and its deps. Members of the stack itself get only what exists before them
        tool = "build:cpython",
        stack = ["python-flit-core", "python-packaging", "python-pyproject-hooks", "python-build", "python-installer"],
    ),
    "cargo": dict(
        # `cargo.tool = buildPkgs["rust-bootstrap"]` for what must exist before llvm and rust
        # are built (formatelf, git). Cross: std for the target is its own package, <tool>-std
        tool = "build:rust",
        deps = "cargoVendor",
    ),
    "cabal": dict(
        # `cabal.tool = buildPkgs["cabal-bootstrap"]` for cabal itself
        tool = "build:cabal",
        tools = ["build:ghc-bootstrap", "build:jsem"],
        dependencies = [
            "host:gmp",  # ghc-bignum: every linked program wants -lgmp
            "host:libffi",  # and the RTS -lffi
        ],
        # the shared set from locks/hackage.toml
        deps = "hackageSet",
    ),
    "luarocks": dict(
        phases = ["install"],  # luarocks make builds into --tree
        tool = "build:luarocks",
        tools = ["sh"],
        # the shared set from locks/luarocks.toml
        deps = "luaRocksSet",
    ),
    "go": dict(
        tool = "build:go",
        deps = "goModules",
    ),
    "pnpm": dict(
        tool = "build:pnpm",
        tools = ["build:nodejs", "sh"] + _NODE_TOOLS,
        deps = "pnpmDeps",
        dependencies = _NODE_DEPS,
    ),
    "pyapp": dict(
        # binary wheels carry upstream-linked .so files: finish implants interp/RUNPATH like for
        # any prebuilt package
        prebuilt = True,
        deps = "pythonDeps",
        # uv.lock does not lock build backends: every one the set has
        tools = ["build:" + n for n in [
            "cpython",
            "python-build",
            "python-installer",
            "python-pyproject-hooks",
            "python-packaging",
            "python-flit-core",
            "python-setuptools",
            "python-setuptools-scm",
            "python-hatchling",
            "python-hatch-vcs",
            "python-cython",
            "maturin",
            "rust",
        ]],
    ),
    "bundler": dict(
        tool = "build:ruby",
        tools = ["sh"],
        deps = "gems",
    ),
    "deno": dict(
        tool = "build:deno",
        deps = "denoDeps",
    ),
    "bun": dict(
        tool = "build:bun",
        tools = ["sh"] + _NODE_TOOLS,
        deps = "bunDeps",
        dependencies = _NODE_DEPS,
    ),
    "yarn": dict(
        tool = "build:yarn",
        tools = ["build:nodejs", "sh"] + _NODE_TOOLS,
        deps = "yarnDeps",
        dependencies = _NODE_DEPS,
    ),
    "mix": dict(
        # no test phase by default: MIX_ENV=test deps are outside the prod lock subset
        phases = ["build", "install"],
        tool = "build:elixir",
        tools = ["build:erlang", "build:hex", "build:rebar3"],
        deps = "hexDeps",
        dependencies = ["host:erlang"],  # escripts say #!/usr/bin/env escript, releases exec erl
    ),
    "rebar3": dict(
        # no test phase by default: eunit/ct deps live in the test profile, outside rebar.lock
        phases = ["build", "install"],
        tools = ["build:rebar3", "build:erlang"],
        deps = "hexDeps",
        dependencies = ["host:erlang"],
    ),
    "npm": dict(
        tool = "build:nodejs",
        tools = ["sh"] + _NODE_TOOLS,
        deps = "npmDeps",
        dependencies = _NODE_DEPS,
    ),
}

def _system(name, bs):
    phases = bs.get("phases", ["build", "test", "install"])
    return struct(
        module = "systems/" + name + ".nu",
        phases = [name + "." + v for v in phases],
        # script text nix/package.star would otherwise assemble per package: the setup block
        # and, for any "<name>.<verb>" a package may list, its body and whether it is a test phase
        setup = "note setup %s\ndo --env {\nmkdir (%s workdir)\ncd (%s workdir)\n%s setup\n}" % (name, name, name, name),
        phase = {
            name + "." + v: struct(
                test = v == "test",
                body = "note phase %s.%s\ndo {\ncd (%s workdir)\n%s %s\n}" % (name, v, name, name, v),
            )
            for v in _VERBS
        },
        tool = bs.get("tool"),
        tools = bs.get("tools", []),
        deps = bs.get("deps"),
        dependencies = bs.get("dependencies", []),
        prebuilt = bs.get("prebuilt", False),
        stack = bs.get("stack", []),
    )

# name -> struct(module, phases, setup, phase, tool, tools, deps, dependencies, prebuilt, stack)
SYSTEMS = {n: _system(n, _SPECS[n]) for n in sorted(_SPECS)}

def resolve(S, ref):
    """A package named in the table, in the set `S` (nix/set.star) it is for."""
    if ref == "sh":
        return S.sh
    kind, _, name = ref.partition(":")
    return S.buildPkgs[name] if kind == "build" else S.pkgs[name]

def unsupported(name, platform):
    """Why no package can use build system `name` on `platform`, or None."""
    if name == "autotools" and platform.libc == "msvc":
        return "configure and libtool do not know the MSVC ABI, config.sub rejects the triple"
    if name == "vcxproj" and platform.libc != "msvc":
        return "Visual Studio projects describe an MSVC-ABI build"
    if name == "cabal" and platform.cross:
        return "ghc-bootstrap only targets the build machine"
    return None

def defaults(S, name, source, given):
    """What the package's `<name>` record starts from: root, tool, deps. `given`: the package's
    own record, whose `deps` is not computed again."""
    bs = SYSTEMS[name]
    d = {"root": "."}
    if bs.tool != None:
        d["tool"] = resolve(S, bs.tool)
    if bs.deps != None and "deps" not in given:
        f = getattr(S.fetch, bs.deps)
        if bs.deps == "hackageSet":
            d["deps"] = f()
        elif bs.deps == "luaRocksSet":
            d["deps"] = f(lua = S.buildPkgs.lua)
        elif bs.deps == "pythonDeps":
            d["deps"] = f(source = source, python = S.pkgs.cpython)
        else:
            d["deps"] = f(source = source)
    return d

def tools(S, name, spec):
    """On PATH while building with `name`: its tool as the package's spec has it, and the rest."""
    bs = SYSTEMS[name]
    out = [spec[name]["tool"]] if bs.tool != None else []
    out += [resolve(S, t) for t in bs.tools]
    if S.platform.cross:
        if name == "cargo":
            out.append(S.pkgs[force(spec["cargo"]["tool"]).pname + "-std"])
        elif name == "pyapp":
            out.append(S.pkgs["rust-std"])
    return out

def dependencies(S, name):
    return [resolve(S, d) for d in SYSTEMS[name].dependencies]
