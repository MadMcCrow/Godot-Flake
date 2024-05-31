# darwin.nix
# MacOS build Attributes
{ pkgs, options, version, inputs, ... }: defaultAtts :
let
  inherit (pkgs.lib.lists) optionals remove;
  inherit (pkgs.lib.strings) concatMapStrings;

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

  apple_frameworks = with pkgs.darwin.apple_sdk.frameworks;
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
    ];
    apple_framework_ccflags = builtins.concatStringsSep " " (map (x: "-iframework${x}/System/Library/Frameworks") apple_frameworks);
  # all apple packages :
  apple_pkgs = with pkgs.darwin;
  [
    libobjc
    apple_sdk.xcodebuild
    apple_sdk.MacOSX-SDK
  ] ++ apple_frameworks;

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
    "verbose=yes"
  ]
  # append all options (except no llvm)
    ++ remove "use_llvm=no"
    (map (x: "${x}=${options."${x}"}") (builtins.attrNames options));
  
  patches = [./patches/apple_sdk.patch];
  # pass values that have whitespaces in them
  postPatch = with pkgs.darwin.apple_sdk.frameworks; ''
  substituteInPlace ./platform/macos/detect.py \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/AppKit         -iframework${AppKit}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/Foundation     -iframework${Foundation}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/CoreFoundation -iframework${CoreFoundation}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/Cocoa          -iframework${Cocoa}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/Carbon         -iframework${Carbon}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/AudioUnit      -iframework${AudioUnit}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/CoreAudio      -iframework${CoreAudio}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/CoreMIDI       -iframework${CoreMIDI}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/IOKit          -iframework${IOKit}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/GameController -iframework${GameController}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/CoreHaptics    -iframework${CoreHaptics}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/CoreVideo      -iframework${CoreVideo}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/AVFoundation   -iframework${AVFoundation}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/CoreMedia      -iframework${CoreMedia}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/QuartzCore     -iframework${QuartzCore}/Library/Frameworks \
  --replace -iframework{MACOS_SDK_PATH}/System/Library/Security       -iframework${Security}/Library/Frameworks
  '';

  # requirements to" "-iframework${de}/System/Library/Framework" build godot on MacOS
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
