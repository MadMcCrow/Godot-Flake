# darwin.nix
# MacOS build Attributes
{ pkgs, options, version, inputs, ... }:
let
  inherit (pkgs.lib.lists) optionals remove;

  # we cannot use pkgs.staticPkgs.darwin.moltenvk
  # as it fails to build
  mvk = pkgs.darwin.moltenvk;
  # we then must use volk to build godot binary 
  # TODO : options.use_volk = true;

  CLibraries = let
    HeaderPath = name:
      "${
        pkgs.darwin.apple_sdk.frameworks."${name}"
      }/Library/Frameworks/${name}.framework/Versions/C/Headers/${name}.h";
  in pkgs.stdenvNoCC.mkDerivation {
    name = "MacOS_SDK_CHeaders";
    phases = [ "installPhase" ];
    installPhase = map (x: ''
      mkdir -p $out/include/${x}
      cp -r ${HeaderPath x} $out/include/${x}/${x}.h
    '') [ "AppKit" ];
  };

  hasOptions = key:
    if (builtins.hasAttr key options) then options.${key} == "yes" else false;

  # mono/C#
  # TODO : test what version of mono/dotnet is required
  mono = optionals (hasOptions "use_mono")
    (with pkgs; [ mono6 msbuild dotnetPackages.Nuget ]);

  # all apple packages :
  apple_pkgs = with pkgs.darwin;
  [
    libobjc
    apple_sdk.xcodebuild
    apple_sdk.MacOSX-SDK
  ] ++
  (with pkgs.darwin.apple_sdk.frameworks;
  # every framework listed in detect.py 
    [
      AppKit
      Foundation
      Cocoa
      Carbon
      AudioUnit
      CoreAudio
      CoreMIDI
      IOKit
      GameController
      CoreHaptics
      CoreVideo
      AVFoundation
      CoreMedia
      QuartzCore
      Security
      OpenGL
    ]);

  # build 
in pkgs.darwin.apple_sdk.stdenv.mkDerivation rec {
  # basic stuff :
  pname = "godot";
  inherit version;
  src = inputs.godot;
  sandbox = false;
  # build flags :
  sconsFlags = [
    "platform=macos"
    "use_llvm=yes"
  ]
  # append all options (except no llvm)
    ++ remove "use_llvm=no"
    (map (x: "${x}=${options."${x}"}") (builtins.attrNames options));

  # requirements to build godot on MacOS
  nativeBuildInputs = apple_pkgs ++ (with pkgs; [
    scons
    pkg-config
    installShellFiles
    bashInteractive
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
  ])
  # static vulkan if no Volk
    ++ (optionals (hasOptions "use_vulkan" && !hasOptions "use_volk")
      (with pkgs.pkgsStatic; [ mvk mvk.dev ])) ++ buildInputs;

  buildInputs = apple_pkgs ++ [ pkgs.zlib pkgs.yasm ] ++ runtimeDependencies;

  NIX_LDFLAGS =  [ "-framework" "AppKit" ];


  # runtime dependencies
  runtimeDependencies = with pkgs;
    [
      freetype
      openssl
      fontconfig.lib
      libxkbcommon
    ]
    # open GL 
    ++ (optionals (hasOptions "use_OpenGL")
      (with pkgs; [ glslang libGLU libGL ]))
    # vulkan if not statically built
    ++ (optionals (hasOptions "use_vulkan" && hasOptions "use_volk")
      (with pkgs; [ mvk mvk.dev ]));

  installPhase = ''
    echo "TODO !"
    ls -la
    breakpointHook
  '';

  # meta is shared between systems
  meta = with pkgs.lib; {
    # TODO: add correct platform list
    platforms = [ pkgs.stdenv.system ];
    homepage = pkgs.godot_4.meta.homepage;
    description = pkgs.godot_4.meta.description;
    license = licenses.mit;
    mainProgram = "godot";
  };
}
