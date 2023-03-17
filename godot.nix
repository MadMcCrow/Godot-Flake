# Godot.nix
# this modules focuses on building godot
# TODO : Add support for a custom.py
{ lib, pkgs, inputs, system }:
with pkgs;
let

  # godot version
  godotVersion = import ./version.nix { inherit system; };
  # godot custom.py
  godotCustom = import ./custom.nix { inherit lib system; };
  # godot build libraries
  godotLibraries = import ./libs.nix {
    inherit pkgs;
    use_x11 = true;
    use_mono = false;
  };

  # implementation
in rec {
  # mkGodot
  # function to male a godot build
  mkGodot = { name ? "godot", target ? "editor", tools ? true, ... }:
    stdenv.mkDerivation {
      # use variables from args
      pname = name;
      src = inputs.godot;

      # get godot version from version modules
      version = godotVersion.version;
      platform = godotVersion.platform;

      # As a rule of thumb: Buildtools as nativeBuildInputs,
      # libraries and executables you only need after the build as buildInputs
      nativeBuildInputs = godotLibraries.buildDep ++ godotLibraries.buildTools;
      buildInputs = godotLibraries.runtimeDep;
      runtimeDependencies = godotLibraries.runtimeDep;
      enableParallelBuilding = true;

      # scons flags list 
      sconsFlags = [
        ("platfom=" + godotVersion.platform)
        ("target=" + target)
        (if tools then "tools=yes" else "tools=no")
        ("use_sowrap=false") # make sure to link to system libraries
        ("use_volk=false") # Get vulkan via system libraries
      ] ++ godotCustom.customSconsFlags;

      # apply the necessary patches
      patches = [
        ./patches/xfixes.patch # fix x11 libs
        ./patches/gl.patch # fix gl libs
      ];

      installPhase = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot
        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
        substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
        GODOT4_BIN=out/bin/godot
      '';

      # some extra info
      meta = with lib; {
        homepage = pkgs.godot.meta.homepage;
        description = pkgs.godot.meta.description;
        license = licenses.mit;
      };
    };

  # build a template
  mkGodotTemplate = { ... }:
    mkGodot {
      pname = "godot-template" + target;
      tools = false;
      installPhase = ''
        mkdir -p "$out/share/godot/templates/${oldAttrs.version}.stable"
        cp bin/godot.x11.opt.64 $out/share/godot/templates/${oldAttrs.version}.stable/linux_x11_64_${target}
      '';
      # https://docs.godotengine.org/en/stable/development/compiling/optimizing_for_size.html
      strip = (oldAttrs.stripAllList or [ ]) ++ [ "share/godot/templates" ];
    };
}
