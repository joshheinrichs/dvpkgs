# lld's libraries and ld.lld against llvm<v>. lld<v>/package.star is `lld(c, "<v>")`
load("//pkgs/ll/llvm/subproject.star", "subproject")

def lld(c, v):
    return subproject(c, c.pkgs["llvm" + v], c.buildPkgs["llvm" + v], "lld", {
        "bin": {"set": ["ld.lld"]},
        "tests": {"version": {"set": True}},
    })
