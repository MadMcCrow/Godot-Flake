# Godot-Flake
## Godot
godot is a cross-platform open-source game engine written in C++ 
[godot website](godotengine.org/)
[godot github](https://github.com/godotengine)

## Flake
[Nixos Wiki](https://nixos.wiki/wiki/Flakes)
[Nixos Manual](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html)

    Flakes are the unit for packaging Nix code in a reproducible and discoverable way. They can have dependencies on other flakes, making it possible to have multi-repository Nix projects.
    this flakes helps project building the godot engine and the C++ bindings to write extensions.

In our case we expose functions and packages to build, develop and run Godot and any related Extensions ([GDExtensions](https://godotengine.org/article/introducing-gd-extensions/))

## Usage

### Build, Run directly
```
nix build   # will build godot and it's export templates
nix run     # will start the godot editor
```

### Use in your Flakes

Add to `flake.nix` :
```nix
{
    inputs.godot-flake.url = "github:MadMcCrow/godot-flake";
}
```
Now you can use :
```nix
{
    system = "x86_64-linux";
    pkgGodot = inputs.godot-flake.packages."${system}";
    libGodot = inputs.godot-flake.lib;
    # you can access the default godot editor like this :
    godot = pkgGodot.godot-engine;
    # you can build it with your options : 
    godot = libGodot.mkGodot {pname = "my-godot-engine"; options = { }; withTemplates = false;};
    # you can also build extensions :
    myExt = buildGdExt.buildExt { extName = "myGDExtension"; src = self; target = "editor"; };
}
```

## Github Action

Build, cache and update flake with cachix : ![main](https://github.com/MadMcCrow/Godot-flake/.github/workflows/main.yml/badge.svg)

## TODO :

 - [X] Build extensions
 - [X] Regroup Godot and it's templates as a single derivation
 - [X] Expose functions for other flakes
 - [X] Build against a specific nixpkgs
 - [ ] Working Github Action
 - [ ] Add Darwin (MacOS) support via flake-utils
