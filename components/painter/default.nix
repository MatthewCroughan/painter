{ pkgs }:
let
  myOverridenPython = pkgs.python3.override {
    packageOverrides = (self: super: {
      diffusers = self.buildPythonPackage {
        pname = "diffusers";
        version = "0.24.0";
        src = self.pkgs.fetchFromGitHub {
          owner = "huggingface";
          repo = "diffusers";
          rev = "618260409f5c0ac6b6cbf79ed21ef51ba57db1c7";
          sha256 = "sha256-iq5qRnXAgRadR2lSSzOcaYMx8dqRt9FlcZIpHLRROvs=";
        };
        postPatch = ''
          substituteInPlace ./src/diffusers/utils/testing_utils.py --replace \
            'raise ImportError(BACKENDS_MAPPING["opencv"][1].format("export_to_video"))' 'import cv2'
        '';
        doCheck = false;
        propagatedBuildInputs = with self; [
          setuptools
          pillow
          numpy
          regex
          requests
          importlib-metadata
          huggingface-hub
          opencv4
          safetensors
          omegaconf
        ];
      };
      compel = self.buildPythonPackage rec {
        pname = "compel";
        version = "2.0.2";
        pyproject = true;
        src = self.pkgs.fetchFromGitHub {
          owner = "damian0815";
          repo = "compel";
          rev = "v${version}";
          hash = "sha256-OHldDlHtxSs112rmy/DsZPV6TIhsmfAzcxH2rjJ9cR4=";
        };
        nativeBuildInputs = with self; [
          setuptools
          wheel
        ];
        propagatedBuildInputs = with self; [
          diffusers
          pyparsing
          torch-bin
          (transformers.override {torch = self.torch-bin; })
        ];
      
        pythonImportsCheck = [ "compel" ];
      }; 

    });
  };
  myPython = myOverridenPython.withPackages (p: with p; [
    diffusers
    (transformers.override { torch = p.torch-bin; })
    (accelerate.override { torch = p.torch-bin; })
    (compel.override { torch = p.torch-bin; })
  ]);
#  papercut-lora = import <nix/fetchurl.nix> {
#    name = "papercut.safetensors";
#    url = "https://civitai.com/api/download/models/133503";
#    hash = "sha256-mPFynYWOe/cZKDeX5FZhM3zpFZQbgyYAJuFX2UljxAI=";
#  };
#  christmas-lora = import <nix/fetchurl.nix> {
#    name = "christmas-critters.safetensors";
#    url = "https://civitai.com/api/download/models/232800";
#    hash = "sha256-D69tY5XBQvj2BiMQYBUkmAbnlcB8y9R0Z0v3rz/O5eg=";
#  };
  sdxl-turbo = pkgs.fetchgit {
    url = "https://huggingface.co/stabilityai/sdxl-turbo.git";
    branchName = "main";
    fetchLFS = true;
    nonConeMode = true;
    sparseCheckout = [
      "/*"
      "!text_encoder/model.safetensors"
      "!text_encoder_2/model.safetensors"
      "!unet/diffusion_pytorch_model.safetensors"
      "!vae/diffusion_pytorch_model.safetensors"
      "!sd_xl_turbo_1.0.safetensors"
    ];
    rev = "2c4b5b9e8c65b03b4cd101620ca468508e51f677";
    sha256 = "sha256-VX0s42OGEZ5ipE3xN7NeiKhVGwfYGoFnuixbz/aIECU=";
  };

in pkgs.writeShellScriptBin "painter" ''
  export PAINTER_MODEL_PATH=${builtins.trace sdxl-turbo.outPath sdxl-turbo}
  mkdir gen
  ${pkgs.imagemagick}/bin/convert -size 123x456 xc:white out.png
  ${pkgs.pqiv}/bin/pqiv -t -s -F --fade-duration=1 -d 1 out.png &
  ${myPython}/bin/python ${./painter.py}
''

