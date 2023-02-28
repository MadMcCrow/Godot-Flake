# custom.nix
# this modules focuses on generating or overriding the custom.py used to build godot
{ lib, pkgs, system }:
let

  # TODO : 
  override = false;
  file = "./custom.py";

  # custom options
  options = {

    # optimize is one of "size"or "speed"
    optimize = "speed";
    # C# support
    module_mono_enabled = "yes";
    # llvm
    use_llvm = "yes";
    use_lld = "yes";
    # link time optim
    use_lto = "yes";
    # add a suffix to binaries
    extra_suffix = "_flake";
    #  opengl3 = "false";
    #  pulseaudio = withPulseaudio;
    #  dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
    #  speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
    #  fontconfig = withFontconfig; # Use fontconfig for system fonts support
    #  udev = withUdev; # Use udev for gamepad connection callbacks
    #  touch = withTouch; # Enable touch events
  };
in {
  # we can use (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options); if we have values in nix format
  # resulting scons flag
  customSconsFlags = (lib.mapAttrsToList (k: v: "${k}=${v}") options);
}
