{
  description = "Template Zig application.";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flakelight-zig.url = "github:accelbread/flakelight-zig";
  };
  outputs = { flakelight-zig, ... }@inputs:
    flakelight-zig ./. {
      inherit inputs;
      name = "hello-world";
      version = "0.0.1";
      license = "AGPL-3.0-or-later";
    };
}
