# libs.nix
# Godot libraries for build and runtime
# TODO : 
# remove unecessary packages.
{ pkgs } :
let
  lib = pkgs.lib;

  # import option from custom
  godotCustom = import ./custom.nix {inherit lib;};

  use_x11 = options : godotCustom.getOption "x11" options;
  use_llvm = options : godotCustom.getOption "use_llvm" options;
  use_openGL = options : godotCustom.getOption "opengl3" options;
  use_vulkan = options : godotCustom.getOption "vulkan" options;
  use_mono = options: godotCustom.getOption "module_mono_enabled" options;

  # helper function
  conditionalLib = c: l: (if (c == true) then l else [ ]);

  # mono/C#
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

  libVulkan = with pkgs; [
    vulkan-loader
    vulkan-headers
    vulkan-tools
  ];

  # OpenGL libraries
  libOpenGL = with pkgs; [ glslang libGLU libGL ]; #++ [pkgs.nixgl.auto.nixGLDefault];

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


    # build dependencies
  mkBuildDependencies = options : (with pkgs;
    [ zlib yasm ] )
    ++ conditionalLib (use_x11 options)    libXorg
    ++ conditionalLib (use_openGL options) libOpenGL 
    ++ conditionalLib (use_mono options)   libMono
    ++ conditionalLib (use_vulkan options) libVulkan;

   mkBuildTools = options : with pkgs;
    [
      scons
      pkg-config
      installShellFiles
      autoPatchelfHook
      bashInteractive
      patchelf
      gcc
    ] ++ conditionalLib (use_llvm options) libllvm;

in {

 

  # runtime dependencies
  mkRuntimeDependencies = options : libRuntime
    ++ conditionalLib (use_x11 options)    libXorg
    ++ conditionalLib (use_mono options)   libMono
    ++ conditionalLib (use_openGL options) libOpenGL
    ++ conditionalLib (use_vulkan options) libVulkan;

  # As a rule of thumb: Buildtools as nativeBuildInputs,
  # libraries and executables you only need after the build as buildInputs
  mkNativeBuildInputs = options : (mkBuildTools options) ++ (mkBuildDependencies options);
  mkBuildInputs = options : (mkBuildDependencies options);
}
