# linux.nix
# linux build Attributes
# defaultAttrs Attrs is the overrided defaults
{ pkgs, options,  ... }: defaultAttrs:
let
  # shortcuts
  inherit (pkgs.lib.lists) optionals;

  hasOptions = key: default:
    if (options ? key) then options.${key} == "yes" else default;
  # lookup options
  # todo : clean that !
  use_x11 = hasOptions "use_x11" true;
  use_openGL = hasOptions "use_OpenGL" true;
  use_mono = hasOptions "use_mono" false;
  use_vulkan = hasOptions "use_vulkan" true;
  use_llvm = hasOptions "use_llvm" true;

in rec {
  sconsFlags = [ "platform=linux" ] ++ defaultAttrs.sconsFlags;

  # runtime dependencies
  runtimeDependencies = (with pkgs; [
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
  ])
  ++ optionals use_x11 (with pkgs.xorg; [
    libX11
    libXcursor
    libXi
    libXinerama
    libXrandr
    libXrender
    libXext
    libXfixes
  ])
    ++ optionals use_mono ( with pkgs; [ mono6 msbuild dotnetPackages.Nuget ]) ++ optionals use_openGL (with pkgs; [
    glslang
    libGLU
    libGL
  ]) ++ optionals use_vulkan ( with pkgs; [ vulkan-loader vulkan-headers vulkan-tools ]);

  # As a rule of thumb: Buildtools as nativeBuildInputs,
  # libraries and executables you only need after the build as buildInputs
  nativeBuildInputs = with pkgs; [
    scons
    pkg-config
    installShellFiles
    autoPatchelfHook
    bashInteractive
    patchelf
    gcc
  ] ++ (optionals use_llvm (with pkgs; [
    llvm
    lld
    clang
    clangStdenv
    llvmPackages.libcxxClang
    llvmPackages.clangUseLLVM
  ])) ++ runtimeDependencies;

  buildInputs = [ pkgs.zlib pkgs.yasm ] ++ runtimeDependencies;

  # apply the necessary patches
  patches = [
    ./patches/xfixes.patch # fix x11 libs
    ./patches/gl.patch # fix gl libs
  ];

  # steal nixpkgs installPhase
  # nixpkgs use Godot4 and godot4 instead of godot, so we replace
  installPhase = builtins.replaceStrings [ "odot4" ] [ "odot" ] pkgs.godot_4.installPhase;
}
