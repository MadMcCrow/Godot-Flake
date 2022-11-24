#
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
  outputs = { self, nixpkgs, godot, godot-cpp, ... }@inputs:
    let
      # this builds godot 4. we should instead read it from the input file
      version = "4.0-beta";
      # only linux supported, todo, support darwin
      system = "x86_64-linux";
      # use nixpkgs
      pkgs = import nixpkgs { inherit system; };
      # libraries to run godot 4.
      libs = with pkgs; [
        libGL
        vulkan-loader
        xorg.libX11
        xorg.libXcursor
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
        xorg.libXi
        xorg.libXext
        xorg.libXfixes
        udev
        systemd
        systemd.dev
        libpulseaudio
        freetype
        openssl
        alsa-lib
        libGLU
        zlib
        yasm
      ];

      # build tools
      buildTools = with pkgs; [ scons pkg-config autoPatchelfHook bashInteractive patchelf gcc clang];
      # scons flags
      flags =  "platform=linux";

  # implementation
  in rec {

      #interface

      packages."${system}" = with pkgs; {

        # Godot Editor
        godot = stdenv.mkDerivation {
          pname = "godot";
          version = version; # builtins.readFile(input.godot + "./version.py");
          src = inputs.godot;
          # As a rule of thumb: Buildtools as nativeBuildInputs,
          # libraries and executables you only need after the build as buildInputs
          nativeBuildInputs = buildTools ++ libs;
          buildInputs = libs;
          enableParallelBuilding = true;
          sconsFlags = flags;
          runtimeDependencies = with pkgs; [ vulkan-loader libpulseaudio ];
          patchPhase = ''
            substituteInPlace platform/linuxbsd/detect.py --replace 'pkg-config xi ' 'pkg-config xi xfixes '
          '';
          installPhase = ''
            mkdir -p "$out/bin"
            cp bin/godot.* $out/bin/godot
          '';
        };

        # release template
        # todo : install to a place we can use for export
        godot-template-release = packages."${system}".godot.overrideAttrs (old: {
          pname = "godot-template-release";
          sconsFlags = flags + " tools=no target=template_release";
          installPhase = ''
            mkdir -p "$out/bin"
            cp bin/* $out/bin/
          '';
        });

        # debug templates
        # todo : install to a place we can use for export
        godot-template-debug = packages."${system}".godot.overrideAttrs (old: {
          pname = "godot-template-debug";
          sconsFlags = flags + " tools=no target=template_debug";
          installPhase = ''
            mkdir -p "$out/bin"
            cp bin/* $out/bin/
          '';
        });

        # Bindings for GD Extension
        # maybe use : pkgs.buildFHSUserEnv
          godot-cpp = stdenv.mkDerivation {
          pname = "godot-cpp";
          version = version;
          src = inputs.godot-cpp;
          nativeBuildInputs = buildTools ++ libs;
          buildInputs = libs;
          sconsFlags = flags;
          enableParallelBuilding = true;
          patchPhase = ''
            substituteInPlace SConstruct --replace 'env = Environment(tools=["default"])' 'env = Environment(tools=["default"], ENV={"PATH" : os.environ["PATH"]})'
          '';
          # produces "./result/godot-cpp-4.0/[bin gen src ...]
          installPhase = ''
            cp -r src $out/src
            cp -r bin $out/bin
            cp -r gen $out/gen
            cp -r SConstruct $out/
            cp -r binding_generator.py $out/
            cp -r tools $out/
            cp -r godot-headers $out/
          '';
          # note : there might be a smarter way to do this
        };


      godot-rust = stdenv.mkDerivation {
          pname = "godot-rust";
          version = version;
          src = inputs.godot-rust;
          nativeBuildInputs = buildTools ++ libs;
          buildInputs = libs ++ (with pkgs;[
            cargo
            rustc 
          ]);
          enableParallelBuilding = true;
      };

	    default = pkgs.linkFarmFromDrvs "godot" [
        packages."${system}".godot
        packages."${system}".godot-cpp
        packages."${system}".godot-template-release
        packages."${system}".godot-template-debug
        ];
      };

      devShells."${system}".default = with pkgs;
        mkShell {
          nativeBuildInputs = buildTools;
          runtimeDependencies = libs;
        };

    };
}
