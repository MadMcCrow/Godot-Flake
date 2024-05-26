# Godot.nix
# this modules focuses on building godot
# everything here is shared between all godot versions
{ inputs, pkgs }:
let
  # shorten a lot of text
  inherit (pkgs) stdenv;

  # version
  version = import ./version.nix { inherit inputs pkgs; };

  # TODO :support cross-building
  arch = if stdenv.isx86_64 then "x86_64"
  else if stdenv.isAarch64 then  "aarch64"
  else throw "unsupported arch";
  
  platform = if stdenv.isDarwin then "darwin"
  else if stdenv.isLinux then "linux"
  else throw "unsupported platform";

  # shared between editor and templates
  generic = stdenv.mkDerivation {
    version = "${version.asString}";
    src = inputs.godot;
    sconsFlags = [ "arch=${arch}" "platform=${platform}" ];
    patches = [
      ./patches/xfixes.patch # fix x11 libs
      ./patches/gl.patch # fix gl libs
    ];
    meta = with pkgs.lib; {
      platforms =
        [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      homepage = pkgs.godot_4.meta.homepage;
      description = pkgs.godot_4.meta.description;
      license = licenses.mit;
    };
  };

 

in editor
