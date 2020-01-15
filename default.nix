{ pkgs ? import ./pin.nix }:

pkgs.stdenv.mkDerivation {
  name = "hello-world";
  src = builtins.fetchurl "https://jappieklooster.nl";
  args = ["-e" ./builder.sh];
  buildInputs = [pkgs.curl];
}
