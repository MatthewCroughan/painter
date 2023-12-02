from PIL import Image, PngImagePlugin
import sys
import time
import torch
import os
from diffusers import AutoPipelineForText2Image

turbo_id = os.getenv("PAINTER_MODEL_PATH")
paper_lora_id = os.getenv("PAINTER_PAPERCUT_MODEL_PATH")
christmas_lora_id = os.getenv("PAINTER_CHRISTMAS_MODEL_PATH")

base = AutoPipelineForText2Image.from_pretrained(turbo_id, torch_dtype=torch.float16, variant="fp16", use_safetensors=True)
base.to("cuda")

base_loaded = AutoPipelineForText2Image.from_pretrained(turbo_id, torch_dtype=torch.float16, variant="fp16", use_safetensors=True)
base_loaded.to("cuda")
base_loaded.load_lora_weights(paper_lora_id)
base_loaded.load_lora_weights(christmas_lora_id)

#init_image = Image.open(r"{}".format(mask_image_path))
count = 0

print()
print("---------------------")
print("PAINTER: Prompt Ready")
print("---------------------")
print()

for line in sys.stdin:
    prompt = line.rstrip()
    metadata = PngImagePlugin.PngInfo()
    print()
    print("------")
    print("PAINTER::PROMPT: ", prompt)
    print("------")
    print()
    if (prompt == "" or prompt.isspace() == True):
        pass
    elif "christmas" in prompt.lower() and "paper" in prompt.lower() and "lora" in prompt.lower():
        print("--- using both paper and chritmas loras ")
        image = base_loaded(prompt="papercut ral-chrcrts "+prompt , num_inference_steps=4, guidance_scale=1.0, width=768, height=768,).images[0]
        metadata.add_text("Style", "papercut_and_christmas_critters_loras")
    elif "christmas" in prompt.lower() and "lora" in prompt.lower():
        print("--- using christmas lora")
        image = base_loaded(prompt="ral-chrcrts "+prompt , num_inference_steps=4, guidance_scale=1.0, width=768, height=768,).images[0]
        metadata.add_text("Style", "christmas_critters_lora")
    elif "paper" in prompt.lower() and "lora" in prompt.lower():
        print("--- using paper lora")
        image = base_loaded(prompt="papercut "+prompt , num_inference_steps=4, guidance_scale=1.0, width=768, height=768,).images[0]
        metadata.add_text("Style", "papercut_lora")
    else:
        print("---normal")
        image = base(prompt=prompt , num_inference_steps=4, guidance_scale=1.0, width=768, height=768,).images[0]
        metadata.add_text("Style", "normal")
    image.save("out.png")

    metadata.add_text("Prompt", prompt)
    metadata.add_text("Model", "sdxl-turbo")
    image.save(f"./gen/{int(time.time())}.png", pnginfo=metadata)
#    init_image = image
#    count = count+1
