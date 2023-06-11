# Godot is a cross-platform open-source game engine written in C++
#
# This flake build godot, the cpp bindings and the export templates
#
{
  description = "the godot Engine, and the godot-cpp bindings for extensions";
  inputs = {

    # the godot Engine
    godot = {
      url = "github:godotengine/godot";
      flake = false;
    };

    # the godot cpp bindings to build GDExtensions
    godot-cpp = {
      url = "github:godotengine/godot-cpp";
      flake = false;
    };

    # the nixpkgs repo
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      #default build args
      buildArgs = {
        # godot bin name :
        pname = "godot";
        version = "4.1.0-beta";
        # ideal options for building godot on nix
        options = {
          use_volk = false;
          use_sowrap = true; # make sure to link to system libraries
          production = true;
          optimize = "speed";
          lto = "full";
        };
        withTemplates = true;
      };

      # only linux supported for now
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # helper to build for multiple system
      forAllSystems = function:
        nixpkgs.lib.genAttrs systems
        (system: function nixpkgs.legacyPackages.${system});

      # helper function
      callGodot = pkgs :
        import ./godot.nix { inherit pkgs inputs; system = pkgs.system;};
      callGdExt = pkgs :
        import ./godot.nix { inherit pkgs inputs; system = pkgs.system;};

    in {
      # pre-defined godot engine 
      packages = forAllSystems (pkgs: rec {
        # godot engine 
        godot-engine = (callGodot pkgs).mkGodot buildArgs;
        default =  godot-engine;
      });

      # add build functions 
      lib = forAllSystems (pkgs: rec {
        libGodot = callGodot pkgs;
        libGdExt = callGdExt pkgs;
      });

      devShells = forAllSystems (pkgs: rec {
        default = (callGodot pkgs).mkGodotShell buildArgs;
      });

    };
}
