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
    in rec {

      # build functions :
      lib = {
        buildGodot = import ./godot.nix { inherit lib pkgs system inputs; };
        buildGdExt = import ./extensions.nix { inherit lib pkgs system inputs; };
      };

      #interface
      packages."${system}" = with pkgs; {

        # godot engine
        godot-editor = lib.buildGodot.mkGodot { }; # Godot Editor
        godot-template-release = lib.buildGodot.mkGodotTemplate { target = "template_release"; };
        godot-template-debug   = lib.buildGodot.mkGodotTemplate { target = "template_debug"; };

        godot-cpp-editor = buildGdExt.mkGodotCPP { target = "editor"; };

        # extension demo
        godot-cpp-demo = buildGdExt.buildExt { 
          extName = "godot-cpp-demo";
          src = "${inputs.godot-cpp}/test";
        };

        # all packages are build
        default = pkgs.linkFarmFromDrvs "godot-flake" [
          # godot and its templates
          packages."${system}".godot-editor
          packages."${system}".godot-template-release
          packages."${system}".godot-template-debug

          # godot-cpp
          packages."${system}".godot-cpp-editor

          # demo to prove we can build gd-extensions
          packages."${system}".godot-cpp-demo
        ];
      };
      # dev-shell
      devShells."${system}".default = with pkgs; mkShell { };
    };
}
