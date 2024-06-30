{
  description = "Template Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }:
    flakelight-zig ./. {
      license = "AGPL-3.0-or-later";
    };
}
