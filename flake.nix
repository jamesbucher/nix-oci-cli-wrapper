{
  description = "The OCI SSH configurations.";

  # Bind the nixpkgs input to the 20.09 version that way it doesn't grab random
  # versions of things
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

  # Make this library compatible with old nix
  # See: https://nixos.wiki/wiki/Flakes
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, ... }: {
    defaultPackage.x86_64-linux = 
      with import nixpkgs { system = "x86_64-linux"; };
      pkgs.writeTextFile {
          name = "oci-cli";
          destination ="/bin/oci";
          executable = true;
          text = ''
            #!${pkgs.stdenv.shell}
            # A nix path looks like:
            # /nix/store/68sm67lcd4pnmyhijpyh134a7ykgyjhq-bash-interactive-4.4-p23/bin/bash
            # here we get the current working directory of the script and then
            # extract out the derivation folder so that we can make a temporary 
            # Folder in the user's home directory allowing us to write to a well known
            # Path to install the python packages to
            SOURCE="''${BASH_SOURCE[0]}"
            while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
              DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
              SOURCE="$(readlink "$SOURCE")"
              [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
            done
            DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

            # TODO: this is technically super brittle if the nix install path is not /nix/ 
            # we can fix this by going "up" from the bin folder in order to get the actual
            # path. We control the relative path inside the binary which is always "bin/" in
            # the derivation
            SUB_FOLDER=$(echo ''${DIR} | awk -F/ '{print $4}')

            # This is technically impure but python is a total PITA to deal with in
            # Nix because it assumes it can write all over the place and tracking
            # down a zillion packages to add for each thing from pypi is tedious and
            # Time consuming and also error prone.

            # Instead we get around this by creating a virtual environment for 
            # Python instead. Messy but effective. 

            # Create a VirtualEnv
            VENV_FOLDER="''${HOME}/.bin/lib/nix-python-installs/''${SUB_FOLDER}"
            if [ ! -d "''${VENV_FOLDER}" ]; then
              echo "Running first time install of oci-cli. Creating new venv environment in path: \"''${VENV_FOLDER}\""
              # Note that the module venv was only introduced in python 3, so for 2.7
              # this needs to be replaced with a call to virtualenv
              ${pkgs.python38.interpreter} -m venv "''${VENV_FOLDER}"
            fi

            # TODO: Figure out if this is necessary
            # Under some circumstances it might be necessary to add your virtual
            # environment to PYTHONPATH, which you can do here too;
            #PYTHONPATH=$PWD/''${VENV_FOLDER}/${pkgs.python38.sitePackages}/:$PYTHONPATH

            source "''${VENV_FOLDER}/bin/activate"

            # Only install if we havent already installed things
            if [ ! -f "''${VENV_FOLDER}/installComplete" ]; then
              pip install oci oci-cli "requests[socks]"
              touch "''${VENV_FOLDER}/installComplete"
            fi

            # Call the installed oci binary with the args to this script
            exec ''${VENV_FOLDER}/bin/oci "$@"
            '';
      };
  };
}
