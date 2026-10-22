# qemu user-mode emulators only (cross tests: platform.emulator). System emulation, tools, docs off.
def package(c):
    return c.package(
        name = "qemu",
        dependencies = [c.pkgs.glib, c.pkgs.zlib],
        buildDependencies = [c.buildPkgs.cpython, c.buildPkgs.ninja],
        phases = [
            {
                "name": "configure",
                "run": c.lib.text("""
                    # the tooling venv group wants setuptools, wheel and pip to install qemu's own python/
                    # package, which only the functional tests use
                    let deps = (open --raw pythondeps.toml | lines | where { $in !~ '^"(qemu|setuptools|wheel|pip)" =' })
                    $deps | str join "\\n" | save -f pythondeps.toml
                    # an error-attribute stub for hosts GCC gives no 16-byte cmpxchg. clang has one through
                    # compiler-rt's libcalls, so HAVE_CMPXCHG128 holds and the generic CAS loop is wanted
                    rm host/include/loongarch64/host/store-insert-al16.h.inc
                    cd $c.build
                    # --cross-prefix is what switches configure to a cross build
                    $env.PKG_CONFIG = "pkg-config"
                    let cross = (if $c.platform.cross { [$"--cross-prefix=($c.platform.gnuTriple)-" $"--host-cc=($env.CC_FOR_BUILD)"] } else { [] })
                    # --prefix paths are templates, get_relocated_path() rebases them on the binary
                    (x (tool sh) $"($c.src)/configure" --prefix=/usr --disable-download --without-default-features
                      --enable-linux-user --disable-system --disable-tools --disable-docs --disable-werror
                      --target-list=aarch64-linux-user,loongarch64-linux-user,ppc64le-linux-user,riscv64-linux-user,x86_64-linux-user $"--python=(which python3 | get 0.path)" ...$cross)
                """),
            },
            {"name": "build", "run": "x ninja -C $c.build $\"-j($c.njobs)\""},
            {
                # through ninja: the meson that configured is qemu's vendored one, not ours
                "name": "install",
                "run": c.lib.text("""
                    with-env {DESTDIR: $"($c.build)/dest"} { x ninja -C $c.build install }
                    ^cp -r $"($c.build)/dest/usr/." $c.out
                    # firmware and keymaps are for system emulation (--disable-install-blobs also drops the vdso)
                    rm -rf $"($c.out)/share/qemu"
                """),
            },
        ],
        tests = {"run": False},
        bin = ["qemu-aarch64", "qemu-loongarch64", "qemu-ppc64le", "qemu-riscv64", "qemu-x86_64"],
    )
