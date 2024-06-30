# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, flakelight, ... }:
let
  inherit (builtins) pathExists toString;
  inherit (lib) mkIf mkOption types warnIf;
  inherit (lib.types) functionTo package;
  inherit (lib.fileset) toSource unions;
  inherit (flakelight.types) nullable;

  readZon = import ./parseZon.nix lib;
  buildZonFile = src + /build.zig.zon;
  hasBuildZon = pathExists buildZonFile;
  buildZon = readZon buildZonFile;

  linkDeps = pkgs:
    if config.zigDependencies != null then
      "ln -s ${config.zigDependencies pkgs} $ZIG_GLOBAL_CACHE_DIR/p"
    else "";
in
warnIf (! builtins ? readFileType) "Unsupported Nix version in use."
{
  options = {
    zigFlags = mkOption {
      type = types.listOf types.str;
      default = [ "--release=safe" "-Dcpu=baseline" ];
    };

    zigDependencies = mkOption {
      type = nullable (functionTo package);
      default = null;
    };
  };

  config = {
    package = mkIf hasBuildZon
      ({ stdenvNoCC, zig, pkgs, defaultMeta }:
        stdenvNoCC.mkDerivation {
          pname = buildZon.name;
          version = buildZon.version;
          src = toSource {
            root = src;
            fileset = unions (map (p: src + ("/" + p)) buildZon.paths);
          };
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
        });

    devShell.packages = pkgs: [ pkgs.zig pkgs.zls pkgs.zon2nix ];

    checks.test = pkgs: "HOME=$TMPDIR ${pkgs.zig}/bin/zig build test";

    formatters."*.zig" = "zig fmt";
  };
}
