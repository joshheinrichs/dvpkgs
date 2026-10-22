# upstream's std for the target, beside rust-bootstrap's host one when formatelf cross-builds
# (builder/systems/cargo.nu overlays <toolchain>-std). Shares rust-bootstrap's sources.toml
def package(c):
    def edit(spec):
        return {
            "name": spec["name"],
            "prebuilt": spec["prebuilt"],
            "source": "rust-std-" + c.platform.cpu,
            "phases": [{
                "name": "install",
                "run": c.lib.text("""
                    x sh install.sh $"--prefix=($c.out)" --disable-ldconfig
                    rm -rf ...(glob $"($c.out)/lib/rustlib/{install.log,uninstall.sh,components,rust-installer-version,manifest-*}")
                """),
            }],
            "exports": False,
        }

    return c.variant(c.pkgs["rust-bootstrap"], {"edit": edit})
