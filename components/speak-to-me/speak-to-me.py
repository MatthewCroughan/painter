import sys, os, time, subprocess, fcntl, json
import vosk

vosk.SetLogLevel(-1)
vosk_model_dir = os.getenv("PAINTER_VOSK_MODEL_DIR")


sample_rate = 44100

#parecexe = "/nix/store/ss1lkr49kh2gy26a6x90y104b00dyimf-pulseaudio-15.0/bin/parec"
parecexe = "parec"
cmd = (parecexe, "--record", "--rate=%d" % sample_rate, "--channels=1", "--format=s16ne", "--latency=10")

ps = subprocess.Popen(cmd, stdout=subprocess.PIPE)
flags = fcntl.fcntl(ps.stdout.fileno(), fcntl.F_GETFL)
fcntl.fcntl(ps.stdout, fcntl.F_SETFL, flags | os.O_NONBLOCK)

OPT_NOPARTIALS = True

model = vosk.Model(vosk_model_dir)
rec = vosk.KaldiRecognizer(model, sample_rate)
block_size = 104_8576
json_text_partial_prev = ""

rec.SetMaxAlternatives(2)

while True:
    time.sleep(0.1)
    data = ps.stdout.read(block_size)
    if data:
        ok = rec.AcceptWaveform(data)
        if ok:
            json_text = rec.Result()
            json_text_partial_prev = ""
            json_data = json.loads(json_text)
            if OPT_NOPARTIALS:
                text = json_data["alternatives"][0]["text"].strip()
                if text:
                    print(text, flush=True)
            else:
                print("\x0d", end="", flush=True)
                for x in json_data["alternatives"]:
                    print(" -", x["text"], flush=True)
                print(flush=True)
            rec.Reset()
        elif not OPT_NOPARTIALS:
            json_text = rec.PartialResult()
            if json_text_partial_prev != json_text:
                json_text_partial_prev = json_text
                json_data = json.loads(json_text)
                print("\x0d", json_data["partial"], end="", flush=True)

#json_text = rec.FinalResult()

