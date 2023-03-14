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
  };

  # func
  outputs = { self, nixpkgs, ... }@inputs:
    let
      # only linux supported, todo, support darwin
      system = "x86_64-linux";
      # use nixpkgs
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
      # import godot.nix
      buildGodot = import ./godot.nix      { inherit lib pkgs system inputs; };
      buildGdExt = import ./extensions.nix { inherit lib pkgs system inputs; };
      # implementation
    in rec {

      #interface
      packages."${system}" = with pkgs; {

        godot-editor = buildGodot.mkGodot { }; # Godot Editor
        godot-template-release = buildGodot.mkGodotTemplate { target = "release"; };
        godot-template-debug = buildGodot.mkGodotTemplate { target = "debug"; };
        godot-cpp =  buildGdExt.mkGodotCpp {};

        default = pkgs.linkFarmFromDrvs "godot" [
          packages."${system}".godot-editor
          packages."${system}".godot-template-release
          packages."${system}".godot-template-debug
          packages."${system}".godot-cpp
        ];
      };
      # dev-shell
      devShells."${system}".default = with pkgs; mkShell { };
    };
}
