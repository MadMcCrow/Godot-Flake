# platform.nix
# From flake systems to godot platform
{ system }:
if (system == "x86_64-linux") then
  "linuxbsd"
else if (system == "aarch64-linux") then
  "linuxbsd"
else
  "darwin"
