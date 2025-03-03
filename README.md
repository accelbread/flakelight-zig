# flakelight-zig

Zig module for [flakelight][1].

[1]: https://github.com/nix-community/flakelight

Package metadata is read from `build.zig.zon`.

## Options

`zigFlags` allows overriding of the flags passed to `zig build`.

`zigPackages` allows providing Zig packages that the project depends on. Set it
to a function that takes the package set and returns an attrset of zig packages.
The attr names should be the zig package hash. This may be left unset if the
project has no dependencies or if all the dependencies use the
`git+<url>#<git-rev>` package url format.

`zigSystemLibs` allows adding libraries needed for building the project. It
should be a set to a function that takes the package set and returns packages to
be added to the main package's nativeBuildInputs and the to the devshell.

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

### When `build.zig.zon` has dependencies

Configure `zigDependencies` to a package containing the Zig package cache to
use. This is a directory tree with each package in a directory named by the Zig
package hash. For example:

```nix
{
  description = "My Zig application.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }: flakelight-zig ./. {
    license = "AGPL-3.0-or-later";
    zigDependencies = pkgs: pkgs.linkFarm "zig-deps" [{
      name = "1220bc9ee317a38d7868cbcfe1ab3c15fe3ffe897edb125ad4731584648ad08ed30a";
      path = builtins.fetchGit {
        url = "https://github.com/accelbread/bread-lib-zig.git";
        rev = "0883dc65c35d1c12bfaec19bfcbfb1d58bd7e5a7";
      };
    }];
  };
}
```

If all of your dependencies are git deps, then the above can be extracted from
`build.zig.zon` with Nix code by using `flakelight-zig.lib.parseZon` to read
`build.zig.zon` into a Nix attrset.
