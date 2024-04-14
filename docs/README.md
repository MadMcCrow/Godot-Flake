# Godot-Flake [![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)
## Godot
godot is a cross-platform open-source game engine written in C++ 
[godot website](godotengine.org/)
[godot github](https://github.com/godotengine)

## Flake
see [Nixos Wiki](https://nixos.wiki/wiki/Flakes), [Nixos Manual](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html).

This project exist to help bootstrap development of godot projects with CI and multiplatform support.

supported systems are `x86_64-linux` and `aarch64-linux`. `aarch64-darwin` is not supported yet.

## Usage

### Build, Run directly
```
nix build   # will build godot and it's export templates
nix run     # will start the godot editor
```

### Use in your Flakes

You can use our [template](./template/flake.nix), or add to `flake.nix` :
```nix
{
    inputs.godot-flake = {
        url = "github:MadMcCrow/godot-flake";
        inputs.nixpkgs.follows = "nixpkgs";
    };
}
```
Now you can use :
```nix
{
    system = "x86_64-linux";
    godotPackages = inputs.godot-flake.packages."${system}";
    libGodot = inputs.godot-flake.lib."${system}";
    # you can access the default godot editor like this :
    godot = inputs.godot-flake.packages."${system}".godot-editor;
    # you can build it with your options :
    my-godot = libGodot.mkGodot {name = "my-godot"; options = { }; withTemplates = false;};
    my-editor = my-godot.godot-editor;
    # you can also build extensions :
    my-Ext =  libGodot.mkGdext {
            godot-cpp = my-godot.godot-cpp;
            src = "src";
            name = "my-GDextension";
          };
}
```

## Github Action

Build, cache and update flake with cachix : ![main](https://github.com/MadMcCrow/Godot-flake/.github/workflows/main.yml/badge.svg)
