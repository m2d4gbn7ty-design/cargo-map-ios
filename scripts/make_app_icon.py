import json
import os

from PIL import Image, ImageDraw

base = os.path.join("App", "Resources", "Assets.xcassets")
appicon = os.path.join(base, "AppIcon.appiconset")
os.makedirs(appicon, exist_ok=True)

W = 1024
img = Image.new("RGB", (W, W), (27, 107, 224))
draw = ImageDraw.Draw(img)
for y in range(W):
    t = y / W
    draw.line(
        [(0, y), (W, y)],
        fill=(int(27 * (1 - t) + 8 * t), int(107 * (1 - t) + 62 * t), int(224 * (1 - t) + 176 * t)),
    )

cx, cy = W * 0.5, W * 0.44
R = W * 0.26
draw.polygon(
    [(cx - R * 0.62, cy + R * 0.55), (cx + R * 0.62, cy + R * 0.55), (cx, cy + R * 1.70)],
    fill=(255, 255, 255),
)
draw.ellipse([cx - R, cy - R, cx + R, cy + R], fill=(255, 255, 255))
draw.ellipse([cx - R * 0.36, cy - R * 0.36, cx + R * 0.36, cy + R * 0.36], fill=(27, 107, 224))
img.save(os.path.join(appicon, "AppIcon-1024.png"), "PNG")

with open(os.path.join(appicon, "Contents.json"), "w", encoding="utf-8") as handle:
    json.dump(
        {
            "images": [
                {
                    "filename": "AppIcon-1024.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024",
                }
            ],
            "info": {"author": "xcode", "version": 1},
        },
        handle,
        indent=2,
        ensure_ascii=False,
    )
    handle.write("\n")

with open(os.path.join(base, "Contents.json"), "w", encoding="utf-8") as handle:
    json.dump({"info": {"author": "xcode", "version": 1}}, handle, indent=2)
    handle.write("\n")

print("icon + asset catalog written")
print("png bytes:", os.path.getsize(os.path.join(appicon, "AppIcon-1024.png")))
