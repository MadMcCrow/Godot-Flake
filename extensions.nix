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

in rec{
  #
  #  Godot-cpp bindings : they are required to
  #  valid values for target are: ('editor', 'template_release', 'template_debug'
  #
  mkGodotCPP =  args @ {target, ...} : stdenv.mkDerivation ({
      # make name:
      name = (lib.strings.concatStringsSep "-" ["godot-cpp" target godotVersion.version]);
      version = godotVersion.version;
      src = inputs.godot-cpp;
      # dependancies
      nativeBuildInputs = godotLibraries.buildTools ++ godotLibraries.buildDep;
      buildInputs = godotLibraries.runtimeDep;
      runtimeDependencies = godotLibraries.runtimeDep;
      # patch
      patches = [
        ./patches/godot-cpp.patch       # fix path for g++ 
      ];
      # build flags 
      sconsFlags = [ ("platfom=" + godotVersion.platform) ("target=" + target) "generate_bindings=true"] ++ godotCustom.customSconsFlags;
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
      '';
    } // args);


  # function to build any GD-extension
  buildExt = args @ { extName, version ? "0.1", src, target ? "editor", ... }:
  let
    # godot bindings for that extension
    godotcpp = mkGodotCPP{inherit target;};
  in
    stdenv.mkDerivation ({
      pname = extName + target;
      version = version;
      src = src;
      nativeBuildInputs = nativeBuildInputs ++ [ godotcpp ];
      buildInputs = buildInputs;
      runtimeDependencies = runtimeDependencies;
      
      # use Sconstruct from godotcpp
      patchPhase = ''
        substituteInPlace SConstruct --replace 'env = SConscript("../SConstruct")' 'env = SConscript("${godotcpp}/SConstruct")'
      '';

      sconsFlags = [ ("platfom=" + godotVersion.platform) ("target=" + target) "generate_bindings=true"] ++ godotCustom.customSconsFlags;
      dontConfigure = true;
      enableParallelBuilding = true;
     
      installPhase = ''
       
        mkdir $out
        ls -la > $out/files.txt
      '';
      dontFixup = true;
    } // args);
}
