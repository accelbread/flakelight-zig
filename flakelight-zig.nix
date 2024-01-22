# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, ... }:
let
  inherit (lib) assertMsg mkOption types;
in
{
  options.version = mkOption { type = types.str; };

  config = {
    package =
      assert assertMsg (config.pname != null)
        "pname option must be set in flakelight config.";
      { stdenvNoCC, zig, defaultMeta }:
      stdenvNoCC.mkDerivation {
        inherit (config) pname version;
        inherit src;
        nativeBuildInputs = [ zig ];
        strictDeps = true;
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
