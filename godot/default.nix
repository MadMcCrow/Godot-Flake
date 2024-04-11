# default.nix
# correctly build godot depending on options and platform
{ inputs, pkgs, options ? [ ] }:
let
  inherit (pkgs) lib;
  
  # x86_64-linux    -> linux
  # aarch64-linux   -> linux 
  # aarch64-darwin  -> darwin
  platform = with builtins;
    elemAt (elemAt (split "[\\w\\_\\-]*-([a-zA-Z]+)" pkgs.stdenv.system) 1) 0;

  options = import ./options.nix {inherit pkgs lib;};

  # build godot :
  godot = import ./godot.nix {
    inherit inputs pkgs platform options;
  };
in godot.editor
