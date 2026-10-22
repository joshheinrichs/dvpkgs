def package(c):
    return c.package(
        name = "boost",
        uses = ["cmake"],
        # libc++ _LIBCPP_BEGIN_NAMESPACE_STD opens a clang attribute region
        # triggering unused attribute warnings spam in build log
        cc = {"cxxflags": ["-Wno-pragma-clang-attribute"]},
        cmake = {"defs": {"BOOST_ENABLE_MPI": False, "BOOST_ENABLE_PYTHON": False}},
        patches = [path("upstream-redis-cmath.patch")],
        dependencies = [c.pkgs.zlib, c.pkgs.bzip2, c.pkgs.zstd, c.pkgs.openssl],
        tests = {"run": False},  # hours
    )
