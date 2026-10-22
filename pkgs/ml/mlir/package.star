# MLIR libraries and mlir-tblgen against llvm, for flang
load("//pkgs/ll/llvm/subproject.star", "subproject")

def package(c):
    return subproject(c, c.pkgs.llvm, c.buildPkgs.llvm, "mlir", {
        "cmake": {"defs": {"merge": {
            "MLIR_INCLUDE_TESTS": False,
            "MLIR_INCLUDE_INTEGRATION_TESTS": False,
            "MLIR_INCLUDE_DOCS": False,
            "MLIR_ENABLE_BINDINGS_PYTHON": False,
            "MLIR_INSTALL_AGGREGATE_OBJECTS": False,
            # tools linked against libMLIR lose their tablegen header dependencies (23.1)
            "MLIR_LINK_MLIR_DYLIB": False,
        }}},
        "platforms": {"set": {"cross": False}},
        # not installed upstream, flang's configure wants it
        "phases": {"after": {"set": {"cmake.install": [{
            "name": "mlir-tblgen",
            "run": 'cp bin/mlir-tblgen $"($c.out)/bin/"',
        }]}}},
        "bin": {"set": ["mlir-tblgen"]},
    })
