# a bundler application with native-extension gems (prism, rbs, json; psych gets our libyaml via
# sys-libs.nu): Gemfile.lock carries CHECKSUMS
def package(c):
    return c.package(
        name = "ruby-lsp",
        uses = ["bundler"],
        # Gemfile.lock pins sorbet-static for x86_64-linux and darwin only, no checksum for other cpus
        platforms = {"cpu": ["x86_64"]},
        dependencies = [c.pkgs.ruby],
        bin = ["ruby-lsp", "ruby-lsp-check"],
    )
