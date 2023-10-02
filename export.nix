# export.nix
# Function to build/export game made with godot
{ pkgs, ... }:
{ godot, src, name, nativeBuildInputs ? [], ... } @args :
with pkgs;
let

  templateName = pkgs.system;
  linux_ext = ".bin";

  # result derivation
in stdenv.mkDerivation (args // {
  inherit name src;
  nativeBuildInputs = [ godot breakpointHook ] ++ nativeBuildInputs;
  buildPhase = ''${godot}/bin/godot --export ${templateName} ${name}${linux_ext}'';
  installPhase = ''
    echo "TODO !"
    ls -la
    breakpointHook
  '';
 })
