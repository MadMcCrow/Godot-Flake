# version.nix
# get the godot version with IFD
{ inputs, pkgs }:
with builtins;
let
  inherit (pkgs.lib) strings attrsets;

  # get version file from godot itself
  godotVersionFile = pkgs.stdenvNoCC.mkDerivation {
    src =
      builtins.filterSource (n: t: baseNameOf n == "version.py") inputs.godot;
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
in ({
  asString =
    "${godotVersionAttrs.major}.${godotVersionAttrs.minor}.${godotVersionAttrs.patch}-${godotVersionAttrs.status}";
} // godotVersionAttrs)
