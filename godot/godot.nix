# Godot.nix
# this modules focuses on building godot
{ inputs, pkgs, options, platform }:
let
  # version
  version = import ./version.nix { inherit inputs pkgs; };

  # get the built attributes for platform 
  platformAttrs = import (if platform == "darwin" then ./darwin.nix else ./linux.nix) {
      inherit inputs pkgs options;
    };

  # how to build godot :
  godotBase = pkgs.stdenv.mkDerivation ( platformAttrs // {
      version = "${version.asString}";
      src = inputs.godot;
      # default build flags
      sconsFlags = (if platformAttrs ? "sconsFlags" then
      platformAttrs.sconsFlags else []) 
      ++ map (x : ''${x}=${options."${x}"}'')
      (builtins.attrNames options);
      # meta is shared between systems
      meta = with pkgs.lib; {
        # TODO: add correct platform list
        platforms = [ pkgs.stdenv.system ];
        homepage = pkgs.godot_4.meta.homepage;
        description = pkgs.godot_4.meta.description;
        license = licenses.mit;
        mainProgram = "godot";
      };
    });

  template = target : godotBase.overrideAttrs (prev : prev // {
    pname = "godot-${target}";
    sconsFlags = prev ++ ["tools=no"];
     installPhase = ''
          mkdir -p "$out/share/godot/templates/${prev.version}"
          cp bin/godot.* $out/share/godot/templates/${prev.version}/${platform}-${target}
        '';
  });


in {
 editor = godotBase.overrideAttrs (prev : prev // {
    pname = "godot-editor";
    sconsFlags = prev.sconsFlags
    ++ ["tools=yes" "target=editor"];
  });
  debug   = template "template_debug";
  release = template "template_release";
}
