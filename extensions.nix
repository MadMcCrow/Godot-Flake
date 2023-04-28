# extension.nix
# this modules focuses on building cool extensions for godot
{ pkgs, system, inputs, options ? { } }:
with pkgs;
with builtins;
let
  # get libs
  lib = pkgs.lib;

  # godot version infos
  godotVersion = import ./version.nix { inherit system; };
  # godot custom.py
  godotCustom = import ./custom.nix { inherit pkgs system options; };
  # godot build libraries
  godotLibraries = import ./libs.nix { inherit pkgs system options; };

  condAttr = name: set: default:
    if hasAttr name set then getAttr name set else default;

  ## copy prebuilt godot-cpp to then build against it
  ## there might be a smarter way to do this (only copy folder structure, link the rest)
  ## use Sconstruct from godotcpp
  prepExtension = godotCppPkg: ''
    mkdir -p godot-cpp
    cp -r ${godotCppPkg}/* ./godot-cpp/
    chmod 777 -R godot-cpp
    substituteInPlace SConstruct --replace 'env = SConscript("../SConstruct")' 'env = SConscript("godot-cpp/SConstruct")'
  '';


  #
  #  Godot-cpp bindings : they are required to
  #  valid values for target are: ('editor', 'template_release', 'template_debug'
  #
  mkGodotCPP = { target ? "editor", ... }:
    stdenv.mkDerivation ({
      # make name:
      name = (concatStringsSep "-" [ "godot-cpp" target godotVersion.version ]);
      version = godotVersion.version;
      src = inputs.godot-cpp;
      # dependancies
      nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep;
      buildInputs = godotLibraries.runtimeDep;
      runtimeDependencies = godotLibraries.runtimeDep;
      # patch
      patches = [
        ./patches/godot-cpp.patch # fix path for g++
      ];
      # build flags 
      sconsFlags = [
        ("platfom=" + godotVersion.platform)
        ("target=" + target)
        "generate_bindings=true"
      ] ++ godotCustom.customSconsFlags;
      # maybe split outputs ["SConstruct" "binding_generator" ... ]
      outputs = [ "out" ];
      installPhase = ''
        mkdir -p $out
        cp -r src $out/src
        cp -r SConstruct $out/
        cp -r binding_generator.py $out/
        cp -r gdextension $out/
        cp -r include $out/
        cp -r tools $out/
        cp -r gen $out/
        chmod 755 $out -R
        chmod 755 $out/gen/include/godot_cpp/core/ext_wrappers.gen.inc
      '';
    });

in {

  inherit mkGodotCPP;

  # function to build any GD-extension
  buildExt = args@{ extName, target ? "editor", ... }:
    let
      # godot bindings for that extension
      godotcpp = mkGodotCPP { inherit target; };
    in stdenv.mkDerivation (args // {
      # TODO : should we allow custom name ?
      pname = extName + target;
      version = condAttr "version" args godotVersion.version;
      nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep
        ++ [ godotcpp ] ++ (condAttr "nativeBuildInputs" args [ ]);
      buildInputs = godotLibraries.runtimeDep
        ++ (condAttr "buildInputs" args [ ]);
      runtimeDependencies = godotLibraries.runtimeDep
        ++ (condAttr "runtimeDependencies" args [ ]);

      # patchPhase
      patchPhase = (prepExtension godotcpp) + "\n"
        + (condAttr "patchPhase" args "");

      # buildPhase
      sconsFlags = [ ("platfom=" + godotVersion.platform) ("target=" + target) ]
        ++ godotCustom.customSconsFlags ++ (condAttr "sconsFlags" args [ ]);
      enableParallelBuilding = condAttr "enableParallelBuilding" args true;

      #installPhase
      installPhase = ''
        mkdir -p $out
        ls -la > $out/files.txt
      '' + (condAttr "installPhase" args "");
    });

  # Make a shell to develop extension
  mkExtensionShell = extPkg:
    let godot-cpp = mkGodotCPP { target = condAttr "target" extPkg "editor"; };
    in mkShell {
      packages = [ breakpointHook cntr ] ++ condAttr "nativeBuildInputs" extPkg [];
      inputsFrom = [ extPkg ];
      src = extPkg.src;
      shellHook = ''
      unpackPhase
      cd source
      '' + prepExtension godot-cpp;
    };
}
