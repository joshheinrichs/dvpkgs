# libLLVM of the major rustc bundles (src/llvm-project in the rustc tarball), one behind ours:
# rustc's feature tables track that major and reject or invent names on a newer one (amx-tf32)
def package(c):
    return c.variant(c.pkgs.llvm, {})
