# this flakes uses godot-flake
{
  description = "A game with Godot";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # the godot Engine
    godot-flake = {
      url = "github:MadMcCrow/godot-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, godot-flake, ... }@inputs:
    let
      # supported systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # default system-agnostic flake implementation :
      flake = system : let 
      # if you need pkgs : 
      # (godot-flake will use the ones in its inputs )
      # pkgs = import nixpkgs { inherit system; };
      # the functions from Godot-Flake
      godot-lib = godot-flake.lib."${system}";
      # the default Godot engine :
      engine = godot-lib.mkGodot {};
      # How to build a GDExtension :
      extension = godot-lib.mkGdext {
            godot-cpp = engine.godot-cpp;
            src = "src";
            name = "my-extension";
          };
      # How to export a godot project :
      my-project =  godot-lib.mkExport {
          godot = engine;
          src = self;
          name = "my-project";
          buildInputs = [my-extension];
      }; 
      in {
        # implement your flake here ;)
        packages."${system}" = {
          inherit my-project;
          default = my-project;
        };
      };
    
    # gen for all systems :
    in foldl' (x: y: godot-flake.inputs.nixpkgs.lib.recursiveUpdate x y) {} (map flake systems);
}