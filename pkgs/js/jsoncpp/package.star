def package(c):
    return c.package(
        name = "jsoncpp",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {
                "JSONCPP_WITH_TESTS": False,
                "JSONCPP_WITH_POST_BUILD_UNITTEST": False,
                "BUILD_OBJECT_LIBS": False,
                # import lib and static lib are both lib/jsoncpp.lib there
                "BUILD_STATIC_LIBS": c.platform.libc != "msvc",
            },
        },
    )
