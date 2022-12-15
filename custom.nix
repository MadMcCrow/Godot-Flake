# custom.nix
# this modules focuses on generating or overriding the custom.py used to build godot
# TODO : generate the custom.py with this module
{ pkgs, system, ... }:
with pkgs;
let
  lib = pkgs.lib;
  cfg = options.custom;
  customPy = if cfg.override.enable then cfg.override.file else "";
in
{
  # interface
  options.custom = {
    # override all the options to use user provided custom.py
    override = {
      enable = mkOption { 
        type = types.bool;
        default = false;
        example = true;
        description = lib.mdDoc ''
        Force to use a specific user provided custom.py file
        '';
      };
      file = mkOption {
        type = types.path;
        default = ./custom.py;
        example = ./custom.py;
        description = lib.mdDoc ''
        Force to use a specific user provided custom.py file
        '';
      };
    };
  };

  # generate
  godotCustom = customPy;
  useCustom = true;
}