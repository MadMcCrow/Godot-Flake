# default.nix
# correctly build godot depending on platform
{ inputs, pkgs, options ? { }, ... }@args:
let
  # default
  generic = pkgs.callPackage ./common {
    inherit options;
    godot = inputs.godot;
  };
  # implementation
in if pkgs.stdenv.isLinux then
  generic.overrideAttrs (import ./linux {inherit pkgs options;})
else if pkgs.stdenv.isDarwin then
  generic.overrideAttrs (import ./macos args)
else
  throw "unsupported platform ${pkgs.stdenv.system}"
