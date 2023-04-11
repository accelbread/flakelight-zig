# flakelite-zig -- Zig module for flakelite
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

defaultInputs: src: inputs: root:
let
  inputs' = defaultInputs // inputs;
in
{
  withOverlay = _: prev: {
    zig = inputs'.zig-overlay.packages.${prev.system}.master;
    zls = inputs'.zls.packages.${prev.system}.default;
  };
  package = { stdenvNoCC, zig, lib, system, flakelite }:
    stdenvNoCC.mkDerivation {
      inherit (root) name;
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
      inherit (flakelite) meta;
    };
  devTools = { zls, zig, ... }: [ zls zig ];
  checks = { lib, zig, ... }: {
    test = "HOME=$TMPDIR ${lib.getExe zig} build test";
  };
  formatters = {
    "*.zig" = "zig fmt";
  };
}
