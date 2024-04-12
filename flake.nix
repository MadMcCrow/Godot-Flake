# Godot is a cross-platform open-source game engine written in C++
# This flake build godot, the cpp bindings and the export templates
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
    # we're using the release branch for stability
    nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let

      # only linux supported for now
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      # helper to build for multiple system
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

    in rec {
      # template for godot projects :
      templates.default = {
        path = ./template;
        description = "A simple Godot-Flake project";
        welcomeText = "Start building your godot game Now !";
      };

      # pre-defined godot engine 
      packages = forAllSystems (system: rec {
        godot = (import ./godot {
          pkgs = nixpkgs.legacyPackages."${system}";
          inherit inputs;
        }).editor;
        default = godot;
      });

      # shell is just inputs for building godot from source
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages."${system}".mkShell {
          inputsFrom = [ packages."${system}".godot ];
          shellHook = "";
        };
      });

      # TODO :
      #checks = forAllSystemPkgs (pkgs:
    };
}
