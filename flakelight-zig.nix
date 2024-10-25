# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, flakelight, ... }:
let
  inherit (builtins) deepSeq pathExists toString;
  inherit (lib) mkIf mkOption warnIf;
  inherit (lib.types) functionTo listOf package str;
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
      type = listOf str;
      default = [ "--release=safe" "-Dcpu=baseline" ];
    };

    zigDependencies = mkOption {
      type = nullable (functionTo package);
      default = null;
    };

    zigSystemLibs = mkOption {
      type = functionTo (listOf package);
      default = _: [ ];
    };
  };

  config = {
    package = mkIf hasBuildZon
      (deepSeq buildZon ({ stdenvNoCC, zig, pkg-config, pkgs, defaultMeta }:
        stdenvNoCC.mkDerivation {
          pname = buildZon.name;
          version = buildZon.version;
          src = toSource {
            root = src;
            fileset = unions (map (p: src + ("/" + p)) buildZon.paths);
          };
          nativeBuildInputs = [ zig pkg-config ];
          buildInputs = config.zigSystemLibs pkgs;
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
        }));

    devShell.packages = pkgs: (with pkgs; [ zig zls pkg-config zon2nix ])
      ++ config.zigSystemLibs pkgs;

    checks.test = pkgs: ''
      export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
      ${linkDeps pkgs}
      ${pkgs.zig}/bin/zig build test
    '';

    formatters = pkgs: {
      "*.zig" = "${pkgs.zig} fmt";
    };
  };
}
