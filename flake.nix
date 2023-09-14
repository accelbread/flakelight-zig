# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{
  inputs.flakelight.url = "github:accelbread/flakelight";
  outputs = { flakelight, ... }: flakelight ./. {
    imports = [ flakelight.flakelightModules.flakelightModule ];
    flakelightModule = ./flakelight-zig.nix;
  };
}
