# options to use for building godot
# TODO : allow for customisation
{ ... }: {
  optimize = "speed";
  lto = "full"; # default is none
  production = "yes"; # godot default is no
  use_volk = "yes"; # godot default is yes;
  use_llvm = "no";
  use_vulkan = "yes";
}
