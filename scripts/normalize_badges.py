import os
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

INPUT_DIR = os.path.join(BASE_DIR, "design", "badges", "Figma Icons")
OUTPUT_DIR = os.path.join(BASE_DIR, "design", "badges", "normalized")

CANVAS_SIZE = 512
PADDING_RATIO = 0.12

# Ignora píxeles muy transparentes para no contar glow, brillos suaves, etc.
ALPHA_THRESHOLD = 40

# Ajustes manuales para archivos concretos que visualmente quedan pequeños.
# Usa el nombre exacto del archivo, incluyendo extensión.
# 1.00 = sin cambio
# 1.08 = 8% más grande
SCALE_OVERRIDES = {
    "Mente - Diamante.png": 1.80,
    "Emocional -Diamante Prismatico.png": 1.25,
    # Añade aquí más si hace falta:
    # "Otro Badge.png": 1.06,
}

print("BASE_DIR:", BASE_DIR)
print("INPUT_DIR:", INPUT_DIR)
print("OUTPUT_DIR:", OUTPUT_DIR)
print("INPUT existe:", os.path.exists(INPUT_DIR))


def get_alpha_bbox(img: Image.Image, alpha_threshold: int):
    alpha = img.getchannel("A")
    mask = alpha.point(lambda p: 255 if p > alpha_threshold else 0)
    return mask.getbbox()


def process_image(path, output_path):
    img = Image.open(path).convert("RGBA")

    # 1. Recorte inteligente ignorando transparencias suaves
    bbox = get_alpha_bbox(img, ALPHA_THRESHOLD)

    # Fallback por si la imagen es rara
    if bbox is None:
        bbox = img.getbbox()

    if bbox is None:
        print("Imagen vacía, se omite:", path)
        return

    img = img.crop(bbox)

    # 2. Tamaño útil disponible
    target_size = int(CANVAS_SIZE * (1 - 2 * PADDING_RATIO))

    # 3. Escalar por lado mayor
    max_dim = max(img.width, img.height)
    if max_dim == 0:
        print("Imagen vacía tras crop, se omite:", path)
        return

    scale = target_size / max_dim
    new_width = max(1, int(round(img.width * scale)))
    new_height = max(1, int(round(img.height * scale)))

    img = img.resize((new_width, new_height), Image.LANCZOS)

    # 4. Override manual por nombre de archivo
    filename = os.path.basename(path)
    override_factor = SCALE_OVERRIDES.get(filename, 1.0)

    if override_factor != 1.0:
        override_width = max(1, int(round(img.width * override_factor)))
        override_height = max(1, int(round(img.height * override_factor)))
        img = img.resize((override_width, override_height), Image.LANCZOS)
        print(f"Override aplicado a {filename}: x{override_factor}")

    # 5. Canvas final
    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))

    # 6. Centrado
    x = (CANVAS_SIZE - img.width) // 2
    y = (CANVAS_SIZE - img.height) // 2

    canvas.paste(img, (x, y), img)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    canvas.save(output_path, "PNG")
    print("Guardado:", output_path)


found_png = False

for root, _, files in os.walk(INPUT_DIR):
    for file in files:
        if file.lower().endswith(".png"):
            found_png = True
            input_path = os.path.join(root, file)

            relative_path = os.path.relpath(root, INPUT_DIR)
            target_dir = os.path.join(OUTPUT_DIR, relative_path)
            output_path = os.path.join(target_dir, file)

            process_image(input_path, output_path)

if not found_png:
    print("No se encontraron PNGs.")

print("DONE ✅")
