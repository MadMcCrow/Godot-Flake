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
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    # flake utils to support multiple systems
    flake-utils = {
      url = "github:numtide/flake-utils";
      };

    # nixgl : A wrapper tool for nix OpenGL application 
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

  };

  outputs = { self, ... }@inputs:
    let
      # only x86_64-linux supported for now.
      system = "x86_64-linux";

      # import pkgs;
      pkgs = import inputs.nixpkgs { 
        inherit system;
        overlays = [ inputs.nixgl.overlay ];
      };

      importArgs = { inherit pkgs system inputs; };

      # helper function
      libGodot = import ./godot.nix importArgs;
      libGDExt = import ./extensions.nix importArgs;

      buildArgs = {
        # godot bin name :
        pname = "godot";

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

      # godot packages:
      godot-engine = libGodot.mkGodot buildArgs;

    in {

      # expose build functions :
      lib = { inherit libGodot libGDExt; };

      #packages
      packages."${system}" = with pkgs; {
        # expose build packages :
        inherit godot-engine;
        # default is godot engine
        default = godot-engine;
      };

      devShells."${system}".default = with pkgs;
        buildGodot.mkGodotShell buildArgs;
    };
}
