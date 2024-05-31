# Godot.nix
# this modules focuses on building godot
# everything here is shared between all godot versions
{ inputs, pkgs }:
let
  # shorten a lot of text
  inherit (pkgs) stdenv;

  # derivate templates from the default base
  template = target:
    let
      platform = if isLinux then
        "linux"
      else if isDarwin then
        "macos"
      else
        "unsupported";
    in godotBase.overrideAttrs (prev: {
      pname = "godot-${target}";
      sconsFlags = prev ++ [ "tools=no" ];
      installPhase = ''
        mkdir -p "$out/share/godot/templates/${prev.version}"
        cp bin/godot.* $out/share/godot/templates/${prev.version}/${platform}-${target}
      '';
    });

in editor
