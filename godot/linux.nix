# linux.nix
# linux build Attributes
{ pkgs, options, ... }:
let
  # shortcuts
  inherit (pkgs.lib.lists) optionals;

 hasOptions = key: if (options ? key) then options.${key} == "yes" else false;
 # lookup options
 # todo : clean that !
  use_x11 = hasOptions "use_x11";
  use_openGL = hasOptions "use_OpenGL";
  use_mono = hasOptions "use_mono";
  use_vulkan = hasOptions "use_vulkan";
  use_llvm = hasOptions "use_llvm";

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
    ] ++ optionals use_llvm libllvm;

in pkgs.stdenv.mkDerivation rec {
  # basic stuff :
  pname = "godot";
  inherit version;
  src = inputs.godot;

  sconsFlags = [
    "platform=linux"
  ]
  ++ (map (x: "${x}=${options."${x}"}") (builtins.attrNames options));


  # As a rule of thumb: Buildtools as nativeBuildInputs,
  # libraries and executables you only need after the build as buildInputs
  nativeBuildInputs = buildTools ++ optionals use_x11 libXorg
    ++ optionals use_openGL libOpenGL ++ optionals use_mono libMono
    ++ optionals use_vulkan libVulkan;

  buildInputs = [ pkgs.zlib pkgs.yasm ] ++ optionals use_x11 libXorg
    ++ optionals use_openGL libOpenGL ++ optionals use_mono libMono
    ++ optionals use_vulkan libVulkan;

  # runtime dependencies
  runtimeDependencies = libRuntime ++ optionals use_x11 libXorg
    ++ optionals use_mono libMono ++ optionals use_openGL libOpenGL
    ++ optionals use_vulkan libVulkan;

  # apply the necessary patches
  patches = [
    ./patches/xfixes.patch # fix x11 libs
    ./patches/gl.patch # fix gl libs
  ];

  # steal nixpkgs installPhase
  # nixpkgs use Godot4 and godot4 instead of godot, so we replace
  installPhase = replaceStrings [ "odot4" ] [ "odot" ] pkgs.godot4.installPhase;
}