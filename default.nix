{ pkgs ? import ./pin.nix }:

let 
  scrollback = pkgs.fetchurl {
    url = "https://tools.suckless.org/ii/patches/ssl/ii-1.7-ssl.diff";
    sha1 = "md2yw4h8h6lpkajk7k9rk2zw0wn480qn";
  };
in
pkgs.stdenv.mkDerivation {
  name = "hello-world";
  src = builtins.fetchurl "https://jappieklooster.nl";
  args = ["-e" ./builder.sh];
  buildInputs = [pkgs.curl (pkgs.ii.overrideAttrs (oldAttrs: {
    patches =  [ scrollback ];
    buildInputs = [ pkgs.openssl ];
  }))];
}
