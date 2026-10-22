# Environments and applications on top of the interpreter, from a uv.lock:
#   env(c, python, src | lock, …)     an environment: every locked dependency plus bin/python3
#   project(c, python, src, …)        struct(package = the application, devEnv = an env whose
#                                     python also imports the checkout named by $REPKGS_PROJECT)
# Both are pyapp packages around fetch.pythonDeps, made with the calling package.star's `c`.
# Paths are `//`-relative (they are read here, not next to the caller). Example:
# tests/builder/pyproject.

load("//nix/lib.star", "base_name", "dir_name")

_SKIP = [".git", ".venv", "result", "__pycache__", ".direnv"]

def _norm(s):
    return s.replace("_", "-").replace(".", "-")

def _git_sources(lock):
    """uv.lock's git sources: url?rev#sha and no content hash. Nix fetched these with
    builtins.fetchGit, which dv does not have."""
    for p in lock.get("package", []):
        if "git" in p.get("source", {}):
            fail("%s: git sources in uv.lock are not supported" % p["name"])
    return []

def _mk(
        c,
        python,
        mode,
        src,  # the project (its pyproject.toml names it); with `lock`, only used for the name
        lock = None,  # a uv.lock elsewhere than src/uv.lock
        name = None,
        extras = [],
        groups = [],  # PEP 735 dependency groups, env and dev only
        prefer = "wheel",  # or "sdist", for every package the lock has both for
        # per locked package, by PyPI name: { prefer, sys, tools, patches, env, run (nu, in its
        # unpacked source), configSettings }
        overrides = {},
        sys = [],  # extra C libraries by package name, on top of sys-libs.json
        tools = [],  # extra build tools by package name
        check = [],  # modules that must import from the result
        env = {},
        environ = {}):  # PEP 508 marker overrides, e.g. {"platform_release": "6.6"}
    # per PyPI name: C libraries to link, build tools, config settings (builder/sys-libs.nu)
    table = json.decode(read_file("//builder/sys-libs.json"))["python"]
    pp = src + "/pyproject.toml"
    if name != None:
        pname = name
    elif path_exists(pp):
        pname = _norm(from_toml(read_file(pp))["project"]["name"])
    else:
        pname = base_name(src)
    source = path(src, name = pname + "-src", filter = lambda p, _t: base_name(p) not in _SKIP)
    lock_data = from_toml(read_file(src + "/uv.lock" if lock == None else lock))
    root = source if lock == None else path(dir_name(lock), name = pname + "-lock")
    ov_names = sorted(overrides)

    def ov(n, k, d):
        return overrides.get(n, {}).get(k, d)

    locked = [p["name"] for p in lock_data.get("package", []) if p["name"] in table]

    def from_table(k):
        return [x for n in locked for x in table[n].get(k, [])]

    table_sys = [table[n]["pkg"] for n in locked if "pkg" in table[n] and c.has_pkg(table[n]["pkg"])]
    tool_names = tools + [n for n in from_table("tools") if c.has_pkg(n)] + [t for n in ov_names for t in ov(n, "tools", [])]
    return c.package(
        name = pname if mode == "project" else pname + "-" + mode,
        source = source,
        version = "0",
        uses = ["pyapp"],
        pyapp = {
            "mode": mode,
            "check": check,
            "deps": c.fetch.pythonDeps(
                python = python,
                extras = extras,
                prefer = prefer,
                source = root,
                groups = [] if mode == "project" else groups,
                sdist = [n for n in ov_names if ov(n, "prefer", prefer) == "sdist"],
                git = _git_sources(lock_data),
                environ = to_json(environ),
            ),
            "overrides": {
                n: {
                    "env": o.get("env", {}),
                    "patches": ["%s" % p for p in o.get("patches", [])],
                    "run": o.get("run", ""),
                    "configSettings": o.get("configSettings", {}),
                }
                for n, o in overrides.items()
            },
        },
        sys = sys + table_sys + [s for n in ov_names for s in ov(n, "sys", [])],
        buildDependencies = [c.buildPkgs[n] for n in tool_names],
        dependencies = [python, c.pkgs["libgcc-shim"]],
        env = env,
        tests = {"version": False},
        exports = False,
    )

def env(c, python, **args):
    if "src" not in args:
        args["src"] = dir_name(args["lock"])
    return _mk(c, python, "env", **args)

def project(c, python, **args):
    return struct(package = _mk(c, python, "project", **args), devEnv = _mk(c, python, "dev", **args))
