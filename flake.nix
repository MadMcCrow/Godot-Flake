{
  description = "the godot Engine, and the godot-cpp bindings for extensions";
  inputs = {
    godot = {
      url = "github:godotengine/godot";
      flake = false;
    };
    godot-cpp = {
      url = "github:godotengine/godot-cpp";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, godot, godot-cpp, ... }@inputs:
    let
      # only linux supported
      system = "x86_64-linux";
      # use nixpkgs
      pkgs = import nixpkgs { inherit system; };
      # libraries to run godot 4.
      libs = with pkgs; [
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

    in rec {
      packages."${system}" = with pkgs; {

        # Godot Itself
        godot = stdenv.mkDerivation {
          pname = "godot";
          version = "4.0";
          src = inputs.godot;
          # As a rule of thumb: Buildtools as nativeBuildInputs,
          # libraries and executables you only need after the build as buildInputs
          nativeBuildInputs = buildTools ++ libs;
          buildInputs = libs;
          # parallel building for faster compile
          enableParallelBuilding = true;
          # for now we only support linux
          sconsFlags = flags;
          runtimeDependencies = with pkgs; [ vulkan-loader libpulseaudio ];
          patchPhase = ''
            substituteInPlace platform/linuxbsd/detect.py --replace 'pkg-config xi ' 'pkg-config xi xfixes '
          '';

          # produces "./result/godot-4.0/godot.bin
          installPhase = ''
            mkdir -p "$out/bin"
            cp bin/godot.* $out/bin/godot
          '';
        };

        # Bindings for GD Extension
        # maybe use : pkgs.buildFHSUserEnv
          godot-cpp = stdenv.mkDerivation {
          pname = "godot-cpp";
          version = "4.0";
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

	default = pkgs.linkFarmFromDrvs "godot" [ packages."${system}".godot packages."${system}".godot-cpp ];
      };

      devShells."${system}".default = with pkgs;
        mkShell {
          nativeBuildInputs = buildTools;
          runtimeDependencies = libs;
        };

    };
}
