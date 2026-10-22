# Reads a sources.toml (docs/uptrack.md). URL templates expand like pkgs/up/uptrack/src/pipeline.nu
# `expand`. `unpacker`: store path with bin/{nu,bsdtar} (the seed; nu's `http get` does the
# download). Only the seed's own sources.toml (a .nar) is read without one.

load("//nix/lib.star", "base_name", "to_string")
load("//nix/mirrors.star", "MIRRORS")

def fetchurl(url, hash, name = None, unpack = False, executable = False):
    """Nix's <nix/fetchurl.nix> for an SRI `hash`: builtin:fetchurl."""
    return derivation(
        builder = "builtin:fetchurl",
        outputHashMode = "recursive" if unpack or executable else "flat",
        name = name if name != None else base_name(url),
        url = url,
        executable = executable,
        unpack = unpack,
        system = "builtin",
        preferLocalBuild = True,
        impureEnvVars = ["http_proxy", "https_proxy", "ftp_proxy", "all_proxy", "no_proxy"],
        urls = [url],
        outputHashAlgo = "",
        outputHash = hash,
    )

_EXT_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"

def _host(url):
    if not url.startswith("https://"):
        return None
    host, slash, _ = url.removeprefix("https://").partition("/")
    return host if slash else None

def _ext(name):
    """The extension after the last dot, if it is one (lowercase letters and digits), and
    what is before it."""
    base, dot, ext = name.rpartition(".")
    if dot and ext and ext.lstrip(_EXT_CHARS) == "":
        return base, ext
    return name, None

def _group_by_host():
    out = {}
    for p in sorted(MIRRORS):
        out.setdefault(_host(p), []).append(p)
    return out

# mirrors are indexed by host so most urls cost one lookup, not a scan
_BY_HOST = _group_by_host()

def with_mirrors(url):
    """The url itself, then the same path on every mirror of its prefix (nix/mirrors.star)."""
    host = _host(url)
    prefixes = _BY_HOST.get(host, []) if host != None else []
    out = [url]
    for p in prefixes:
        if url.startswith(p):
            out += [m + url[len(p):] for m in MIRRORS[p]]
    return out

def _strip_ext(name):
    """Strip one extension, and a ".tar" before it."""
    base, ext = _ext(name)
    return base.removesuffix(".tar") if ext else name

def _github_tag(url):
    """(repo, tag) of a github tag archive url (extension stripped), else None."""
    if not url.startswith("https://github.com/"):
        return None
    owner, _, rest = url.removeprefix("https://github.com/").partition("/")
    repo, _, rest = rest.partition("/")
    if owner and repo and rest.startswith("archive/refs/tags/"):
        return repo, rest.removeprefix("archive/refs/tags/")
    return None

def url_name(url):
    """"llvm-project-21.1.8.src" from …/llvm-project-21.1.8.src.tar.xz, "fd-v10.5.0" for github
    tag archives."""
    base = _strip_ext(url)
    gh = _github_tag(base)
    return (gh[0] + "-" + gh[1] if gh != None else base_name(base)).replace("~", "-")

def _is_nar(url):
    """A .nar, possibly compressed (.nar.xz)."""
    base, ext = _ext(url)
    return url.endswith(".nar") or (ext != None and base.endswith(".nar"))

def read_sources(file, unpacker, system = None, pin = {}, hashes = {}):
    """The sources.toml at `file` as a struct: version, tag, sys, has(key), fetch(key),
    repin(pin, hashes). `pin`: [pin] keys over the file's, `hashes`: source key -> hash.
    The file is read and each source's derivation made once per run, however many packages
    ask (every variant of jq fetches jq's tarball): they are a lazy set's attributes."""
    s = lazy_attrs(sources_attr, {"file": file, "unpacker": unpacker, "system": system, "pin": pin, "hashes": hashes})
    info = force(s.info)
    return struct(
        file = file,
        version = info["version"],
        tag = info["tag"],
        # our libraries the lock file links (builder/sys-libs.nu), written by uptrack
        sys = info["sys"],
        has = partial(_has, info["keys"]),
        fetch = partial(_fetch, s),
        # the same file under another pin (nix/package.star, for overrides)
        repin = partial(read_sources, file, unpacker, system),
    )

def _has(keys, key):
    return key in keys

def _fetch(s, key):
    return force(getattr(s, "src:" + key))

def sources_attr(name, a):
    """`info`: version, tag, sys and the source keys; `src:<key>`: that source's derivation."""
    t = from_toml(read_file(a["file"]))
    pinned = dict(t.get("pin", {}))
    pinned.update(a["pin"])
    version = pinned.get("version", "")
    tag = pinned.get("tag", version)
    by_key = {s["key"]: s for s in t.get("source", [])}
    for k, h in a["hashes"].items():
        if k in by_key:
            by_key[k] = dict(by_key[k], hash = h)
    if name == "info":
        return {"version": version, "tag": tag, "sys": pinned.get("sys", []), "keys": sorted(by_key)}

    key = name.removeprefix("src:")
    if key not in by_key:
        fail("%s: no source '%s'" % (a["file"], key))
    s = by_key[key]

    # every [pin] key is a {key} placeholder, plus three spellings derived from the version.
    # Nearly every url uses {version} and {tag} only: the full table is built for the rest
    url = s["url"].replace("{version}", version).replace("{tag}", tag)
    if "{" in url:
        parts = version.split(".")
        vars = {"tag": version, "version_": version.replace(".", "_"), "major": parts[0], "minor": parts[1] if len(parts) > 1 else ""}
        vars.update(pinned)
        for k in sorted(vars):
            url = url.replace("{" + k + "}", to_string(vars[k]))

    # a fixed-output path is found by (name, hash): with a constant name a bumped url whose
    # hash was not updated silently reuses the old download, so the name follows the url
    is_nar = _is_nar(url)

    # `hash` is the NAR hash of what lands in the store: for archives the unpacked tree (single
    # top-level directory stripped, u+w), fetched and unpacked by one fixed-output derivation
    # running the seed's nu and bsdtar. `unpack = false` and .nar urls (the seed itself) go
    # through builtin:fetchurl.
    if not s.get("unpack", True) or is_nar:
        return fetchurl(url = url, name = s.get("name", base_name(url)), hash = s["hash"], unpack = is_nar)
    unpacker = a["unpacker"]
    return derivation(
        system = a["system"],
        unpacker = unpacker,
        builder = to_string(unpacker) + "/bin/nu",
        args = ["--no-config-file", path("//pkgs/up/uptrack/src/unpack.nu"), "--fetch"],
        outputHashMode = "recursive",
        preferLocalBuild = True,
        impureEnvVars = ["http_proxy", "https_proxy", "ftp_proxy", "all_proxy", "no_proxy"],
        name = s.get("name", url_name(url)),
        urls = with_mirrors(url),
        outputHash = s["hash"],
    )
