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
  runtimeDependencies =  godotLibraries.runtimeDep;

in rec {

  #
  #  Godot-cpp bindings : they are required to
  #  valid values for target are: ('editor', 'template_release', 'template_debug'
  #
  mkGodotCPP = { pname ? "godot-cpp", target ? "editor", ... }:
    stdenv.mkDerivation {
      # make name:
      name = (lib.strings.concatStringsSep "-" [pname target godotVersion.version]);
      version = godotVersion.version;
      src = inputs.godot-cpp;
      nativeBuildInputs = nativeBuildInputs;
      buildInputs = buildInputs;
      runtimeDependencies = runtimeDependencies;
      # scons flags list 
      sconsFlags = [ ("platfom=" + godotVersion.platform) ("target=" + target) ]
        ++ godotCustom.customSconsFlags;

      enableParallelBuilding = true;

      # fix path for g++
      patches = [
        ./patches/godot-cpp.patch # fix x11 libs
      ];
     
      # produces "./result/godot-cpp-4.0/[bin gen src ...]
      # todo : split outputs to only get what you need
      installPhase = ''
        ls -la ./ >> $out/folders
        cp -r src $out/src
        cp -r bin $out/bin
        cp -r gen $out/gen
        cp -r SConstruct $out/
        cp -r binding_generator.py $out/
        cp -r gdextension $out/
        cp -r tools $out/
      '';
    };

  # function to build any GD-extension
  buildExt = { extName, version ? "0.1", src, target ? "editor", ...}:
   let
    godot-cpp = mkGodotCPP{target = target; };
   in 
    stdenv.mkDerivation {
      pname =  extName + target;
      version = version;
      src = src;
      nativeBuildInputs = nativeBuildInputs  ++ [godot-cpp];
      buildInputs = buildInputs;
      runtimeDependencies = runtimeDependencies;
      sconsFlags = [("target=" + target)];
      enableParallelBuilding = true;
      patchPhase = ''
        substituteInPlace SConstruct --replace 'env = SConscript("../SConstruct")' 'env = SConscript("${godot-cpp}/SConstruct")'
        echo "${godot-cpp}"
      '';
    };
}
