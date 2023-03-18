# extension.nix
# this modules focuses on building cool extensions for godot
{ lib, pkgs, system, inputs }:
with pkgs;
let
  # godot version infos
  godotVersion = import ./version.nix { inherit system; };
  # godot custom.py
  godotCustom = import ./custom.nix { inherit lib system; };
  # godot build libraries
  godotLibraries = import ./libs.nix { inherit pkgs; };

  # dependancies
  nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep;
  buildInputs = godotLibraries.runtimeDep;
  runtimeDependencies = godotLibraries.runtimeDep;

  #
  #  Godot-cpp bindings : they are required to
  #  valid values for target are: ('editor', 'template_release', 'template_debug'
  #
  godotCPP = stdenv.mkDerivation {
      # make name:
      name = (lib.strings.concatStringsSep "-" ["godot-cpp" godotVersion.version]);
      version = godotVersion.version;
      src = inputs.godot-cpp;
      dontBuild = true;
      # fix path for g++ 
      patches = [
        ./patches/godot-cpp.patch
      ];
      # maybe split outputs ["SConstruct" "binding_generator" ... ]
      outputs = [ "out" ];
      installPhase = ''
      ls -la
      cp -r src $out/src
      cp -r bin $out/bin
      cp -r gen $out/gen
      cp -r SConstruct $out/
      cp -r binding_generator.py $out/
      cp -r gdextension $out/
      cp -r tools $out/
      '';
    };

in {

  # function to build any GD-extension
  buildExt = args @ { extName, version ? "0.1", src, target ? "editor", ... }:
    stdenv.mkDerivation ({
      pname = extName + target;
      version = version;
      src = src;
      nativeBuildInputs = nativeBuildInputs ++ [ godotCPP ];
      buildInputs = buildInputs;
      runtimeDependencies = runtimeDependencies;
      sconsFlags = [ ("platfom=" + godotVersion.platform) ("target=" + target) ]
        ++ godotCustom.customSconsFlags;
      enableParallelBuilding = true;
      patchPhase = ''
        substituteInPlace SConstruct --replace 'env = SConscript("../SConstruct")' 'env = SConscript("${godotCPP}/SConstruct")'
      '';
    } // args);
}
