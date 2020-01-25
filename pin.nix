let 
pinnedPkgs = 
    (builtins.fetchGit {
    # Descriptive name to make the store path easier to identify
    name = "nixos-pin-19.10.2019";
    url = https://github.com/nixos/nixpkgs/;
    rev = "7b97c8c0c8c450bcce24113d9a2bf2bfff1b75c9";
    }) ;
in
import pinnedPkgs {
    # since I also use this for clients I don't want to have to care
    config.allowUnfree = true; # took me too long to figure out
}
