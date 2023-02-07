# custom.nix
# this modules focuses on generating or overriding the custom.py used to build godot
# TODO : generate the custom.py with this module
# TODO : generate the profile command line with this module
{ pkgs, system, ...  }:
{
override = true;
file = "./custom.py";
}