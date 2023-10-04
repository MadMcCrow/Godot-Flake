# extension.nix
# this modules focuses on building cool extensions for godot
{ pkgs, ... }:
{ godot-cpp # the godot cpp to build against
, src
, name
, target ? "editor"
,  ... }@args:
with builtins;
let
  # shortcuts
  inherit (pkgs) lib stdenv writeText;

  # extension file for the engine
  # TODO : linux aarch64
  ext_file = writeText "${name}.gdextension" ''
    [configuration]
    entry_symbol = "${name}_library_init"
    [libraries]
    linux.x86_64 = "res://bin/x11/lib${name}.so"
  '';

  # remove what mkDerivation does not need
  buildArgs = removeAttrs args [ "target" "godot-cpp" ];
  # and merge build Args given by user with ours : 
  mergeBuildArgs = drvArgs:
    drvArgs // (mapAttrs (name: value:
      if (hasAttr name drvArgs) && (isList value) then
        value ++ (getAttr name drvArgs)
      else
        value) buildArgs);

# implementation
in stdenv.mkDerivation (mergeBuildArgs {
  inherit src name;
  inherit (godot-cpp) buildInputs runtimeDependencies;
  nativeBuildInputs = [ godot-cpp ] ++ godot-cpp.nativeBuildInputs;

  # already in godot-cpp flags, but it does not hurt to add
  sconsFlags = godot-cpp.sconsFlags ++ ["-s"];

  #unpackPhase = '' cp -r $src ./ '';

  ## copy prebuilt godot-cpp to then build against it
  ## there might be a smarter way to do this (only copy folder structure, link the rest)
  ## use Sconstruct from godotcpp
  patchPhase = ''
    substituteInPlace SConstruct --replace 'env = SConscript("../SConstruct")' 'env = SConscript("godot-cpp/SConstruct")'
    mkdir -p godot-cpp
    cp -r ${godot-cpp}/* ./godot-cpp/
    chmod 777 -R godot-cpp
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/*.so $out/bin/lib${name}.so
    cp ${ext_file} $out/${name}.gdextension
  '';
})
