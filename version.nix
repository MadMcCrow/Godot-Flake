# version.nix
# function to get godot version

{ pkgs, inputs,  version ? "" }:
with pkgs;
with builtins;
let
  # get lib
  lib = pkgs.lib;

  # get version file from godot itself
  godotVersionFile = stdenv.mkDerivation {
    src = inputs.godot;
    name = "godot-version-descriptor";
    noBuildPhase = true;
    installPhase = ''
      mkdir -p "$out/"
      ls >> "$out/files.txt"
      cp version.py $out/version.py
    '';
  };

  # helper functions 
  mkPair = separator: str:
    let split = (lib.strings.splitString separator str);
    in lib.attrsets.nameValuePair (elemAt split 0) (elemAt split 1);
  splitLine = lstr: lib.strings.splitString "\n" lstr;
  replaceChar = r: n: str:
    (lib.strings.stringAsChars (x: if x == r then n else x) str);
  removeNewLine = str:
    lib.strings.stringAsChars (x: if x == "\n" then "" else x) str;
  removeEmpty = l: filter (x: x != "") l;
  hasAllAttrs = names: set: all (x: x) (map (a: hasAttr a set) names);

  # godot Attribute Set
  godotVersionAttrs = builtins.listToAttrs (map (s: mkPair " = " s) (removeEmpty
    (map removeNewLine
      (splitLine (readFile "${godotVersionFile}/version.py")))));

  # make the final version string
  pyVersion =
    if hasAllAttrs [ "major" "minor" "patch" "status" ] godotVersionAttrs then
      "${godotVersionAttrs.major}.${godotVersionAttrs.minor}.${godotVersionAttrs.patch}-${godotVersionAttrs.status}"
    else
      "";

in (if version == "" then pyVersion else version)
