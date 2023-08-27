# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    name = mkOption { type = types.str; };
    version = mkOption { type = types.str; };
  };

  config = {
    package = { stdenvNoCC, zig, defaultMeta }:
      stdenvNoCC.mkDerivation {
        pname = config.name;
        version = config.version;
        inherit src;
        nativeBuildInputs = [ zig ];
        dontConfigure = true;
        dontInstall = true;
        XDG_CACHE_HOME = ".cache";
        buildPhase = ''
          runHook preBuild
          mkdir -p $out
          zig build -Doptimize=ReleaseSafe -Dcpu=baseline --prefix $out
          runHook postBuild
        '';
        meta = defaultMeta;
      };

    devShell.packages = pkgs: with pkgs; [ zig zls ];

    checks.test = pkgs: "HOME=$TMPDIR ${pkgs.zig}/bin/zig build test";

    formatters."*.zig" = "zig fmt";
  };
}
