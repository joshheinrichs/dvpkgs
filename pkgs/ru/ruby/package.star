# CRuby. Cross: configure runs a `baseruby` on the build machine (buildPkgs.ruby); ext/ compile
# through jig like any C. rbconfig.rb records CC etc. as the bare names our cc provides, so gems with
# native extensions build against whatever toolchain is on PATH later (the bundler build system's).
def package(c):
    pkgs = c.pkgs
    cross = c.platform.cross
    return c.package(
        name = "ruby",
        uses = ["autotools"],
        autotools = {"flags": [
            "--enable-load-relative",  # prefix from libruby's location, rbconfig TOPDIR from rbconfig.rb's
            "--disable-install-doc",
            "--sysconfdir=/etc",  # Etc.sysconfdir is the machine's
            "--enable-shared",
            "--with-out-ext=win32,win32ole,readline,gdbm,dbm",
            "--without-git",
            "--without-baseruby",
        ] + c.on(cross, ["--with-baseruby=ruby"])},
        buildDependencies = c.on(cross, [c.buildPkgs.ruby]),
        dependencies = [
            pkgs.bash,  # rbconfig's CONFIG["SHELL"], mkmf runs commands through it
            pkgs.zlib,
            pkgs.openssl,
            pkgs.libyaml,
            pkgs.libffi,
        ],
        phases = {
            # rbinstall copies each script's own #! line (libexec/, .bundle/gems/*/exe) under its
            # sh prolog. When cross compiling a build ruby is on PATH, so prepare's shebang rewrite
            # had pointed those lines at it: undo that before install
            "before": {"autotools.install": c.on(cross, [{"name": "script-shebangs", "run": "fix-shebangs $c.src --undo"}])},
            "after": {"autotools.install": [{
                # rbconfig.rb describes the build machine: configure's bash and clang's InstalledDir line
                "name": "rbconfig",
                "run": c.lib.text("""
                    for f in (glob $"($c.out)/lib/ruby/*/*/rbconfig.rb") {
                      let text = (open --raw $f
                        | str replace -r '(CONFIG\\["SHELL"\\] = ")[^"]*' ("${1}" + (dep-root bash "rbconfig SHELL") + "/bin/bash")
                        | str replace -r '(CONFIG\\["CC_VERSION_MESSAGE"\\] = "[^"]*?)\\\\nInstalledDir: [^"]*' "${1}")
                      $text | save -f $f
                    }
                """),
            }]},
        },
        tests = {"run": False},  # `make check` is hours; tests.version covers "it starts and finds its stdlib"
        bin = ["ruby", "gem", "bundle", "irb", "rake"],
    )
