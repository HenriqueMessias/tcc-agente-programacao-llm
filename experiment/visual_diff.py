"""Pipeline de comparação visual (seção 6.7): grayscale -> resize 128x72 ->
blur gaussiano sigma=2 -> SSIM + % de pixels diferentes, com máscaras opcionais
para regiões dinâmicas."""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from skimage.metrics import structural_similarity

TARGET_SIZE = (128, 72)
BLUR_SIGMA = 2
SSIM_THRESHOLD = 0.95
MAX_DIFFERENT_PIXELS_RATIO = 0.20
PIXEL_DIFF_THRESHOLD = 25 / 255


def _preprocess(image_path: Path, mask_path: Path | None = None) -> np.ndarray:
    img = Image.open(image_path).convert("L")
    if mask_path is not None and mask_path.exists():
        mask = Image.open(mask_path).convert("L").resize(img.size)
        img_arr = np.array(img)
        mask_arr = np.array(mask) > 127
        img_arr = img_arr.copy()
        img_arr[mask_arr] = 128
        img = Image.fromarray(img_arr)
    img = img.resize(TARGET_SIZE)
    img = img.filter(ImageFilter.GaussianBlur(radius=BLUR_SIGMA))
    return np.array(img).astype(np.float64) / 255.0


def compare(captured_path: Path, oracle_path: Path, mask_path: Path | None = None) -> dict:
    a = _preprocess(captured_path, mask_path)
    b = _preprocess(oracle_path, mask_path)
    score, diff = structural_similarity(a, b, data_range=1.0, full=True)
    different_pixels = np.sum(np.abs(a - b) > PIXEL_DIFF_THRESHOLD)
    total_pixels = a.size
    different_ratio = different_pixels / total_pixels
    passed = score >= SSIM_THRESHOLD and different_ratio <= MAX_DIFFERENT_PIXELS_RATIO
    return {
        "ssim": float(score),
        "different_pixels_ratio": float(different_ratio),
        "passed": bool(passed),
    }
