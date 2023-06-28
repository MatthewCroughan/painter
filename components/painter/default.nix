let
  pkgs = import ( builtins.fetchTarball {
    #url = "https://github.com/NixOS/nixpkgs/archive/6add9f882954b20287d54009b9c61c4ff6cadd79.tar.gz";#(newest)
    url = "https://github.com/NixOS/nixpkgs/archive/963006aab35e3e8ebbf6052b6bf4ea712fdd3c28.tar.gz";
    sha256 = "1f9xk07n2nzn3mj5b1rrkfv5v3ryrj7danp3mlr5z0zyrkdsdjvy";
  }) { system = "x86_64-linux"; config.allowUnfree = true; };



  myOverridenPython = pkgs.python3.override {

    packageOverrides = (self: super: {
      diffusers = self.buildPythonPackage rec {
        pname = "diffusers";
        version = "0.16.1";
        src = self.fetchPypi {
          inherit pname version;
          sha256 = "sha256-TNdAA4LIbYXghCVVDeGxqB1O0DYj+9S82Dd4ZNnEbv4=";
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
        ];
      };

      controlnet = self.buildPythonPackage rec {
        pname = "controlnet_aux";
        version = "0.0.3";
        src = self.fetchPypi {
          inherit pname version;
          sha256 = "sha256-61zjrV05kdOu/1vbVCw0S6zXonFG+UJtv28CSIvQOTU=";
        };
        postPatch = ''
          substituteInPlace ./setup.py --replace \
            'opencv-python' 'numpy'
        '';
        doCheck = false;
        propagatedBuildInputs = with self; [
          numpy
          opencv4
          einops
          importlib-metadata
          filelock
          pillow
          huggingface-hub
          torch-bin
          torchvision-bin
          timm2
          #(timm.override { torchvision = self.torchvision-bin; torch = self.torch-bin; })
          scikit-image
        ];
      };

      timm2 = self.buildPythonPackage rec {
        pname = "timm";
        version = "0.9.2";
        src = self.pkgs.fetchFromGitHub {
          owner = "huggingface";
          repo = "pytorch-image-models";
          rev = "refs/tags/v${version}";
          hash = "sha256-gYrc8ds6urZvwDsTnzPjxjSTiAGzUD3RlCf0wogCrDI=";
        };
        doCheck = false;
        propagatedBuildInputs = with self; [
          huggingface-hub
          pyyaml
          safetensors
          torch-bin
          torchvision-bin
        ];
      };

    });
  };

  myPython = myOverridenPython.withPackages (p: with p; [
    controlnet
    diffusers
    (transformers.override { torch = p.torch-bin; })
    (accelerate.override { torch = p.torch-bin; })
  ]);

  stable-diffusion = pkgs.fetchgit {
    url = "https://huggingface.co/runwayml/stable-diffusion-v1-5.git";
    branchName = "fp16";
    fetchLFS = true;
    rev = "ded79e214aa69e42c24d3f5ac14b76d568679cc2";
    sha256 = "sha256-UMG5l04X3AVPJF4z9uXy2eBM0FtuKWFpzUvKH0KGeCU=";
  };

  stable_diffusion_mega = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/huggingface/diffusers/v0.16.1/examples/community/stable_diffusion_mega.py";
    sha256 = "sha256-aNmL9ZCBgBF4wsURmNBLItmbRzz3iwxgpkBP71Ev/WU=";
  };

in

pkgs.writeShellScriptBin "painter" ''
  export PAINTER_MODEL_PATH=${stable-diffusion}
  cp --no-preserve=mode ${stable_diffusion_mega} /tmp/stable_diffusion_mega.py
  export PAINTER_PIPELINE_PATH=/tmp/stable_diffusion_mega.py
  export PAINTER_MASK_IMAGE_PATH=${./mask_blur.png}

  ${myPython}/bin/python ${./painter.py}
''

