# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, ... }:
let
  inherit (builtins) attrValues deepSeq pathExists toString;
  inherit (lib) mkIf mkMerge mkOption warnIf;
  inherit (lib.types) functionTo lazyAttrsOf listOf package str;
  inherit (lib.fileset) toSource unions;

  strictEval = x: deepSeq x x;
  readZon = import ./parseZon.nix lib;

  buildZonFile = src + /build.zig.zon;
  hasBuildZon = pathExists buildZonFile;
  buildZon = strictEval (readZon buildZonFile);

  pkgDir = pkgs: pkgs.linkFarm "zig-packages" (config.zigPackages pkgs);
  makeZigCacheDir = pkgs: ''
    export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
    ln -s ${pkgDir pkgs} $ZIG_GLOBAL_CACHE_DIR/p
  '';

  dependencies = buildZon.dependencies or { };

  # zon deps with git urls can be automatically converted into nix drvs
  gitDependencies = pkgs: lib.pipe dependencies [
    lib.attrValues
    (lib.filter (d: d ? url))
    (map (d: {
      name = d.hash;
      captures = builtins.match "git\\+(.*)#([a-z0-9]+)" d.url;
    }))
    (lib.filter (d: d.captures != null))
    (map (d: {
      inherit (d) name;
      value = builtins.fetchGit {
        url = builtins.elemAt d.captures 0;
        rev = builtins.elemAt d.captures 1;
        shallow = true;
      };
    }))
    builtins.listToAttrs
  ];
in
warnIf (! builtins ? readFileType) "Unsupported Nix version in use."
{
  options = {
    zigToolchain = mkOption {
      type = functionTo (lazyAttrsOf package);
      default = pkgs: { inherit (pkgs) zig zls; };
    };

    zigFlags = mkOption {
      type = listOf str;
      default = [ "--release=safe" "-Dcpu=baseline" ];
    };

    zigPackages = mkOption {
      type = functionTo (lazyAttrsOf package);
      default = gitDependencies;
    };

    zigSystemLibs = mkOption {
      type = functionTo (listOf package);
      default = _: [ ];
    };
  };

  config = mkMerge [
    (mkIf hasBuildZon {
      pname = buildZon.name;

      package = { stdenvNoCC, pkg-config, pkgs, defaultMeta }:
        stdenvNoCC.mkDerivation {
          pname = buildZon.name;
          version = buildZon.version;
          src = toSource {
            root = src;
            fileset = unions (map (p: src + ("/" + p)) buildZon.paths);
          };
          nativeBuildInputs = [ (config.zigToolchain pkgs).zig pkg-config ];
          buildInputs = config.zigSystemLibs pkgs;
          strictDeps = true;
          dontConfigure = true;
          dontInstall = true;
          postPatch = ''
            ${makeZigCacheDir pkgs}
          '';
          buildPhase = ''
            runHook preBuild
            mkdir -p $out
            zig build ${toString config.zigFlags} --prefix $out
            runHook postBuild
          '';
          meta = defaultMeta;
        };

      checks.test = pkgs: ''
        ${makeZigCacheDir pkgs}
        ${(config.zigToolchain pkgs).zig}/bin/zig build test
      '';
    })

    {
      devShell.packages = pkgs: (with pkgs; [ pkg-config ])
        ++ attrValues (config.zigToolchain pkgs)
        ++ config.zigSystemLibs pkgs;

      formatters = pkgs: {
        "*.zig" = "${(config.zigToolchain pkgs).zig} fmt";
      };
    }
  ];
}
