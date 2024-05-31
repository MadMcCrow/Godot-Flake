# version.nix
# get the godot version with IFD
{ godot, stdenvNoCC, lib, ... }:
with builtins;
let
  inherit (lib) strings attrsets;

  # get version file from godot itself
  godotVersionFile = stdenvNoCC.mkDerivation {
    src = builtins.filterSource (n: t: baseNameOf n == "version.py") godot;
    name = "godot-version-desc";
    noBuildPhase = true;
    installPhase = "install -D -t $out ./version.py";
  };
  removeChars = l: str:
    strings.stringAsChars (x: if (any (c: x == c) l) then "" else x) str;
  splitLine = lstr: (strings.splitString "\n" lstr);
  removeEmpty = l: filter (x: x != "") l;
  hasAllAttrs = names: set: all (x: x) (map (a: hasAttr a set) names);
  mkPair = str:
    let split = (strings.splitString " = " str);
    in attrsets.nameValuePair (elemAt split 0) (elemAt split 1);
  godotVersionAttrs = builtins.listToAttrs (map mkPair (removeEmpty
    (map (removeChars [ "\n" ''"'' ])
      (splitLine (readFile "${godotVersionFile}/version.py")))));

  # build AttrSet
in "${godotVersionAttrs.major}.${godotVersionAttrs.minor}.${godotVersionAttrs.patch}-${godotVersionAttrs.status}"
