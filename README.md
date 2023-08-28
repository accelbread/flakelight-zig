# flakelight-zig

Zig module for [flakelight][1].

[1]: https://github.com/accelbread/flakelight

## Additional options

Set `name` to the name of the Zig package.

Set `version` to the version of the package.

## Configured options

Sets `package` to the zig project at the flake source.

Adds `zig` and `zls` to the default devShell.

Adds checks for zig tests.

Configures `zig` files to be formatted with `zig fmt`.

## Example flake

```nix
{
  inputs = {
    flakelight.url = "github:accelbread/flakelight";
    flakelight-zig.url = "github:accelbread/flakelight-zig";
  };
  outputs = { flakelight, flakelight-zig, ... }: flakelight ./. {
    imports = [ flakelight-zig.flakelightModules.default ];
    name = "hello-world";
    version = "0.0.1";
    description = "My Zig application.";
    license = "AGPL-3.0-or-later";
  };
}
```
