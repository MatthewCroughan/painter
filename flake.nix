{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules/iso-images.nix
      ];
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs { config.allowUnfree = true; inherit system; };
        packages = {
          painter = pkgs.callPackage ./components/painter {};
          speak-to-me = import ./components/speak-to-me;
          speak-to-me-whisper = pkgs.callPackage ./components/speak-to-me-whisper {};
        };
      };
      flake = {
      };
    };
}
