# patchelf reimplementation; `auto-formatelf` (argv[0] personality) gives foreign ELFs our
# interpreter and a RUNPATH resolved against given lib dirs. Used on binary wheels (builder/systems/pyapp.nu).
def package(c):
    return c.package(
        name = "formatelf",
        uses = ["cargo"],
        # finish.nu needs it on Linux before llvm + rust exist
        cargo = c.on(c.platform.os == "linux", {"tool": c.buildPkgs["rust-bootstrap"]}),
        links = {"bin/auto-formatelf": "formatelf", "bin/patchelf": "formatelf"},
        bin = ["formatelf", "auto-formatelf"],
    )
