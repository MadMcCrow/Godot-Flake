# export.nix
# Function to build/export game made with godot
{ pkgs, ... }:
{ godot, src, name, nativeBuildInputs ? [], ... } @args :
with pkgs;
with builtins;
let

  templateName = pkgs.system;
  linux_ext = ".bin";

  # remove args not used in mkDerivation or merged manually
  buildArgs = removeAttrs args ["godot" "nativeBuildInputs"];

  # result derivation
in stdenv.mkDerivation ({
  inherit name src;
  nativeBuildInputs = [ godot breakpointHook ] ++ nativeBuildInputs;
  buildPhase = ''${godot}/bin/godot --export ${templateName} ${name}${linux_ext}'';
  installPhase = ''
    echo "TODO !"
    ls -la
    breakpointHook
  '';
 } // buildArgs)
