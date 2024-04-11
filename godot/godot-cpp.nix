# Godot-cpp.nix
# Godot-cpp bindings
{ pkgs, inputs, ... }@args:
let
  # get godot 
  godot = import ./godot.nix args;

in pkgs.stdenv.mkDerivation {
  inherit buildInputs runtimeDependencies;
  nativeBuildInputs = nativeBuildInputs ++ [ godot.editor ];
  # make name:
  name = "godot-cpp-editor-${version.asString}";
  version = version.asString;
  src = inputs.godot-cpp;
  # this does not work, sadly
  # configurePhase = "${godot-editor}/bin/godot --dump-extension-api extension_api.json";
  # "custom_api_file=extension_api.json"

  # patch
  patches = [
    ./patches/godot-cpp.patch # fix path for g++
  ];
  # build flags 
  sconsFlags = [ "generate_bindings=true" "-s" ] ++ godot-editor.sconsFlags;

  # maybe split outputs ["SConstruct" "binding_generator" ... ]
  outputs = [ "out" ];
  installPhase = ''
    mkdir -p $out
    cp -r src $out/src
    cp -r SConstruct $out/
    cp -r binding_generator.py $out/
    cp -r gdextension $out/
    cp -r include $out/
    cp -r tools $out/
    cp -r gen $out/
    chmod 755 $out -R
    chmod 755 $out/gen/include/godot_cpp/core/ext_wrappers.gen.inc
  '';
}
