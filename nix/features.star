# A package's `features`: knobs its package.star declares as a top-level FEATURES and reads back
# as values, `c.features`.
#
#   FEATURES = {
#       "tls": {"values": ["openssl", "gnutls", "none"], "default": "openssl", "doc": "TLS backend"},
#       "http3": {"default": False},
#   }
#   def package(c):
#       return c.package(…, dependencies = on(c.features["tls"] != "none", [c.pkgs[c.features["tls"]]]))
#
# The type is the default's (bool, string, list, int), `values` limits a string or a list's
# elements to a set. Resolved once per package as default <- set-wide `features` argument (only
# names the package declares) <- `overrides.<pkg>.features`. A name the package does not declare
# or a value of another type is an error. The result is in the derivation (drv hash) and on it as
# `.features`.

load("//nix/lib.star", "to_string")
load("//nix/overrides.star", "nix_type")

def _check(pkg, decl, given):
    out = {}
    for n in sorted(given):
        v = given[n]
        d = decl[n]
        if nix_type(v) != nix_type(d["default"]):
            fail("%s: feature %s wants a %s, got a %s" % (pkg, n, nix_type(d["default"]), nix_type(v)))
        if "values" in d and not all([x in d["values"] for x in (v if type(v) == "list" else [v])]):
            fail("%s: feature %s = %s, not among %s" % (pkg, n, to_string(v), to_string(d["values"])))
        out[n] = v
    return out

def resolve(pkg, decl, global_, local):
    """decl: the package's FEATURES ({} when absent). global_: the set's. local: overrides.<pkg>.features"""
    if not decl and not local:
        return {}
    unknown = [n for n in sorted(local) if n not in decl]
    if unknown:
        fail("%s: unknown features %s (has: %s)" % (pkg, " ".join(unknown), " ".join(sorted(decl))))
    out = {n: d["default"] for n, d in decl.items()}
    out.update(_check(pkg, decl, {n: v for n, v in global_.items() if n in decl}))
    out.update(_check(pkg, decl, local))
    return {k: out[k] for k in sorted(out)}

def bad(decl):
    """The declarations of the wrong shape."""
    out = []
    for n in sorted(decl):
        d = decl[n]
        ok = type(d) == "dict" and "default" in d and all([k in ("default", "values", "doc") for k in d])
        if ok:
            t = nix_type(d["default"])
            ok = t in ("bool", "string", "list", "int") and (
                "values" not in d or type(d["values"]) == "list" and all([v in d["values"] for v in (d["default"] if t == "list" else [d["default"]])])
            )
        if not ok:
            out.append(n)
    return out
