# Overrides: edit package specs from outside the tree (docs/design.md "Overrides"), and the same
# verbs in-tree as `c.variant(pkgs.llvm, {"cmake": {"defs": {"merge": {…}}}})` in a package.star.
#
#   package_set(overrides = {"jq": {"autotools": {"flags": {"append": ["--x"]}}}})
#
# A tree of <package>.<field>….<verb>. Verbs:
#   set      replace the value (creates the field if missing)
#   append   add to the end of a list        prepend  add to the front
#   merge    update a dict                    remove   drop list elements / dict keys, or `True`: the field
#   edit     on a package only: a top-level function spec -> spec, applied after the other verbs
#   features on a package only: {<feature>: value}, no verbs (nix/features.star)
# One node applies as set, remove, merge, prepend/append: `merge`/`append`/`prepend` create a
# missing field (or refill one `remove = True` dropped), and a list `remove` also filters what
# merge/append/prepend add. In dependencies/buildDependencies a string names a package of the
# final set, and remove matches by package name. `overrides` may be a list of trees: they are
# merged first (set/edit: last wins, list verbs concatenate, `remove = True` beats element
# removes), then applied once per package. Unknown package, remove of a missing field, a verb
# argument of the wrong type, or a verb that does not fit the value's type is an error.

VERBS = ["set", "append", "prepend", "merge", "remove"]

_DEP_FIELDS = ["dependencies", "buildDependencies"]

def nix_type(v):
    t = type(force(v))
    return {"dict": "set", "struct": "set", "derivation": "set", "function": "lambda", "NoneType": "null"}.get(t, t)

def _is_dict(v):
    return type(v) == "dict"

def is_verb_node(node):
    return _is_dict(node) and len(node) > 0 and all([k in VERBS for k in node])

def merge_trees(trees):
    names = {}
    for t in trees:
        for k in t:
            names[k] = True
    out = {}
    for name in sorted(names):
        vals = [t[name] for t in trees if name in t]
        if name in VERBS and all([is_verb_node(v) for v in vals]):
            # a field that happens to be called like a verb (phases.remove) holds verb nodes itself
            out[name] = merge_trees(vals)
        elif name == "set" or name == "edit":
            out[name] = vals[-1]
        elif name == "features" or name == "merge":
            m = {}
            for v in vals:
                m.update(v)
            out[name] = m
        elif name == "remove" and any([v == True for v in vals]):
            out[name] = True
        elif name in ("append", "prepend", "remove"):
            l = []
            for v in vals:
                if type(v) != "list":
                    fail("overrides: %s takes a list, got a %s" % (name, nix_type(v)))
                l += v
            out[name] = l
        elif all([_is_dict(v) for v in vals]):
            out[name] = merge_trees(vals)
        else:
            fail("overrides: conflicting values at " + name)
    return out

def pname(d):
    d = force(d)
    if hasattr(d, "pname"):
        return d.pname
    if hasattr(d, "name"):
        return d.name
    return str(d)

def _apply_verbs(ctx, path, node, has, old):
    here = ".".join(path)

    def fail_(msg):
        fail("overrides: %s.%s: %s" % (ctx.pkg, here, msg))

    is_deps = len(path) == 1 and path[0] in _DEP_FIELDS

    def resolve(v):
        if is_deps and type(v) == "string":
            if not ctx.has_pkg(v):
                fail_("no package named " + v)
            return ctx.pkgs[v]
        return v

    def arg(verb, want):
        v = node[verb]
        if want == "list" and type(v) == "list":
            return [resolve(x) for x in v]
        if want == "set" and _is_dict(v):
            return v
        fail_("%s takes a %s, got a %s" % (verb, want, nix_type(v)))

    lists = "prepend" in node or "append" in node
    drop = "remove" in node and node["remove"] != True
    dropped = [pname(r) if is_deps and type(r) != "string" else r for r in arg("remove", "list")] if drop else []

    def keep(d):
        return (pname(d) if is_deps else d) not in dropped

    # the value the other verbs edit: set, else the field, else what merge/append imply
    if "set" in node:
        start = arg("set", "list") if is_deps else node["set"]
    elif has and node.get("remove") != True:
        start = old
    elif "merge" in node:
        start = {}
    elif lists:
        start = []
    elif "remove" in node:
        start = old if has else fail_("remove: no such field")
    else:
        fail_("no such field (use .set to create it)")

    # remove also filters what merge/append/prepend add, so a later tree can take back an earlier one's
    if not drop:
        after_remove = start
    elif type(start) == "list":
        after_remove = [d for d in start if keep(d)]
    elif _is_dict(start):
        after_remove = {k: v for k, v in start.items() if k not in dropped}
    else:
        fail_("remove from a %s, expected a list or set" % nix_type(start))

    if "merge" not in node:
        after_merge = after_remove
    elif _is_dict(after_remove):
        after_merge = dict(after_remove)
        after_merge.update({k: v for k, v in arg("merge", "set").items() if k not in dropped})
    else:
        fail_("merge into a %s, expected a set" % nix_type(after_remove))

    if not lists:
        return after_merge
    if type(after_merge) != "list":
        fail_("append to a %s, expected a list" % nix_type(after_merge))
    return [d for d in (arg("prepend", "list") if "prepend" in node else []) + after_merge + (arg("append", "list") if "append" in node else []) if keep(d)]

def walk(ctx, path, tree, has, old):
    """Walk tree and spec together; returns the edited value."""
    here = ".".join(path)
    if is_verb_node(tree):
        return _apply_verbs(ctx, path, tree, has, old)
    if not _is_dict(tree):
        fail("overrides: %s.%s: expected a verb (%s), got a %s" % (ctx.pkg, here, " ".join(VERBS), nix_type(tree)))
    if "edit" in tree:
        fail("overrides: %s.%s.edit: edit goes on the package, not a field" % (ctx.pkg, here))

    # a verb name whose value is not itself a node was meant as a verb (a field called `remove`
    # is still reachable: phases.remove.set = [ … ])
    mixed = [k for k in sorted(tree) if k in VERBS and not is_verb_node(tree[k])]
    if mixed:
        fields = [k for k in sorted(tree) if k not in VERBS or is_verb_node(tree[k])]
        fail("overrides: %s.%s: mixes verbs (%s) with fields (%s)" % (ctx.pkg, here, " ".join(mixed), " ".join(fields)))
    if has and _is_dict(old):
        cur = old
    elif has:
        fail("overrides: %s.%s: is a %s, cannot descend" % (ctx.pkg, here, nix_type(old)))
    else:
        cur = {}
    out = dict(cur)
    for k in sorted(tree):
        out[k] = walk(ctx, path + [k], tree[k], k in cur, cur.get(k))
    for k in sorted(tree):
        if tree[k] == {"remove": True}:
            out.pop(k)
    return out

def apply_one(ctx, name, node, spec):
    """One package's subtree applied to its spec (also what `variant` uses). `ctx`: struct of
    pkgs and has_pkg."""
    if not _is_dict(node):
        fail("overrides: %s: expected {<field>…}, got a %s" % (name, nix_type(node)))
    edit = node.get("edit")
    if edit != None and type(edit) != "function":
        fail("overrides: %s.edit: expected a function spec -> spec, got a %s" % (name, nix_type(edit)))
    c = struct(pkg = name, pkgs = ctx.pkgs, has_pkg = ctx.has_pkg)
    spec = walk(c, [], {k: v for k, v in node.items() if k != "edit"}, True, spec)
    return edit(spec) if edit != None else spec

def apply(ctx, tree, name, spec):
    """From the user's tree, where `<pkg>.features` is plain values nix/set.star resolved
    before the spec existed."""
    if name not in tree:
        return spec
    node = tree[name]
    if not _is_dict(node):
        return apply_one(ctx, name, node, spec)
    return apply_one(ctx, name, {k: v for k, v in node.items() if k != "features"}, spec)

def unknown(has_pkg, tree):
    """Packages the tree names that the set lacks."""
    return [n for n in sorted(tree) if not has_pkg(n)]

def merge(trees):
    return merge_trees(trees) if type(trees) == "list" else trees
