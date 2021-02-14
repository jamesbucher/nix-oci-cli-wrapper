# Nix oci-cli

This is a simple nix flake that allows for an easy install of the [Oracle OCI CLI interface](https://github.com/oracle/oci-cli) onto a nixos system.

## Caveats
Unfortunately getting python packaged into a "clean" nix package turned out to be extremely tedious. Pip wants to write files all over the place and attempts to cache files in the home directory. Nix on the other hand disallows network calls during an install to prevent packages from being non-deterministic.

To get around this package creates a simple bash script that will automatically use a python venv and pip to install the CLI on the fly when it is called the first time. This writes files into the user HOME directory. After this is done the files are cached.

The venv is written to $HOME/.bin/lib/nix-python-installs/<nix-package-derivation-path>. This means that if you uninstall/upgrade the package garbage will be left in this folder as the venv will be abandoned.

It should also be noted that pip caches package installs in the user directory so this is another loction where garbage can hang around.

This script also take a dependency on the folder being named "/nix/store/<derivation-name>" In order to determine the final nix-package-derivation-path.
