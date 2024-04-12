# default.nix
# correctly build godot depending on options and platform
{ inputs, pkgs, ... }:
let
  # shortcuts
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isDarwin isLinux;

  # TODO : allow customisation :with pa
  options = import ./options.nix { inherit pkgs lib; };
  version = import ./version.nix { inherit inputs pkgs lib; };

  # Get the correct godot from platform
  godotBase = if isLinux then
    (import ./linux.nix  { inherit pkgs options inputs version; })
  else if isDarwin then
    (import ./darwin.nix { inherit pkgs options inputs version; })
  else
    throw "unsupported nix platform, add it to godot/default.nix";

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

in {
  # the editor 
  editor = godotBase.overrideAttrs (prev: {
    pname = "godot-editor";
    sconsFlags = prev.sconsFlags ++ [ "tools=yes" "target=editor" ];
  });
  # templates
  debug = template "template_debug";
  release = template "template_release";
}
