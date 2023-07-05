# extension.nix
# this modules focuses on building cool extensions for godot
args@{ pkgs, system, inputs }:
with pkgs;
with builtins;
let
  # get libs
  lib = pkgs.lib;

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
  mkGodotCPP = { target ? "editor", options ? { }, version ? "", ... }:
    let
      godotVersion = import ./version.nix { inherit pkgs version inputs; };
      godotPlatform = import ./platform.nix { inherit system; };
      # get libs for options :
      nativeBuildInputs = godotLibraries.mkNativeBuildInputs options;
      runtimeDependencies = godotLibraries.mkRuntimeDependencies options;
      buildInputs = godotLibraries.mkBuildInputs options;
      sconsFlags = godotCustom.mkSconsFlags options;
    in stdenv.mkDerivation ({
      inherit nativeBuildInputs runtimeDependencies buildInputs;
      # make name:
      name = "godot-cpp-${target}-${godotVersion.asString}";
      version =  godotVersion.asString;
      src = inputs.godot-cpp;
      # patch
      patches = [
        ./patches/godot-cpp.patch # fix path for g++
      ];
      # build flags 
      sconsFlags = [
        ("platform=" + godotPlatform)
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
  mkGDExt =
    args@{ extName, src, target ? "editor", options ? { }, version ? "", ... }:
    let
      godotcpp = mkGodotCPP { inherit target options; };
      godotVersion = import ./version.nix { inherit pkgs version inputs; };
      godotPlatform = import ./platform.nix { inherit system; };
      nativeBuildInputs = godotLibraries.mkNativeBuildInputs options;
      runtimeDependencies = godotLibraries.mkRuntimeDependencies options;
      buildInputs = godotLibraries.mkBuildInputs options;
      sconsFlags = godotCustom.mkSconsFlags options;
      condList = name: condAttr name args [ ];
      condString = name: condAttr name args "";
    in stdenv.mkDerivation (args // {
      inherit src;
      version =  godotVersion.asString;
      platform = godotPlatform;
      # TODO : should we allow custom name ?
      pname = extName + target;
      nativeBuildInputs = nativeBuildInputs ++ [ godotcpp ]
        ++ (condList "nativeBuildInputs");
      buildInputs = buildInputs ++ (condList "buildInputs");
      runtimeDependencies = runtimeDependencies
        ++ (condList "runtimeDependencies");

      # patchPhase
      patchPhase = (prepExtension godotcpp) + "\n" + (condString "patchPhase");

      # buildPhase
      sconsFlags = [ ("platform=" + godotPlatform) ("target=" + target) ]
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
      packages = [ breakpointHook cntr ]
        ++ condAttr "nativeBuildInputs" extPkg [ ];
      inputsFrom = [ extPkg ];
      src = extPkg.src;
      shellHook = ''
        unpackPhase
        cd source
      '' + prepExtension godot-cpp;
    };

     # Make a shell to develop extension
  mkGodotCPPShell = args @ { pname ? "godot-cpp", options ? { }, ... }:
    let
      godotVersion = import ./version.nix { inherit pkgs version inputs; };
      godotPlatform = import ./platform.nix { inherit system; };
      godot-cpp = mkGodotCPP args;
      sconsFlags = godotCustom.mkSconsFlags options;
      # get a list in a set by name
      condList = n: s: if hasAttr n s then getAttr n s else [ ];
    in mkShell {
      packages = [ breakpointHook cntr ]
        ++  godotLibraries.mkNativeBuildInputs options
        ++ godotLibraries.mkBuildInputs options
        ++  godotLibraries.mkRuntimeDependencies options;
      inputsFrom = [  godot-cpp  ];
      src = inputs.godot-cpp;
      shellHook = ''
        unpackPhase
        cd source
      '';
    };
}
