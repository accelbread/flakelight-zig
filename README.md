# flakelight-zig

Zig module for [flakelight][1].

[1]: https://github.com/nix-community/flakelight

## Options

Set `pname` to the name of the Zig package, if `name` not configured in
`build.zig.zon`.

Set `version` to the version of the package if `version` not in `build.zig.zon`.

`zigDependencies` will have to be set if `build.zig.zon` contains dependencies.
Set it to a function that takes the package set and returns a zig package cache
path.

`fileset` configures the fileset the package is built with. To use all files,
set it to `./.`. Without `build.zig.zon`, The default is Zig and C files. If
`paths` is set in `build.zig.zon`, those paths are used.

## Configured options

Sets `package` to the zig project at the flake source.

Adds `zig` and `zls` to the default devShell.

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

### When `build.zig` sets `preferred_optimize_mode`

```nix
{
  description = "My Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }: flakelight-zig ./. {
    license = "AGPL-3.0-or-later";
    zigFlags = [ "-Dcpu=baseline" "-Drelease" ];
  };
}
```

### Without a `build.zig.zon`

```nix
{
  description = "My Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }: flakelight-zig ./. {
    pname = "hello-world";
    version = "0.0.1";
    license = "AGPL-3.0-or-later";
  };
}
```

### When `build.zig.zon` has dependencies

Use `zon2nix` to generate `deps.nix` (`zon2nix` is available in the devShell if
the flake has a `build.zig.zon`). The `zon2nix` output can be used as follows:

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
