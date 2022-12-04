# extension.nix
# this modules focuses on building cool extensions for godot
{ pkgs, inputs, system }:
with pkgs;
let
# godot version infos
godotVersion = import ./version.nix{inherit system;};
in 
{

 #
 #  Godot-cpp bindings : they are required to
 #
  godot-cpp = stdenv.mkDerivation {
    pname = "godot-cpp";
    version = godotVersion.version;
    src = inputs.godot-cpp;
    nativeBuildInputs = buildTools ++ libs;
    buildInputs = libs;
    sconsFlags = flags;
    enableParallelBuilding = true;
    patchPhase = ''
      substituteInPlace SConstruct --replace 'env = Environment(tools=["default"])' 'env = Environment(tools=["default"], ENV={"PATH" : os.environ["PATH"]})'
    '';
    # produces "./result/godot-cpp-4.0/[bin gen src ...]
    installPhase = ''
      cp -r src $out/src
      cp -r bin $out/bin
      cp -r gen $out/gen
      cp -r SConstruct $out/
      cp -r binding_generator.py $out/
      cp -r tools $out/
      cp -r godot-headers $out/
    '';
  };

}