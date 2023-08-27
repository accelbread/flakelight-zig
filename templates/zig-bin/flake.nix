{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flakelight.url = "github:accelbread/flakelight";
    flakelight-zig.url = "github:accelbread/flakelight-zig";
  };
  outputs = { flakelight, flakelight-zig, ... }@inputs: flakelight ./. {
    imports = [ flakelight-zig.flakelightModules.default ];
    inherit inputs;

    name = "hello-world";
    version = "0.0.1";
    description = "Template Zig application.";
    license = "agpl3Plus";
  };
}
