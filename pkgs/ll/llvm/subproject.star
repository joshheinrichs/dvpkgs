# one llvm-project subtree (clang, lld) built standalone against an already built llvm<N>:
# same tarball and pin as that base, its libLLVM linked, its tblgen used

def subproject(c, llvm, build_llvm, root, tree):
    return c.variant(llvm, [
        {
            "patches": {"set": []},
            "cmake": {
                "root": {"set": root},
                "defs": {"set": {
                    "LLVM_DIR": "%s/lib/cmake/llvm" % llvm,
                    "LLVM_TOOLS_BINARY_DIR": "%s/bin" % build_llvm,
                    "LLVM_TABLEGEN_EXE": "%s/bin/llvm-tblgen" % build_llvm,
                    "LLVM_LINK_LLVM_DYLIB": True,
                    "BUILD_SHARED_LIBS": False,
                    "LLVM_INCLUDE_TESTS": False,
                    "LLVM_PARALLEL_LINK_JOBS": 4,
                }},
            },
            # LLVMExports.cmake names ZLIB::ZLIB and zstd in libLLVM's link interface
            "dependencies": {"set": [llvm, c.pkgs.zlib, c.pkgs.zstd]},
            "buildDependencies": {"set": [c.buildPkgs.cpython, build_llvm]},
            "phases": {"after": {"set": {}}, "remove": {"set": ["cmake.test"]}},
        },
        tree,
    ])
