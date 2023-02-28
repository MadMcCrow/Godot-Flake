# libs.nix
# Godot libraries for build and runtime
{ pkgs, use_llvm ? true, use_x11 ? true, use_openGL ? true, ... }:
let
  # llvm compiler
  llvm = with pkgs; [ llvm lld clang ];
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
  # OpenGL libraries
  libOpenGL = with pkgs; [ glslang libGLU libGL ];

  buildTools = with pkgs;
    [
      scons
      pkg-config
      installShellFiles
      autoPatchelfHook
      bashInteractive
      patchelf
      gcc
    ] ++ llvm;

in {

  # runtime dependencies
  runtimeDep = with pkgs;
    [
      udev
      systemd
      systemd.dev
      libpulseaudio
      freetype
      openssl
      alsa-lib
      fontconfig.lib
      speechd
      dbus.lib
      vulkan-loader
    ] ++ libXorg;

  # build dependancies
  buildDep = with pkgs; [ zlib yasm vulkan-headers ] ++ libXorg ++ libOpenGL;
}
