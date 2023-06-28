let
  pkgs = (import (builtins.getFlake "github:jtojnar/nixpkgs/e94a1d428913cb0faa4e26b61e6eb37ebf8ea5ec") { system = "x86_64-linux"; });
  myPython = pkgs.python3.withPackages (p: [
    p.vosk-python
  ]);
  voskModel = pkgs.fetchzip {
    url = "https://alphacephei.com/vosk/models/vosk-model-en-us-0.21.zip";
    sha256 = "sha256-Jp4uVthoSQGjymJWJX/xRiIeEjPlbdqsTZyDQQM9xf0=";
  };
  smallModel = pkgs.fetchzip {
    url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip";
    sha256 = "sha256-CIoPZ/krX+UW2w7c84W3oc1n4zc9BBS/fc8rVYUthuY=";
  };
in
pkgs.writeShellScriptBin "speak-to-me" ''
  export PATH=${pkgs.nerd-dictation}/bin:${pkgs.pulseaudio}/bin:$PATH
  export PAINTER_VOSK_MODEL_DIR=${smallModel}
  ${myPython}/bin/python ${./speak-to-me.py}
''

