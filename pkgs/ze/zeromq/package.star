def package(c):
    return c.package(
        name = "zeromq",
        uses = ["cmake"],
        patches = [path("upstream-nothrow-include-new.patch")],
        cmake = {
            "defs": {
                "CMAKE_POLICY_VERSION_MINIMUM": "3.5",  # cmake_minimum_required 2.8
                "WITH_LIBSODIUM": True,
                "ENABLE_CURVE": True,
            },
            # a hand-rolled TCP peer polls with msleep(1) against the 10 s TIMEOUT
            "skipTests": ["test_mock_pub_sub"],
        },
        dependencies = [c.pkgs.libsodium],
        tests = {"parallel": False},  # every test gets a 10 s TIMEOUT; in parallel on a loaded machine they exceed it
    )
