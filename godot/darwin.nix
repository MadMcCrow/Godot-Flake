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

  apple-sdk = with pkgs.darwin.apple_sdk;
  # every framework listed in detect.py 
    [
      MacOSX-SDK
      frameworks.AppKit
      frameworks.Foundation
      frameworks.Cocoa
      frameworks.Carbon
      frameworks.AudioUnit
      frameworks.CoreAudio
      frameworks.CoreMIDI
      frameworks.IOKit
      frameworks.GameController
      frameworks.CoreHaptics
      frameworks.CoreVideo
      frameworks.AVFoundation
      frameworks.CoreMedia
      frameworks.QuartzCore
      frameworks.Security
    ];

  # build 
in pkgs.stdenv.mkDerivation rec {
  # basic stuff :
  pname = "godot";
  inherit version;
  src = inputs.godot;
  sandbox = true;
  # build flags :
  sconsFlags = [
    "platform=macos"
    "use_llvm=yes"
  ]
  # append all options (except no llvm)
    ++ remove "use_llvm=no"
    (map (x: "${x}=${options."${x}"}") (builtins.attrNames options));

  # requirements to build godot on MacOS
  nativeBuildInputs = apple-sdk ++ (with pkgs; [
    scons
    pkg-config
    installShellFiles
    bashInteractive
    darwin.libobjc
    darwin.objc4
    xcbuild
    xcodebuild
    llvm
    lld
    clang
    clangStdenv
    llvmPackages.libcxxClang
    llvmPackages.clangUseLLVM
  ])
  # static vulkan if no Volk
    ++ (optionals (hasOptions "use_vulkan" && !hasOptions "use_volk")
      (with pkgs.pkgsStatic; [ mvk mvk.dev ])) ++ buildInputs;

  buildInputs = apple-sdk ++ [ pkgs.zlib pkgs.yasm ] ++ runtimeDependencies;

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
    ls -la
    ffrefrf
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
