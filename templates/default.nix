# flakelight-zig -- Zig module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

rec {
  default = zig-bin;
  zig-bin = {
    path = ./zig-bin;
    description = "Template Zig application.";
    welcomeText = ''
      # Flakelight Zig template
      To use, run `nix develop -c zig init-exe`.
    '';
  };
}
