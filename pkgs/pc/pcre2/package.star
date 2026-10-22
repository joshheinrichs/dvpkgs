def package(c):
    return c.package(
        name = "pcre2",
        uses = ["cmake"],
        tests = {"separate": True},
        cmake = {"defs": {
            "PCRE2_SUPPORT_JIT": True,
            "PCRE2_BUILD_PCRE2_16": True,
            "PCRE2_BUILD_PCRE2_32": True,
            "PCRE2GREP_SUPPORT_CALLOUT_FORK": False,  # test execs /bin/echo
        }},
        dependencies = [c.pkgs.zlib, c.pkgs.bzip2],
    )
