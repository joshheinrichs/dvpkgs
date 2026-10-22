# bin/erl finds its root from $0, so the tree relocates as installed. A cross build needs a
# native erlang of the same release to compile the .erl files. No wx, odbc, jinterface
def package(c):
    cross = c.platform.cross
    return c.package(
        name = "erlang",
        # otp's own Windows build is msvc under WSL/cygwin, configure has no mingw target
        platforms = {"posix": True},
        uses = ["autotools"],
        autotools = {
            "outOfTree": False,
            "flags": [
                "--enable-kernel-poll",
                "--with-ssl=%s" % c.pkgs.openssl,
                "--without-javac",
                "--without-odbc",
                "--without-wx",
                "--disable-parallel-configure",
            ] + (["erl_xcomp_sysroot=%s" % c.toolchain.sysroot] if cross else []),
        },
        # the suites run under ts for hours, tests.version and elixir exercise the install.
        # The full version is only in releases/<otp major>/OTP_VERSION, which erl reads here
        tests = {
            "run": False,
            "version": 'erl -noshell -eval {ok,V}=file:read_file(filename:join([code:root_dir(),"releases",erlang:system_info(otp_release),"OTP_VERSION"])),io:put_chars(V),halt().',
        },
        patches = [path("upstream-cstdlib.patch"), path("erl-dirname.patch")],
        buildDependencies = [c.buildPkgs.perl] + c.on(cross, [c.buildPkgs.erlang]),
        dependencies = [c.pkgs.ncurses, c.pkgs.openssl, c.pkgs.zlib],
        exports = False,
        bin = ["erl", "erlc", "escript"],
    )
