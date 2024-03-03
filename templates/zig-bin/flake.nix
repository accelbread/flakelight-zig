{
  description = "Template Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }:
    flakelight-zig ./. {
      pname = "hello-world";
      version = "0.0.1";
      license = "AGPL-3.0-or-later";
    };
}
