# Godot-Flake
## Godot
godot is a cross-platform open-source game engine written in C++ 
[godot website](godotengine.org/)
[godot github](https://github.com/godotengine)

## This flake
this flakes helps project building the godot engine and the C++ bindings to write extensions

## How To run
to build , run 
```
nix build
```
to run godot :
```
nix run .#godot-editor
```
to update the godot version
```
nix flake update
```

## Github Action

Build, cache and update flake with cachix : ![flake update](https://github.com/MadMcCrow/Godot-flake/.github/workflows/flake-update.yml/badge.svg)

## TODO :

 - [X] Build extensions
 - [ ] Regroup Godot and it's templates as a single derivation
 - [X] Expose functions for other flakes 
 - [ ] Add Darwin (MacOS) support
 - [ ] Build against a specific nixpkgs
