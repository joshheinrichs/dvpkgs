def package(c):
    return c.package(
        name = "libssh2",
        uses = ["cmake"],
        cmake = {"defs": {
            "CRYPTO_BACKEND": "OpenSSL",
            "ENABLE_ZLIB_COMPRESSION": True,
            "BUILD_EXAMPLES": False,
        }},
        dependencies = [c.pkgs.openssl, c.pkgs.zlib],
        tests = {"run": False},  # the suite wants an ssh server (docker)
    )
