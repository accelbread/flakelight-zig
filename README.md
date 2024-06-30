# flakelight-zig

Zig module for [flakelight][1].

[1]: https://github.com/nix-community/flakelight

Package metadata is read from `build.zig.zon`.

## Options

`zigFlags` allows overriding of the flags passed to `zig build`.

`zigDependencies` will have to be set if `build.zig.zon` contains dependencies.
Set it to a function that takes the package set and returns a zig package cache
path.

## Configured options

Sets `package` to the zig project at the flake source.

Adds `zig`, `zls`, and `zon2nix` to the default devShell.

Adds checks for zig tests.

Configures `zig` files to be formatted with `zig fmt`.

## Example flakes

### Standard

```nix
{
  description = "My Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }: flakelight-zig ./. {
    license = "AGPL-3.0-or-later";
  };
}
```

### When `build.zig.zon` has dependencies

Use `zon2nix` to generate `deps.nix`.

The `zon2nix` output can be used as follows:

```nix
{
  description = "My Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }: flakelight-zig ./. {
    license = "AGPL-3.0-or-later";
    zigDependencies = pkgs: pkgs.callPackage ./deps.nix {};
  };
}
```
