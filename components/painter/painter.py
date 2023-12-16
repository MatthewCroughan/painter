from PIL import Image, PngImagePlugin
import sys
import time
#import random
import torch
import os
from diffusers import AutoPipelineForText2Image
#from diffusers import AutoPipelineForImage2Image
from compel import Compel, ReturnedEmbeddingsType


turbo_id = os.getenv("PAINTER_MODEL_PATH")
#turbo_id = "/home/astraluser/.cache/huggingface/hub/models--stabilityai--sdxl-turbo/snapshots/6a16f412e1acf6e413cda1abe869f32888a156fa"
#turbo_id = "stabilityai/sdxl-turbo"
base = AutoPipelineForText2Image.from_pretrained(turbo_id, torch_dtype=torch.float16, variant="fp16", use_safetensors=True)
base.to("cuda")

compel = Compel(tokenizer=[base.tokenizer, base.tokenizer_2] , text_encoder=[base.text_encoder, base.text_encoder_2], returned_embeddings_type=ReturnedEmbeddingsType.PENULTIMATE_HIDDEN_STATES_NON_NORMALIZED, requires_pooled=[False, True], truncate_long_prompts=False)

negative_prompt = "lowres, deformed, worst "

def make_image(prompt, conditioning, pooled, negative_conditioning, negative_pooled, res, steps):
    image1 = base(
            prompt_embeds=conditioning, 
            pooled_prompt_embeds=pooled, 
            negative_prompt_embeds=negative_conditioning, 
            negative_pooled_prompt_embeds=negative_pooled, 
            height=res, 
            width=res, 
            num_inference_steps=steps,
            guidance_scale=1.0,
    ).images[0]
    return image1


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
    else:
        print("---normal")
        with torch.no_grad():
            conditioning, pooled = compel.build_conditioning_tensor(prompt)
            negative_conditioning, negative_pooled = compel.build_conditioning_tensor(negative_prompt)
            [conditioning, negative_conditioning] = compel.pad_conditioning_tensors_to_same_length([conditioning, negative_conditioning])
            image = make_image(prompt, conditioning, pooled, negative_conditioning, negative_pooled, 768, 4)
            conditioning = None
            pooled = None
            nagative_conditioning = None
            negative_pooled = None
            image.save("out.png")
            metadata.add_text("Prompt", prompt)
            metadata.add_text("Style", "normal")
            metadata.add_text("Model", "sdxl-turbo")
            image.save(f"./gen/{int(time.time())}.png", pnginfo=metadata)
