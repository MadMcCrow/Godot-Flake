# Godot is a cross-platform open-source game engine written in C++
# Godot-cpp is the bindings to build custom extensions
# Godot-rust is one of the most common extensions for godot
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

    # the godot Rust GDExtension
    godot-rust = {
      url = "github:godot-rust/gdextension";
      flake = false;
    };
  };

  # func
  outputs = { self, nixpkgs, ... }@inputs:
    let
      # only linux supported, todo, support darwin
      system = "x86_64-linux";
      # use nixpkgs
      pkgs = import nixpkgs { inherit system; };
      lib  = import lib;
      # import godot.nix
      buildGodot = import ./godot.nix { inherit system pkgs inputs; };
      # implementation
    in rec {

      #interface
      packages."${system}" = with pkgs; {

        
        godot-editor   = buildGodot.mkGodot {}; # Godot Editor
        godot-template = { # Godot templates
          release = buildGodot.mkGodotTemplate {target = "release";};
          debug   = buildGodot.mkGodotTemplate {target = "debug";  };
        };

        default = pkgs.linkFarmFromDrvs "godot" [
        packages."${system}".godot-editor
        packages."${system}".godot-template.release
        packages."${system}".godot-template.debug
        ];
      };
      # dev-shell
      devShells."${system}".default = with pkgs;
        mkShell { };
      };
}
