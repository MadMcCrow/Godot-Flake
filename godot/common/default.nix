# common/default.nix
# godot default build options :
{ callPackage, stdenv, zlib, yasm, godot_4, godot, options ? { }, ... }@args:
stdenv.mkDerivation rec {
  # basic stuff :
  pname = "godot";
  version = callPackage ./version.nix args;
  src = godot;

  # import options and turn them into scons flags :
  sconsFlags = let opt = (import ./options.nix {}) // options;
  in (map (x: ''${x}=${opt."${x}"}'') (builtins.attrNames opt));

  buildInputs = [ zlib yasm ];
  # nixpkgs use Godot4 and godot4 instead of godot, so we replace
  installPhase = builtins.replaceStrings [ "odot4" ] [ "odot" ] godot_4.installPhase;

  # copy relevant infos and add our own
  meta = {
    inherit (godot_4.meta) description homepage license name mainProgram;
  };
}
