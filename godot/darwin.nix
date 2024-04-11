# darwin.nix
# MacOS build Attributes
{ pkgs, options, inputs }: 
let
  inherit (pkgs.lib.lists) optionals;

  # we cannot use pkgs.staticPkgs.darwin.moltenvk
  # as it fails to build
  mvk = pkgs.darwin.moltenvk;
  # we then must use volk to build godot binary 
  options.use_volk = true;

  CLibraries = let HeaderPath =  name:
  ''${pkgs.darwin.apple_sdk.frameworks."${name}"}/Library/Frameworks/${name}.framework/Versions/C/Headers/${name}.h'';
  in
  pkgs.stdenvNoCC.mkDerivation {
    name = "MacOS_SDK_CHeaders";
    phases = ["installPhase"];
    installPhase = map (x : ''
    mkdir -p $out/include/${x}
    cp -r ${HeaderPath x} $out/include/${x}/${x}.h
    '') ["AppKit"];
  };

  hasOptions = key: if (builtins.hasAttr key options) then options.${key} == "yes" else false;

  # vulkan support is moltenvk
  vk = optionals (hasOptions "use_vulkan") [
    mvk
    mvk.dev
  ];

  # OpenGL libraries
  ogl = optionals (hasOptions "use_OpenGL") (with pkgs; [
    glslang
    libGLU
    libGL
  ]);

  # mono/C#
  # TODO : test what version of mono/dotnet is required
  mono = optionals ( hasOptions "use_mono") 
  (with pkgs; [ mono6 msbuild dotnetPackages.Nuget ]);

  # llvm compiler
  libllvm = optionals ( hasOptions "use_llvm")
   (with pkgs; [
    llvm
    lld
    clang
    clangStdenv
    llvmPackages.libcxxClang
    llvmPackages.clangUseLLVM
  ]);

  # absolutely needed libs for runtime
  libRuntime = with pkgs; [
    freetype
    openssl
    fontconfig.lib
    libxkbcommon
  ];

  buildTools = with pkgs;
    [
      scons
      pkg-config
      installShellFiles
      bashInteractive
    ] ++ libllvm;


in {
  sconsFlags = [ "platform=macos" ];

 nativeBuildInputs = [pkgs.darwin.apple_sdk.MacOSX-SDK] ++
 # every framework listed in detect.py 
 (with pkgs.darwin.apple_sdk.frameworks; [
  AppKit
  Foundation
  Cocoa
  Carbon
  #AudioUnit
  #CoreAudio
  #CoreMIDI
  #IOKit
  #GameController
  #CoreHaptics
  #CoreVideo
  #AVFoundation
  #CoreMedia
  #QuartzCore
  #Security
  ]) ++
 (with pkgs; [xcbuild xcodebuild]) ++ buildTools
    ++ ogl ++ mono
    ++ vk;

  buildInputs = [ pkgs.zlib pkgs.yasm ] ++ mono
    ++ ogl 
    ++  vk;

  # runtime dependencies
  runtimeDependencies = libRuntime ++ mono ++ ogl
    ++ vk;

  installPhase = ''
  ls -la
  ffrefrf
  '';
}