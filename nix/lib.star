# Helpers for package.star files and nix/*.star. The names follow repkgs' nix/lib.nix where
# there is one (on, per, join, lines); the rest stand in for the Nix builtins Starlark lacks:
# toString, baseNameOf, and the indentation rules of a '' string.

def on(cond, v):
    """`v` when `cond` holds, else the empty dict or list: `+ on(platform.cross, [...])`."""
    if cond:
        return v
    if type(v) == "dict":
        return {}
    return []

def per(key, table):
    """The entry for `key`, else `default`, else an error naming the key."""
    if key in table:
        return table[key]
    if "default" in table:
        return table["default"]
    fail("no entry for " + key)

def join(sep, xs):
    return sep.join(xs)

def lines(xs):
    return "\n".join(xs)

def to_string(v):
    """Nix's `toString`: lists space separated (no space after an empty list), true is "1",
    false and None are empty, derivations are their `out` path."""
    t = type(v)
    if t == "string":
        return v
    if t == "bool":
        return "1" if v else ""
    if v == None:
        return ""
    if t == "int":
        return str(v)
    if t == "list":
        out = ""
        for i, x in enumerate(v):
            out += to_string(x)
            if i + 1 < len(v) and not (type(x) == "list" and len(x) == 0):
                out += " "
        return out
    return str(v)

def base_name(p):
    """`baseNameOf`: after the last slash, a trailing slash ignored."""
    p = p.removesuffix("/")
    return p.rpartition("/")[2]

def dir_name(p):
    """`dirOf` of a path string."""
    d = p.rpartition("/")[0]
    return d if d else "/"

def text(s, **vars):
    """A Nix '' string: the opening line dropped when blank, the common indentation of the lines
    with content stripped, a blank last line dropped; then each `${name}` replaced by
    `to_string(vars[name])`, which as in Nix counts as content where it starts a line."""
    first = s.find("\n")
    if first >= 0 and s[:first].strip(" ") == "":
        s = s[first + 1:]
    lines_ = s.split("\n")
    indent = None
    for l in lines_:
        stripped = l.lstrip(" ")
        if stripped == "":
            continue
        k = len(l) - len(stripped)
        if indent == None or k < indent:
            indent = k
    indent = indent or 0
    out = []
    for l in lines_:
        stripped = l.lstrip(" ")
        k = len(l) - len(stripped)
        out.append(" " * max(0, k - indent) + stripped)
    if out and out[-1].strip(" ") == "":
        out[-1] = ""
    r = "\n".join(out)
    for k in sorted(vars):
        r = r.replace("${" + k + "}", to_string(vars[k]))
    return r

def attr_names(d):
    """`builtins.attrNames`: sorted."""
    return sorted(d.keys())

def without(d, keys):
    """`removeAttrs`."""
    return {k: v for k, v in d.items() if k not in keys}

def merge(*ds):
    """`a // b // …`, keys sorted as Nix keeps them."""
    out = {}
    for d in ds:
        out.update(d)
    return {k: out[k] for k in sorted(out)}

def flatten(xss):
    out = []
    for xs in xss:
        out += xs
    return out
