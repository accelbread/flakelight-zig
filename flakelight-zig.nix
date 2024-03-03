# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, flakelight, ... }:
let
  inherit (builtins) any pathExists toString;
  inherit (lib) assertMsg mkIf mkOption optional types warnIf;
  inherit (lib.types) functionTo package;
  inherit (lib.fileset) fileFilter toSource unions;
  inherit (flakelight.types) fileset nullable;

  readZon = import ./parseZon.nix lib;
  buildZonFile = src + /build.zig.zon;
  hasBuildZon = pathExists buildZonFile;
  buildZon =
    if hasBuildZon
    then readZon buildZonFile
    else { };

  linkDeps = pkgs:
    if config.zigDependencies != null then
      "ln -s ${config.zigDependencies pkgs} $ZIG_GLOBAL_CACHE_DIR/p"
    else "";
in
warnIf (! builtins ? readFileType) "Unsupported Nix version in use."
{
  options = {
    version = mkOption { type = types.str; };

    zigFlags = mkOption {
      type = types.listOf types.str;
      default = [ "-Doptimize=ReleaseSafe" "-Dcpu=baseline" ];
    };

    fileset = mkOption {
      type = fileset;
      default = fileFilter
        (file: any file.hasExt [ "zig" "zon" "c" "h" ])
        src;
    };

    zigDependencies = mkOption {
      type = nullable (functionTo package);
      default = null;
    };
  };

  config = {
    pname = mkIf (buildZon ? name) buildZon.name;
    version = mkIf (buildZon ? version) buildZon.version;
    fileset = mkIf (buildZon ? paths)
      (unions (map (p: src + ("/" + p)) buildZon.paths));

    package =
      assert assertMsg (config.pname != null)
        "pname option must be set in flakelight config.";
      { stdenvNoCC, zig, pkgs, defaultMeta }:
      stdenvNoCC.mkDerivation {
        inherit (config) pname version;
        src = toSource { root = src; inherit (config) fileset; };
        nativeBuildInputs = [ zig ];
        strictDeps = true;
        dontConfigure = true;
        dontInstall = true;
        postPatch = ''
          export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
          ${linkDeps pkgs}
        '';
        buildPhase = ''
          runHook preBuild
          mkdir -p $out
          zig build ${toString config.zigFlags} --prefix $out
          runHook postBuild
        '';
        meta = defaultMeta;
      };

    devShell.packages = pkgs: [ pkgs.zig pkgs.zls ] ++
      (optional hasBuildZon pkgs.zon2nix);

    checks.test = pkgs: "HOME=$TMPDIR ${pkgs.zig}/bin/zig build test";

    formatters."*.zig" = "zig fmt";
  };
}
