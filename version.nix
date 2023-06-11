# version.nix
# function to get godot version

{ pkgs, inputs,  version ? "" }:
with pkgs;
with builtins;
let
  # get lib
  lib = pkgs.lib;
  strs = lib.strings;

  # get version file from godot itself
  godotVersionFile = stdenv.mkDerivation {
    src = inputs.godot;
    name = "godot-version-descriptor";
    noBuildPhase = true;
    installPhase = ''
      mkdir -p "$out/"
      cp version.py $out/version.py
    '';
  };

  useDefaultVersion = (version == "");


  # helper functions 
  removeChars = l: str: strs.stringAsChars (x: if (any (c: x == c) l) then "" else x) str;
  splitLine   = lstr: (strs.splitString "\n" lstr);
  removeEmpty = l: filter (x: x != "") l;
  hasAllAttrs = names: set: all (x: x) (map (a: hasAttr a set) names);

  mkPair = separator: str:
    let split = (strs.splitString separator str);
    in lib.attrsets.nameValuePair (elemAt split 0) (elemAt split 1);

  # godot Attribute Set
  godotVersionAttrs = builtins.listToAttrs (map (s: mkPair " = " s) (removeEmpty
    (map (removeChars ["\n" "\""]) (splitLine (readFile "${godotVersionFile}/version.py")))));

  # split version
  v = splitVersion "4.1.0-beta";

# build AttrSet
in rec {
    
    major  = if useDefaultVersion then godotVersionAttrs.major  else (elemAt v 0);
    minor  = if useDefaultVersion then godotVersionAttrs.minor  else (elemAt v 1);
    patch  = if useDefaultVersion then godotVersionAttrs.patch  else (elemAt v 2);
    status = if useDefaultVersion then godotVersionAttrs.status else (elemAt v 3);
  
    asString = "${major}.${minor}.${patch}-${status}";
}
