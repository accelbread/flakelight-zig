# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, flakelight, ... }:
let
  inherit (builtins) any pathExists toString;
  inherit (lib) assertMsg mkIf mkOption types warnIf;
  inherit (lib.fileset) fileFilter toSource unions;
  inherit (flakelight.types) fileset;

  readZon = import ./parseZon.nix lib;
  buildZonFile = src + /build.zig.zon;
  buildZon =
    if pathExists buildZonFile
    then readZon buildZonFile
    else { };
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
  };

  config = {
    pname = mkIf (buildZon ? name) buildZon.name;
    version = mkIf (buildZon ? version) buildZon.version;
    fileset = mkIf (buildZon ? paths)
      (unions (map (p: src + ("/" + p)) buildZon.paths));

    package =
      assert assertMsg (config.pname != null)
        "pname option must be set in flakelight config.";
      { stdenvNoCC, zig, defaultMeta }:
      stdenvNoCC.mkDerivation {
        inherit (config) pname version;
        src = toSource { root = src; inherit (config) fileset; };
        nativeBuildInputs = [ zig ];
        strictDeps = true;
        dontConfigure = true;
        dontInstall = true;
        XDG_CACHE_HOME = ".cache";
        buildPhase = ''
          runHook preBuild
          mkdir -p $out
          zig build ${toString config.zigFlags} --prefix $out
          runHook postBuild
        '';
        meta = defaultMeta;
      };

    devShell.packages = pkgs: with pkgs; [ zig zls ];

    checks.test = pkgs: "HOME=$TMPDIR ${pkgs.zig}/bin/zig build test";

    formatters."*.zig" = "zig fmt";
  };
}
