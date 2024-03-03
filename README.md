# flakelight-zig

Zig module for [flakelight][1].

[1]: https://github.com/nix-community/flakelight

## Options

Set `pname` to the name of the Zig package, if `name` not configured in
`build.zig.zon`.

Set `version` to the version of the package if `version` not in `build.zig.zon`.

## Configured options

Sets `package` to the zig project at the flake source.

Adds `zig` and `zls` to the default devShell.

Adds checks for zig tests.

Configures `zig` files to be formatted with `zig fmt`.

## Example flake

```nix
{
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }: flakelight-zig ./. {
    pname = "hello-world";
    version = "0.0.1";
    description = "My Zig application.";
    license = "AGPL-3.0-or-later";
  };
}
```
