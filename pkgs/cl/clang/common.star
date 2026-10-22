# clang's libraries (libclang for bindgen, libclang-cpp) against llvm<v>, as nixpkgs'
# clang-unwrapped is. The compiler in use stays `cc`. clang<v>/package.star is `clang(c, "<v>")`
load("//pkgs/ll/llvm/subproject.star", "subproject")

def clang(c, v):
    cross = c.platform.cross
    build_clang = c.buildPkgs["clang" + v]
    defs = {
        "CLANG_LINK_CLANG_DYLIB": True,
        "CLANG_INCLUDE_TESTS": False,
        "CLANG_INCLUDE_DOCS": False,
        "CLANG_BUILD_TOOLS": False,
        "CLANG_BUILD_EXAMPLES": False,
        "CLANG_ENABLE_ARCMT": False,
        "CLANG_ENABLE_STATIC_ANALYZER": False,
        "CLANG_TOOLING_BUILD_AST_INTROSPECTION": False,
        "LIBCLANG_BUILD_STATIC": False,
    }
    if cross:
        defs["CLANG_TABLEGEN"] = "%s/bin/clang-tblgen" % build_clang
    return subproject(c, c.pkgs["llvm" + v], c.buildPkgs["llvm" + v], "clang", {
        "cmake": {"defs": {"merge": defs}},
        "buildDependencies": {"append": c.on(cross, [build_clang])},
        # not installed upstream, a cross clang needs the build machine's
        "phases": {"after": {"set": {"cmake.install": [{
            "name": "clang-tblgen",
            "run": 'cp $"bin/clang-tblgen($c.platform.ext.exe)" $"($c.out)/bin/"',
        }]}}},
        "bin": {"set": []},
    })
