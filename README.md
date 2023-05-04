# `govers` - Easily manage multiple Go installations

This repo contains a single Zsh shell script that registers a `govers` shell command.  This command provides several operations for managing your Go installation (or installations, plural).

h/t to Robbie Coleman, who was instrumental in putting this together.

```bash
> govers help
  usage: govers use|list|remove|installed [-v] {goversion}
       2nd arg | -v | --version:     the Go version

    example:
    > govers use go1.15.2
    > govers use -v 'go1.15.2'
    > govers use --version 'go1.15.2'

  Installs to $HOME/sdk by default.  Set $GOVERS_INSTALL_DIR to override.
```

## Install Steps

Copy `govers.zsh` into your `$HOME` folder then add the snippet below to your `.zshrc`:

```bash
# optionally override the default Go install location of $HOME/sdk
export GOVERS_INSTALL_DIR=$HOME/go
# inject the 'govers' command
source $HOME/govers.zsh
# use Go 1.20.4
govers use go1.20.4
```

With this, Go 1.20.4 will be downloaded and installed to `$HOME/go/go1.20.4` and that folder will be added to your `$PATH`.

## Managing Multiple Versions

This script also makes it trivial to have multiple versions of Go installed and switch between them.

```bash
# install and use Go 1.21 to test something
govers use go1.21
# ...

# switch to 1.19.9 and test there
govers use go1.19.9
# ...

# be super thorough and test under 1.18.x too
govers use go1.18.10
# ...

# switch back to Go 1.20.4
govers use go1.20.4
```

For any given Go version, `govers use` will download it to `$GOVERS_INSTALL_DIR/[version]` and inject that into your `$PATH`.

## Upgrading to new Go releases

Installing new Go versions is as simple as editing `.zshrc` and updating the `govers use` command

```bash
...
# use Go 1.20.5 instead
govers use go1.20.5
...
```
