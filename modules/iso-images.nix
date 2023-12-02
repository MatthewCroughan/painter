{ self, ... }:

{
  perSystem = { lib, pkgs, system, ... }:
  let
    mkIsoImage = { gpuType, system, pkgs, self }: let
      nixosSystem = self.inputs.nixpkgs.lib.nixosSystem {
        inherit system;
      modules = [
        "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
        ({ config, pkgs, ... }:
        {
          environment.systemPackages = [
            self.packages.${system}.painter
            self.packages.${system}.speak-to-me-whisper
            pkgs.pqiv
          ];
        })
        ({ config, pkgs, ... }: {
          config = lib.mkIf (gpuType == "nvidia") {
            nixpkgs.config.allowUnfree = true;
            services.xserver.videoDrivers = [ "nvidia" ];
            hardware.opengl.enable = true;
            hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
            hardware.nvidia.nvidiaPersistenced = true;
            hardware.nvidia = {
              powerManagement.enable = false;
            };
            services.xserver.displayManager.gdm.wayland = false;
            zramSwap = {
              enable = true;
              memoryPercent = 90;
            };
          };
        })
      ];
    };
    in nixosSystem.config.system.build.isoImage;
  in
  {
    packages = {
      iso-image-nvidia = mkIsoImage { gpuType = "nvidia"; inherit system pkgs self; };
    };
  };
}

