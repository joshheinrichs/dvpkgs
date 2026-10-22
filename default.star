# The package set for this machine's platform:
#   dv instantiate default.star -A pkgs.zlib
# For another platform, `package_set(platform = "riscv64-linux")` (nix/set.star).
load("//nix/set.star", "package_set")

pkgs = package_set()
