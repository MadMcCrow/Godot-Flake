# Godot.nix
# this modules focuses on building godot
# TODO : Add support for a custom.py
{ pkgs, inputs, system }:
with pkgs;
let

  # TODO : implement options
  # Options from godot/platform/linuxbsd/detect.py
  #options = {
  #  pulseaudio = withPulseaudio;
  #  dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
  #  speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
  #  fontconfig = withFontconfig; # Use fontconfig for system fonts support
  #  udev = withUdev; # Use udev for gamepad connection callbacks
  #  touch = withTouch; # Enable touch events
  #};

  # build tools
  buildTools = with pkgs; [
    scons
    pkg-config
    installShellFiles
    autoPatchelfHook
    bashInteractive
    patchelf
    gcc
    clang
  ];

  # runtime dependencies
  runtimeDep = with pkgs; [
    udev
    systemd
    systemd.dev
    libpulseaudio
    freetype
    openssl
    alsa-lib
    vulkan-loader
    fontconfig.lib
    speechd
    dbus.lib
  ];

  # build dependancies
  buildDep = with pkgs; [
    libGLU
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
    xorg.libXext
    xorg.libXfixes
    zlib
    yasm
  ];

  # godot version
  godotVersion = import ./version.nix {inherit system; };

  # implementation
in rec
{
  # mkGodot
  # function to male a godot build
  # TODO : add a custom.py to fill the sconsFlags
  mkGodot = { name ? "godot", target ? "editor", tools ? true, ... }:
    stdenv.mkDerivation {
      # use variables from args
      pname = name;
      src = inputs.godot;

      # get godot version from version modules
      version = godotVersion.version;
      platform = godotVersion.platform;
     
      # As a rule of thumb: Buildtools as nativeBuildInputs,
      # libraries and executables you only need after the build as buildInputs
      nativeBuildInputs = buildTools ++ buildDep;
      buildInputs = runtimeDep;
      runtimeDependencies = runtimeDep;
      enableParallelBuilding = true;

      # scons flags list 
      sconsFlags = [
        ("platfom=" + godotVersion.platform)
        ("target=" + target)
        (if tools then "tools=yes" else [ "tools=no" ])
      ];

      # apply the necessary patches
      # TODO : take EVERYTHING in the patches folder
      patches = [
        ./patches/xfixes.patch # fix x11 libs
        ./patches/gl.patch     # fix gl libs
      ];
      
      # Not necessary : sconsFlags is "enough"
      # preconfigure help for scons
      #preConfigure = ''
      #  sconsFlags+="${sconsFlags}"
      #'';
            
      installPhase = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot
        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
        substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
      '';

      # some extra info
       meta = with lib; {
          homepage = pkgs.godot.meta.homepage;
          description = pkgs.godot.meta.description;
          license = licenses.mit;
       };
    };

  # build a template
  mkGodotTemplate = { ... }:
    mkGodot {
      pname = "godot-template" + target;
      tools = false;
      installPhase = ''
        mkdir -p "$out/share/godot/templates/${oldAttrs.version}.stable"
        cp bin/godot.x11.opt.64 $out/share/godot/templates/${oldAttrs.version}.stable/linux_x11_64_release
      '';
      # https://docs.godotengine.org/en/stable/development/compiling/optimizing_for_size.html
      strip = (oldAttrs.stripAllList or [ ]) ++ [ "share/godot/templates" ];
    };
}