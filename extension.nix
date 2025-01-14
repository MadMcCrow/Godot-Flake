# extension.nix
# this modules focuses on building cool extensions for godot
# TODO:
# Auto patch derviation 
pkgs:
{ name, src, godot-cpp, ... }@args:
let
  # extension file for the engine
  # TODO : linux aarch64
  # TODO : darwin
  ext_file = pkgs.writeText "${name}.gdextension" ''
    [configuration]
    entry_symbol = "${name}_library_init"
    [libraries]
    linux.x86_64 = "res://bin/x11/lib${name}.so"
  '';

  # implementation
in pkgs.stdenv.mkDerivation ({
  nativeBuildInputs = [ godot-cpp ] ++ godot-cpp.nativeBuildInputs;
  sconsFlags = godot-cpp.sconsFlags ++ [ "-s" ];
  # unpack files and folders alike !
  unpackPhase = ''
    if [ -d $src ]; then
      cp -r $src/* ./
    else 
      cp $src ./$(stripHash $src)
    fi
    touch -a -m ./*
    chmod 755 ./* -R
  '';

  ## copy prebuilt godot-cpp to then build against it
  ## there might be a smarter way to do this (only copy folder structure, link the rest)
  ## use Sconstruct from godotcpp : 
  ## Add something like : substituteInPlace SConstruct --replace 'env = SConscript("../SConstruct")' 'env = SConscript("godot-cpp/SConstruct")'
  postPatch = ''
    mkdir -p godot-cpp
    cp -r ${godot-cpp}/* ./godot-cpp/
    chmod 755 -R godot-cpp
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp bin/*.so $out/bin/lib${name}.so
    cp ${ext_file} $out/${name}.gdextension
  '';
} // builtins.removeAttrs args [ "godot-cpp" ])
