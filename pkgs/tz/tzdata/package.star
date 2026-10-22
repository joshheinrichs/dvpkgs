# share/zoneinfo plus zic, zdump and tzselect (tzcode and tzdata are one tree, tzdb)
def package(c):
    return c.package(
        name = "tzdata",
        # zic and friends are POSIX programs, Windows keeps its own zone database
        platforms = {"os": ["linux", "macos"]},
        uses = ["make"],
        # TOPDIR is / for the compiled-in TZDIR and TZDEFAULT (the machine's), the prefix only at install
        make = {
            "flags": [
                "cc=cc",
                "AR=llvm-ar",
                "RANLIB=llvm-ranlib",
                "USRDIR=",
                "ZICDIR=$(BINDIR)",
            ] +
            # cross: the zone files are compiled by a zic that runs here
            (["zic=%s/bin/zic" % c.buildPkgs.tzdata] if c.platform.cross else []),
            "installFlags": ["TOPDIR=$(PREFIX)"],
            "programs": ["zic", "zdump"],
        },
        tests = {"run": False},  # `make check` validates the sources against the web and a UTF-8 grep
    )
