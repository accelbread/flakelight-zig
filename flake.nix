# flakelite-zig -- Zig module for flakelite
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{
  inputs = {
    flakelite.url = "github:accelbread/flakelite";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "zls/nixpkgs";
    };
    zls = {
      url = "github:zigtools/zls";
      inputs.zig-overlay.follows = "zig-overlay";
    };
  };
  outputs = { flakelite, ... }@inputs:
    flakelite.lib.mkFlake ./. {
      outputs.flakeliteModule = import ./. inputs;
    };
}
