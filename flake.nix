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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  };

  outputs = { self, nixpkgs, ... }@inputs:
    let

      # only linux supported for now
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # helper to build for multiple system
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
      forAllSystemPkgs = f:
        forAllSystems (system: f (nixpkgs.legacyPackages.${system}));

      # function to gen godot :
      mkLib = pkgs: {
        mkGodot = args: import ./godot.nix { inherit pkgs inputs; } args;
        mkGdext = args: import ./extension.nix pkgs args;
        mkExport = args: import ./export.nix pkgs args;
      };

    in {

      # add build functions
      lib = forAllSystemPkgs mkLib;

      # template for godot projects :
      templates = {
        default = {
          path = ./template;
          description = "A simple Godot-Flake project";
          welcomeText = "";
        };
      };

      # pre-defined godot engine 
      packages = forAllSystemPkgs (pkgs:
        let all = (mkLib pkgs).mkGodot { };
        in all // { default = all.godot; });

      # shell is just unputs for building godot from source
      devShells = forAllSystemPkgs
        (pkgs: { default = ((mkLib pkgs).mkGodot { }).shell; });

      # Check that everything builds correctly
      checks = forAllSystemPkgs (pkgs:
        let
          lib = mkLib pkgs;
          godot = lib.mkGodot { };
        in {
          inherit (godot) godot-editor;
          extension = lib.mkGdext {
            godot-cpp = godot.godot-cpp;
            src = "${inputs.godot-cpp}/test";
            name = "godot-cpp-test";
          };
        });
    };
}
