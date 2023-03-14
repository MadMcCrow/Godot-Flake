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


in rec {

  #
  #  Godot-cpp bindings : they are required to
  #  valid values for target are: ('editor', 'template_release', 'template_debug'
  #
  mkGodotCpp = {target ? "editor"} : stdenv.mkDerivation {
    pname = "godot-cpp";
    version = godotVersion.version;
    src = inputs.godot-cpp;
    nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep;
    buildInputs = godotLibraries.runtimeDep;
    runtimeDependencies = godotLibraries.runtimeDep;
     # scons flags list 
      sconsFlags = [
        ("platfom=" + godotVersion.platform)
        ("target=" + target)
      ] ++ godotCustom.customSconsFlags;

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
  };

  # TODO : build demo !
  demo = stdenv.mkDerivation {
    pname = "godot-cpp";
    version = godotVersion.version;
    src = inputs.godot-cpp.test;
    nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep ++ [godot-cpp];
    buildInputs = godotLibraries.runtimeDependencies;
    runtimeDependencies = godotLibraries.runtimeDependencies;
    sconsFlags = godotCustom.customSconsFlags;
    enableParallelBuilding = true;
    patchPhase = ''
      substituteInPlace SConstruct --replace 'env = Environment(tools=["default"])' 'env = Environment(tools=["default"], ENV={"PATH" : os.environ["PATH"]})'
    '';
    #todo : installPhase = '' '';
  };

  buildExt = {pname , version } : stdenv.mkDerivation
  {
    pname = "godot-cpp";
    version = godotVersion.version;
    src = inputs.godot-cpp;
    nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep ++ [godot-cpp];
    buildInputs = godotLibraries.runtimeDependencies;
    runtimeDependencies = godotLibraries.runtimeDependencies;
    sconsFlags = godotCustom.customSconsFlags;
    enableParallelBuilding = true;
  };

}
