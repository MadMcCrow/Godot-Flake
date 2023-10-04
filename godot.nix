# Godot.nix
# this modules focuses on building godot
{ pkgs, inputs }:
# the "real" function inputs
{ name ? "godot", profile ? "", options ? { }, withTemplates ? true
, withBindings ? true, ... }:
with builtins;
let
  # shortcuts
  inherit (pkgs) lib stdenv stdenvNoCC system;

  # get the godot version with IFD
  version = let
    # get version file from godot itself
    godotVersionFile = stdenvNoCC.mkDerivation {
      src = inputs.godot;
      name = "godot-version";
      noBuildPhase = true;
      installPhase = ''
        mkdir -p "$out/"
        cp version.py $out/version.py
      '';
    };
    removeChars = l: str:
      lib.strings.stringAsChars (x: if (any (c: x == c) l) then "" else x) str;
    splitLine = lstr: (lib.strings.splitString "\n" lstr);
    removeEmpty = l: filter (x: x != "") l;
    hasAllAttrs = names: set: all (x: x) (map (a: hasAttr a set) names);
    mkPair = str:
      let split = (lib.strings.splitString " = " str);
      in lib.attrsets.nameValuePair (elemAt split 0) (elemAt split 1);
    godotVersionAttrs = builtins.listToAttrs (map mkPair (removeEmpty
      (map (removeChars [ "\n" ''"'' ])
        (splitLine (readFile "${godotVersionFile}/version.py")))));

    # build AttrSet
  in ({
    asString =
      "${godotVersionAttrs.major}.${godotVersionAttrs.minor}.${godotVersionAttrs.patch}-${godotVersionAttrs.status}";
  } // godotVersionAttrs);

  # default godot from nix (for meta)
  nix-godot = pkgs.godot_4;

  # x86_64-linux    -> linux
  # aarch64-linux   -> linux 
  # aarch64-darwin  -> darwin
  platform = let
    regex = "[\\w\\_\\-]*-([a-zA-Z]+)";
    getElem = x: elemAt (elemAt (x) 1) 0;
  in getElem (split regex system);

  # default options for building godot in production (.ie for using it) 
  defaultOptions = {
    optimize = "speed"; # default is "speed_trace"
    lto = "full"; # godot default is "none";
    production = true; # godot default is false
    use_volk = false; # godot default is true;
  };

  # get the option (to have correct libs)
  condGet = n: s: d: if hasAttr n s then getAttr n s else d;
  getOption = opt: def: condGet opt options (condGet opt defaultOptions def);

  # parse options :
  use_x11 = getOption "x11" true;
  use_llvm = getOption "llvm" false;
  use_openGL = getOption "opengl3" true;
  use_vulkan = getOption "vulkan" true;
  use_mono = getOption "module_mono_enabled" false;

  condLib = c: l: if c then l else [ ];

  # mono/C#
  # TODO : test what version of mono/dotnet is required
  libMono = with pkgs; [ mono6 msbuild dotnetPackages.Nuget ];

  # llvm compiler
  libllvm = with pkgs; [
    llvm
    lld
    clang
    clangStdenv
    llvmPackages.libcxxClang
    llvmPackages.clangUseLLVM
  ];

  # x11 libraries
  libXorg = with pkgs.xorg; [
    libX11
    libXcursor
    libXi
    libXinerama
    libXrandr
    libXrender
    libXext
    libXfixes
  ];

  libVulkan = with pkgs; [ vulkan-loader vulkan-headers vulkan-tools ];

  # OpenGL libraries
  libOpenGL = with pkgs; [
    glslang
    libGLU
    libGL
  ]; # ++ [pkgs.nixgl.auto.nixGLDefault];

  # absolutely needed libs for runtime
  libRuntime = with pkgs; [
    udev
    systemd
    systemd.dev
    libpulseaudio
    freetype
    openssl
    alsa-lib
    fontconfig.lib
    speechd
    libxkbcommon
    dbus.lib
  ];

  buildTools = with pkgs;
    [
      scons
      pkg-config
      installShellFiles
      autoPatchelfHook
      bashInteractive
      patchelf
      gcc
    ] ++ condLib use_llvm libllvm;

  # runtime dependencies
  runtimeDependencies = libRuntime ++ condLib use_x11 libXorg
    ++ condLib use_mono libMono ++ condLib use_openGL libOpenGL
    ++ condLib use_vulkan libVulkan;

  # As a rule of thumb: Buildtools as nativeBuildInputs,
  # libraries and executables you only need after the build as buildInputs
  nativeBuildInputs = buildTools ++ condLib use_x11 libXorg
    ++ condLib use_openGL libOpenGL ++ condLib use_mono libMono
    ++ condLib use_vulkan libVulkan;

  buildInputs = [ pkgs.zlib pkgs.yasm ] ++ condLib use_x11 libXorg
    ++ condLib use_openGL libOpenGL ++ condLib use_mono libMono
    ++ condLib use_vulkan libVulkan;

  # turn option set into scons options
  mkSconsOptions = optionSet:
    let
      condAttr = n: s: d: if hasAttr n s then getAttr n s else d;
      boolToString = cond: if cond then "yes" else "no";
    in (lib.mapAttrsToList (k: v:
      if (lib.isBool v) then
        ("${k}=${boolToString v}")
      else if (lib.isString v) then
        ("${k}=${v}")
      else
        "${k}=${toJSON v}") optionSet);

  # sconsFlags for everyone
  mkSconsFlags = target:
    [
      ("platform=${platform}")
      ("target=${target}")
      ("tools=${if target == "editor" then "yes" else "no"}")
    ] ++ (if (profile != "") then
      [ "profile=${profile}" ]
    else
      (mkSconsOptions options));

  # the editor
  godot-editor = stdenv.mkDerivation {
    inherit nativeBuildInputs buildInputs runtimeDependencies;
    pname = "${name}-editor";
    version = "${version.asString}";
    src = inputs.godot;
    # nixpkgs use Godot4 and godot4 instead of godot, so we replace
    installPhase = replaceStrings ["odot4"] ["odot"] nix-godot.installPhase;
    enableParallelBuilding = true;
    sconsFlags = mkSconsFlags "editor";
    # apply the necessary patches
    patches = [
      ./patches/xfixes.patch # fix x11 libs
      ./patches/gl.patch # fix gl libs
    ];
    # some extra info
    meta = with lib; {
      homepage = nix-godot.meta.homepage;
      description = nix-godot.meta.description;
      license = licenses.mit;
    };
  };

  # the templates
  mkTemplate = target:
    godot-editor.overrideAttrs (final: prev:
      (prev // {
        pname = "${name}-${target}";
        sconsFlags = mkSconsFlags target;
        installPhase = ''
          mkdir -p "$out/share/godot/templates/${prev.version}"
          cp bin/godot.* $out/share/godot/templates/${prev.version}/${platform}-${target}
        '';
      }));
  godot-debug = mkTemplate "template_debug";
  godot-release = mkTemplate "template_release";

  # Godot-cpp bindings
  godot-cpp = let target = "editor"; # no needs for other targets
  in stdenv.mkDerivation {
    inherit buildInputs runtimeDependencies;
    nativeBuildInputs = nativeBuildInputs ++ [godot-editor];
    # make name:
    name = "godot-cpp-${target}-${version.asString}";
    version = version.asString;
    src = inputs.godot-cpp;
    # this does not work, sadly
    # configurePhase = "${godot-editor}/bin/godot --dump-extension-api extension_api.json";
    # "custom_api_file=extension_api.json"

    # patch
    patches = [
      ./patches/godot-cpp.patch # fix path for g++
    ];
    # build flags 
    sconsFlags = [ "generate_bindings=true" "-s"] ++ godot-editor.sconsFlags;

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
  };

in {
  # build to needs 
  inherit godot-editor godot-debug godot-release godot-cpp;
  # inherit (build) nativeBuildInputs buildInputs runtimeDependencies;
  # full engine
  godot = pkgs.buildEnv {
    name = "${name}-${version.asString}";
    paths = [ godot-editor ]
      ++ (lib.optional withTemplates [ godot-release godot-debug ])
      ++ (lib.optional withBindings [ godot-cpp ]);
  };

  shell = pkgs.mkShell {
    # inputsFrom = [godot-editor]; 
    inherit nativeBuildInputs buildInputs;
  };
}
