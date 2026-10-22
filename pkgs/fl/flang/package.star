# LLVM's Fortran compiler, standalone against llvm, clang and mlir of the same pin
load("//pkgs/ll/llvm/subproject.star", "subproject")

def package(c):
    pkgs, build = c.pkgs, c.buildPkgs
    return subproject(c, pkgs.llvm, build.llvm, "flang", {
        "cmake": {"defs": {"merge": {
            "CLANG_DIR": "%s/lib/cmake/clang" % pkgs.clang,
            "MLIR_DIR": "%s/lib/cmake/mlir" % pkgs.mlir,
            "MLIR_TABLEGEN_EXE": "%s/bin/mlir-tblgen" % build.mlir,
            "FLANG_INCLUDE_TESTS": False,
            "FLANG_INCLUDE_DOCS": False,
        }}},
        "dependencies": {"append": [pkgs.clang, pkgs.mlir]},
        "platforms": {"set": {"cross": False}},
        "bin": {"set": ["flang"]},
        "tests": {"version": {"set": True}},
    })
