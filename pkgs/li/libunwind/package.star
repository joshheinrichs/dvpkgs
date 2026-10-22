# the nongnu libunwind (unw_* over ptrace and core dumps), not LLVM's unwinder
def package(c):
    return c.package(
        name = "libunwind",
        uses = ["autotools"],
        patches = [path("upstream-test-runner-relative.patch")],
        autotools = {"outOfTree": False},  # tests/run-ptrace-* look for test-ptrace next to themselves
        dependencies = [c.pkgs.xz, c.pkgs.zlib],
        platforms = {"os": ["linux"]},
    )
