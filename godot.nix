# Godot.nix
# this modules focuses on building godot
{ pkgs, inputs, system}:
with pkgs;
with builtins;
let
  lib = pkgs.lib;

  godotVersion = import ./version.nix { inherit system; };
  godotCustom = import ./custom.nix { inherit lib; };
  godotLibraries = import ./libs.nix { inherit pkgs; };

  # Do not set GODOT4_BIN=out/bin/godot-${target} because we may build templates toos
  mkInstallPhase = {pname, version, platform, target} :
    let
      isEditor = (target == "editor");
      editorInstallPhase = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/${pname}
        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
        substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
      '';
      templateInstallPhase = ''
        mkdir -p "$out/share/godot/templates/${version}"
        cp bin/godot.* $out/share/godot/templates/${version}/${platform}-${target}
      '';
    in (if isEditor then editorInstallPhase else templateInstallPhase);

  # function to make attributes to pass to mkDerivation
  mkGodotAttrs = { pname, target, options ? {} }: 
  let
    version = godotVersion.version;
    platform = godotVersion.platform;
    # get libs for options :
    nativeBuildInputs = godotLibraries.mkNativeBuildInputs options;
    runtimeDependencies = godotLibraries.mkRuntimeDependencies options;
    buildInputs = godotLibraries.mkBuildInputs options;
  in
  {
    inherit platform version nativeBuildInputs buildInputs runtimeDependencies;
    name = (concatStringsSep "-" [ pname target version ]);
    src = inputs.godot;

    installPhase = mkInstallPhase {inherit pname version platform target;};
    enableParallelBuilding = true;

    # scons flags list 
    sconsFlags = [
      ("platfom=" + godotVersion.platform)
      ("target=" + target)
      (if target == "editor" then "tools=yes" else "tools=no")
    ] ++ godotCustom.mkSconsFlags options;

    # apply the necessary patches
    patches = [
      ./patches/xfixes.patch # fix x11 libs
      ./patches/gl.patch # fix gl libs
    ];

    # some extra info
    meta = with lib; {
      homepage = pkgs.godot.meta.homepage;
      description = pkgs.godot.meta.description;
      license = licenses.mit;
    };
  };

  # implementation
in {

  # build godot
  mkGodot = { pname ? "godot-engine", options ? { }, withTemplates ? true}:
    let
      # helper function
      mkGodotDerivation = target : stdenv.mkDerivation (mkGodotAttrs { inherit pname target options; });
      # editor
      godot-editor = mkGodotDerivation "editor";
      # release template
      godot-release = mkGodotDerivation "template_release";
      # debug template
      godot-debug = mkGodotDerivation "template_debug";
    in pkgs.buildEnv {
      name = (concatStringsSep "-" [ pname godotVersion.version ]);
      paths = [ godot-editor ] ++ (if withTemplates then [ godot-release godot-debug] else []);
    };

  mkGodotShell = { pname ? "godot-engine", options ? { }, ...}:
    let
      # make the godot Attributes
      godotAttr = mkGodotAttrs {
        inherit pname options;
        target = "editor";
      };
      # get a list in a set by name
      condList = n: s: if hasAttr n s then getAttr n s else [ ];
    in mkShell {
      packages = [ breakpointHook cntr ]
        ++ (condList "nativeBuildInputs" godotAttr)
        ++ (condList "buildInputs" godotAttr)
        ++ (condList "runtimeDependencies" godotAttr);
      inputsFrom = [ (stdenv.mkDerivation godotAttr) ];
      src = godotAttr.src;
      shellHook = ''
        unpackPhase
        cd source
      '';
    };
}
