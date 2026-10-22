def package(c):
    return c.package(
        name = "curl",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {
                "CURL_USE_OPENSSL": True,
                "CURL_USE_LIBPSL": False,
                "CURL_USE_LIBSSH2": False,
                "BUILD_LIBCURL_DOCS": False,
                "BUILD_MISC_DOCS": False,
                "ENABLE_CURL_MANUAL": False,
                "CURL_CA_BUNDLE": "/etc/ssl/certs/ca-certificates.crt",
                "CURL_CA_PATH": "/etc/ssl/certs",
                "CURL_CA_SEARCH_SAFE": True,
            },
        },
        tests = {"run": False},  # needs perl + python impacket + minutes
        phases = {"after": {"cmake.install": [{
            # `curl-config --cc` would echo the build compiler's store path
            "name": "curl-config",
            "run": c.lib.text("""
                let f = $"($c.out)/bin/curl-config"
                let text = (open --raw $f | str replace -r "echo '[^']*/bin/cc'" "echo 'cc'")
                $text | save -f $f
            """),
        }]}},
        dependencies = [c.pkgs.openssl, c.pkgs.zlib, c.pkgs.zstd],
        buildDependencies = [c.buildPkgs.perl],
    )
