{ openai-whisper-cpp, fetchurl, writeShellScriptBin, python3 }:
let
  largeModel = fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin";
    sha256 = "sha256-11eV7P8/g7X6qJ0ZAGBK2MeAq9Vzn65AbeGfI+zZitE=";
  };
  mediumModel = fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
    sha256 = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  };
  model = largeModel;
  whisperWithCuda = (import (builtins.getFlake "github:matthewcroughan/nixpkgs/79eec243144d6ec528f4b8f492fbd47684cd16bd") { system = "x86_64-linux"; config.allowUnfree = true; }).openai-whisper-cpp;
in
writeShellScriptBin "speak-to-me-whisper" ''
  ${whisperWithCuda}/bin/whisper-cpp-stream -m ${model} "$@" | ${python3}/bin/python ${./filter.py}
''
