# extension.nix
# this modules focuses on building cool extensions for godot
{ pkgs, system, inputs, options ? { } }:
with pkgs;
with builtins;
let
  # get libs
  lib = pkgs.lib;

  godotVersion = import ./version.nix { inherit system; };
  godotCustom = import ./custom.nix { inherit lib; };
  godotLibraries = import ./libs.nix { inherit pkgs; };

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
  mkGodotCPP = { target ? "editor", options ? {}, ... }:
    let
    version = godotVersion.version;
    platform = godotVersion.platform;
    # get libs for options :
    nativeBuildInputs = godotLibraries.mkNativeBuildInputs options;
    runtimeDependencies = godotLibraries.mkRuntimeDependencies options;
    buildInputs = godotLibraries.mkBuildInputs options;
    sconsFlags = godotCustom.mkSconsFlags options;
    in
    stdenv.mkDerivation ({
      inherit nativeBuildInputs runtimeDependencies buildInputs;
      # make name:
      name = (concatStringsSep "-" [ "godot-cpp" target godotVersion.version ]);
      version = godotVersion.version;
      src = inputs.godot-cpp;
      # patch
      patches = [
        ./patches/godot-cpp.patch # fix path for g++
      ];
      # build flags 
      sconsFlags = [
        ("platfom=" + godotVersion.platform)
        ("target=" + target)
        "generate_bindings=true"
      ] ++ sconsFlags;
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
  mkGDExt = args@{ extName, src,  target ? "editor", options ? {}, ... }:
    let
      godotcpp = mkGodotCPP { inherit target options; };
      nativeBuildInputs = godotLibraries.mkNativeBuildInputs options;
      runtimeDependencies = godotLibraries.mkRuntimeDependencies options;
      buildInputs = godotLibraries.mkBuildInputs options;
      sconsFlags = godotCustom.mkSconsFlags options;
      condList   = name : condAttr name args [];
      condString = name : condAttr name args "";
    in 
    stdenv.mkDerivation (args // {
      inherit src;
      # TODO : should we allow custom name ?
      pname = extName + target;
      version = condAttr "version" args godotVersion.version;
      nativeBuildInputs = nativeBuildInputs ++ [ godotcpp ] ++ (condList "nativeBuildInputs");
      buildInputs = buildInputs ++ (condList "buildInputs");
      runtimeDependencies = runtimeDependencies ++ (condList "runtimeDependencies");

      # patchPhase
      patchPhase = (prepExtension godotcpp) + "\n"
        + (condString "patchPhase");

      # buildPhase
      sconsFlags = [ ("platfom=" + godotVersion.platform) ("target=" + target) ]
        ++ sconsFlags ++ (condList "sconsFlags");

      # you may want to override
      enableParallelBuilding = condAttr "enableParallelBuilding" args true;

      #installPhase : override defaults !
      installPhase = condAttr "installPhase" args ''
        mkdir -p $out
        ls -la > $out/files.txt
      '';
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
