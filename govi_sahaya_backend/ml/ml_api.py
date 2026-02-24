"""
ML API Service for Govi-Sahaya
Crop Disease Detection using CNN Model (Multi-crop: Onion / Tomato / Pumpkin)

✅ FULL FIXED:
- Accepts BOTH form-data keys: "file" (Node) and "image" (Flutter)
- Returns fields Flutter UI can show properly:
  id, name, crop_name, description, organic_treatment, chemical_treatment,
  confidence, risk_level
- ALSO returns: symptoms, cause, solution, prevention
- ✅ Correct crop_name comes from class label (Onion/Tomato/Pumpkin) if JSON missing
- ✅ Disease name parsing works for ALL crops (not only Onion)
- Case-insensitive + normalized DISEASE_INFO lookup
- Safe defaults so organic/chemical NEVER come empty
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
import numpy as np
from PIL import Image
import io
import logging

# -----------------------------------
# Logging
# -----------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s]: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("govi-ml-api")

# -----------------------------------
# App
# -----------------------------------
app = Flask(__name__)
CORS(app)

# -----------------------------------
# Config
# -----------------------------------
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB
app.config["MAX_CONTENT_LENGTH"] = MAX_FILE_SIZE

# -----------------------------------
# Paths
# -----------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")

MODEL_PATH = os.path.join(MODELS_DIR, "onion_disease_model.h5")
MODEL_METADATA_PATH = os.path.join(MODELS_DIR, "model_metadata.json")

# Your file name is onion_disease_info.json (but it contains onion+pumpkin+tomato)
DISEASE_INFO_PATH = os.path.join(MODELS_DIR, "onion_disease_info.json")

# -----------------------------------
# Globals
# -----------------------------------
model = None
CLASS_NAMES = []
INPUT_SHAPE = (224, 224, 3)
DISEASE_INFO = {}
DISEASE_INFO_LOWER_KEYS = {}  # for case-insensitive lookup


# -----------------------------------
# Helpers
# -----------------------------------
def _safe_str(x):
    return "" if x is None else str(x)


def normalize_key(s: str) -> str:
    # normalize for matching differences in spaces/_/-
    return (
        _safe_str(s)
        .strip()
        .lower()
        .replace(" ", "_")
        .replace("-", "_")
    )


def split_class(class_name: str):
    """
    Supports:
      "Onion___Purple_blotch"
      "Tomato___Leaf_Mold"
      "Pumpkin___Powdery_Mildew"
    Returns (crop_part, disease_part)
    """
    s = _safe_str(class_name).strip()
    if "___" in s:
        crop, disease = s.split("___", 1)
        return crop.strip(), disease.strip()
    return "", s


def crop_from_class(class_name: str) -> str:
    crop, _ = split_class(class_name)
    crop = _safe_str(crop).replace("_", " ").strip()
    return crop if crop else "Unknown"


def disease_from_class_readable(class_name: str) -> str:
    _, disease = split_class(class_name)
    d = _safe_str(disease).replace("_", " ").strip()
    return d if d else "Unknown"


def risk_level_from_confidence(confidence: float):
    if confidence >= 0.85:
        return "High"
    elif confidence >= 0.60:
        return "Medium"
    return "Low"


# -----------------------------------
# Load Metadata
# -----------------------------------
def load_metadata():
    global CLASS_NAMES, INPUT_SHAPE

    if not os.path.exists(MODEL_METADATA_PATH):
        logger.error("❌ model_metadata.json not found")
        return False

    with open(MODEL_METADATA_PATH, "r", encoding="utf-8") as f:
        meta = json.load(f)

    CLASS_NAMES = meta.get("classes", [])
    INPUT_SHAPE = tuple(meta.get("input_shape", [224, 224, 3]))

    logger.info(f"✅ Loaded metadata: {len(CLASS_NAMES)} classes")
    return True


# -----------------------------------
# Load Disease Info
# -----------------------------------
def load_disease_info():
    global DISEASE_INFO, DISEASE_INFO_LOWER_KEYS

    if os.path.exists(DISEASE_INFO_PATH):
        with open(DISEASE_INFO_PATH, "r", encoding="utf-8") as f:
            DISEASE_INFO = json.load(f)

        # lower-key mapping for case-insensitive search
        DISEASE_INFO_LOWER_KEYS = {k.lower(): k for k in DISEASE_INFO.keys()}

        logger.info("✅ Loaded onion_disease_info.json")
        logger.info(f"✅ Disease info entries: {len(DISEASE_INFO)}")
    else:
        DISEASE_INFO = {}
        DISEASE_INFO_LOWER_KEYS = {}
        logger.warning("⚠️ onion_disease_info.json not found (DISEASE_INFO empty)")


def find_disease_info(class_name: str):
    """
    ✅ Robust lookup:
    - exact match
    - case-insensitive match
    - normalized match (handles small formatting differences)
    """
    if not class_name:
        return {}

    # exact
    if class_name in DISEASE_INFO:
        return DISEASE_INFO.get(class_name, {})

    # case-insensitive
    key = DISEASE_INFO_LOWER_KEYS.get(class_name.lower())
    if key:
        return DISEASE_INFO.get(key, {})

    # normalized scan
    target = normalize_key(class_name)
    for raw_key in DISEASE_INFO.keys():
        if normalize_key(raw_key) == target:
            return DISEASE_INFO.get(raw_key, {})

    return {}


def build_description(symptoms: str, cause: str):
    parts = []
    s = _safe_str(symptoms).strip()
    c = _safe_str(cause).strip()

    if s:
        parts.append(f"Symptoms: {s}")
    if c:
        parts.append(f"Cause: {c}")

    text = "\n\n".join(parts).strip()
    return text if text else "No description available"


def fallback_solution(solution: str):
    sol = _safe_str(solution).strip()
    return sol if sol else "Consult agricultural expert"


# -----------------------------------
# Load Model
# -----------------------------------
def load_model():
    global model
    from tensorflow import keras

    if not os.path.exists(MODEL_PATH):
        logger.error("❌ Model file not found")
        return False

    logger.info("📦 Loading ML model...")
    model = keras.models.load_model(MODEL_PATH)
    logger.info("✅ Model loaded successfully")
    return True


# -----------------------------------
# Preprocess Image
# -----------------------------------
def preprocess_image(image_bytes: bytes):
    """
    Convert bytes -> RGB -> resize -> normalize -> (1, H, W, 3)
    """
    img = Image.open(io.BytesIO(image_bytes))

    if img.mode != "RGB":
        img = img.convert("RGB")

    # INPUT_SHAPE = (224, 224, 3) -> resize to (224,224)
    img = img.resize((INPUT_SHAPE[0], INPUT_SHAPE[1]))

    arr = np.array(img).astype("float32") / 255.0
    arr = np.expand_dims(arr, axis=0)
    return arr


# -----------------------------------
# Predict
# -----------------------------------
def predict_disease(img_array):
    """
    Returns JSON in the format Flutter DiseaseModel expects
    + extra fields (symptoms, cause, solution, prevention)
    """
    preds = model.predict(img_array, verbose=0)[0]
    best_idx = int(np.argmax(preds))
    confidence = float(preds[best_idx])

    class_name = CLASS_NAMES[best_idx] if best_idx < len(CLASS_NAMES) else "Unknown"
    info = find_disease_info(class_name)

    # ✅ Crop name must be Onion/Tomato/Pumpkin correctly
    crop_name = info.get("crop_name") or crop_from_class(class_name) or "Unknown"

    # ✅ disease name must remove crop prefix correctly
    disease_name = info.get("disease_name") or disease_from_class_readable(class_name)

    symptoms = info.get("symptoms") or "Consult agricultural expert"
    cause = info.get("cause") or "Environmental / fungal / bacterial / viral factors"
    solution = info.get("solution") or "Consult agricultural expert"
    prevention = info.get("prevention") or "Follow best farming practices"

    description = build_description(symptoms, cause)

    # Map solution -> organic + chemical (so Flutter always shows something)
    sol_text = fallback_solution(solution)
    organic_treatment = sol_text
    chemical_treatment = sol_text

    return {
        # ✅ Flutter DiseaseModel keys
        "id": class_name,
        "name": disease_name,
        "name_sinhala": info.get("name_sinhala", ""),
        "crop_name": crop_name,
        "description": description,
        "organic_treatment": organic_treatment,
        "chemical_treatment": chemical_treatment,
        "image_url": "",
        "confidence": confidence,
        "risk_level": risk_level_from_confidence(confidence),

        # ✅ Extra fields (optional)
        "class": class_name,
        "disease_name": disease_name,
        "symptoms": symptoms,
        "cause": cause,
        "solution": solution,
        "prevention": prevention,

        # ✅ Extra debug field (helps Node controller too)
        "info": info,
    }


# -----------------------------------
# Routes
# -----------------------------------
@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "model_loaded": model is not None,
        "num_classes": len(CLASS_NAMES),
        "disease_info_loaded": len(DISEASE_INFO),
    }), 200


@app.route("/predict", methods=["POST"])
def predict():
    try:
        # ✅ Node backend sends key = "file"
        # ✅ Flutter sends key = "image"
        upload = request.files.get("file") or request.files.get("image")

        if not upload:
            return jsonify({
                "success": False,
                "error": "No image uploaded. Use form-data key 'file' (backend) or 'image' (flutter)."
            }), 400

        if upload.filename == "":
            return jsonify({"success": False, "error": "No file selected"}), 400

        image_bytes = upload.read()
        if not image_bytes:
            return jsonify({"success": False, "error": "Empty file"}), 400

        img_array = preprocess_image(image_bytes)
        result = predict_disease(img_array)

        logger.info(
            f"🎯 Prediction: {result['crop_name']} - {result['name']} ({result['confidence']*100:.2f}%)"
        )

        result["success"] = True
        return jsonify(result), 200

    except Exception as e:
        logger.exception("❌ Prediction error")
        return jsonify({"success": False, "error": str(e)}), 500


# -----------------------------------
# Main
# -----------------------------------
if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("🌾 Govi-Sahaya ML API Service")
    logger.info("=" * 60)

    meta_ok = load_metadata()
    load_disease_info()
    model_ok = load_model() if meta_ok else False

    logger.info(f"Metadata loaded: {meta_ok}")
    logger.info(f"Model loaded: {model_ok}")
    logger.info("🚀 Starting server at http://localhost:5001")
    logger.info("=" * 60)

    app.run(host="0.0.0.0", port=5001, debug=True, use_reloader=False)