import os
import json
import tensorflow as tf
import pandas as pd
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau

print(f"TensorFlow version: {tf.__version__}")

# ======================
# CONFIG
# ======================
DATA_DIR = "dataset/"
CSV_FILE = "crop_disease_data.csv"

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
SEED = 42

# ✅ Save directly to backend folder so Python API + Node backend can use same files
BACKEND_MODELS_DIR = "../govi_sahaya_backend/ml/models"
os.makedirs(BACKEND_MODELS_DIR, exist_ok=True)

MODEL_PATH = os.path.join(BACKEND_MODELS_DIR, "onion_disease_model.h5")
BEST_PATH = os.path.join(BACKEND_MODELS_DIR, "best_model.h5")
META_PATH = os.path.join(BACKEND_MODELS_DIR, "model_metadata.json")
DISEASE_INFO_PATH = os.path.join(BACKEND_MODELS_DIR, "onion_disease_info.json")

print("🌿 Govi Sahaya - Onion Disease Model Training")
print("=" * 60)

# ======================
# Check dataset exists
# ======================
if not os.path.exists(DATA_DIR):
    raise FileNotFoundError(f"❌ Dataset directory '{DATA_DIR}' not found!")

# ======================
# Load CSV (optional info)
# ======================
if os.path.exists(CSV_FILE):
    print("\n📊 Loading disease information from CSV...")
    disease_df = pd.read_csv(CSV_FILE)
    print(f"✅ Loaded {len(disease_df)} disease records")
else:
    print(f"⚠️ CSV file '{CSV_FILE}' not found. Using empty info.")
    disease_df = pd.DataFrame(columns=["crop_name", "disease_name", "symptoms", "cause", "solution", "prevention"])

# ======================
# ✅ IMPORTANT FIX:
# Train generator = augmentation
# Val generator = ONLY rescale (no augmentation)
# ======================
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=25,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.15,
    zoom_range=0.2,
    horizontal_flip=True,
    vertical_flip=False,     # ✅ keep off for leaf diseases
    fill_mode="nearest",
    validation_split=0.2
)

val_datagen = ImageDataGenerator(
    rescale=1./255,
    validation_split=0.2
)

print("\n📂 Loading training data...")
train_data = train_datagen.flow_from_directory(
    DATA_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    subset="training",
    shuffle=True,
    seed=SEED
)

print("📂 Loading validation data...")
val_data = val_datagen.flow_from_directory(
    DATA_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    subset="validation",
    shuffle=False
)

num_classes = train_data.num_classes
print(f"\n✅ Found {num_classes} classes")

# ======================
# ✅ IMPORTANT FIX:
# Save class labels in correct index order (index -> name)
# ======================
inv_map = {v: k for k, v in train_data.class_indices.items()}
class_labels = [inv_map[i] for i in range(num_classes)]

print("\n📌 Class order (used by the model):")
for i, name in enumerate(class_labels):
    print(f"  {i}: {name}")

# Save model metadata for API
model_metadata = {
    "input_shape": [IMG_SIZE[0], IMG_SIZE[1], 3],
    "classes": class_labels
}

with open(META_PATH, "w") as f:
    json.dump(model_metadata, f, indent=2)

print(f"\n💾 Saved model_metadata.json to: {META_PATH}")

# ======================
# Build disease info JSON (FIXED MATCHING)
# ======================
def norm_text(x: str) -> str:
    s = "" if x is None else str(x)
    return s.strip().lower().replace(" ", "_").replace("-", "_")

def humanize(x: str) -> str:
    s = "" if x is None else str(x)
    return s.replace("_", " ").strip()

def build_recommendations(crop_name: str, disease_name: str):
    dlow = norm_text(disease_name).replace("_", " ").lower()
    rec = []

    # ✅ Powdery first (so it won't get caught by "mildew")
    if "powdery" in dlow:
        rec += [
            "🔸 Powdery Mildew detected",
            "💊 Chemical: Apply sulfur-based fungicide as recommended",
            "🌿 Organic: Potassium bicarbonate spray / neem-based spray",
            "🌬️ Improve air flow, avoid overcrowding",
            "💧 Avoid frequent leaf wetting",
        ]

    # ✅ Downy separate
    elif "downy" in dlow:
        rec += [
            "🔸 Downy Mildew detected",
            "💊 Chemical: Apply Metalaxyl + Mancozeb @ recommended dose",
            "🌿 Organic: Copper-based spray / Bordeaux mixture (1%)",
            "🚜 Improve field drainage to reduce moisture",
            "⏰ Avoid late evening irrigation",
            "📏 Ensure proper spacing for airflow",
        ]

    # ✅ Alternaria / Blotch
    elif ("alternaria" in dlow) or ("blotch" in dlow):
        rec += [
            "🔸 Alternaria / Blotch detected",
            "💊 Chemical: Apply Mancozeb 75% WP @ 2g/L or Chlorothalonil 75% WP @ 2g/L",
            "🌿 Organic: Neem oil spray (5ml/L) or Copper oxychloride 50% WP @ 3g/L",
            "✂️ Remove and destroy infected leaves immediately",
            "💧 Avoid overhead irrigation - use drip irrigation",
            "🌬️ Ensure proper plant spacing for air circulation",
            "🔄 Practice crop rotation",
        ]

    elif "healthy" in dlow:
        rec += [
            "✅ Plant looks healthy",
            "👀 Continue regular monitoring",
            "💧 Maintain proper watering and balanced nutrition",
            "🧹 Keep field clean and remove weeds",
        ]

    else:
        rec += [
            "🔸 Disease detected",
            "👨‍🌾 Consult agricultural expert for confirmation",
            "🧹 Maintain field hygiene and remove affected parts",
            "💧 Adjust irrigation to reduce leaf wetness",
        ]

    rec += [
        "",
        "📋 General Preventive Measures:",
        "• Maintain field sanitation",
        "• Scout plants 2-3 times per week",
        "• Avoid overhead irrigation when possible",
        "• Use crop rotation",
    ]
    return rec

# ✅ normalize CSV columns once
if not disease_df.empty:
    disease_df["crop_norm"] = disease_df["crop_name"].astype(str).apply(norm_text)
    disease_df["disease_norm"] = disease_df["disease_name"].astype(str).apply(norm_text)

disease_info = {}

for label in class_labels:
    parts = label.split("___")
    crop_name = parts[0] if len(parts) > 1 else "Unknown"
    disease_raw = parts[1] if len(parts) > 1 else label  # keep underscores for matching

    crop_norm = norm_text(crop_name)
    disease_norm = norm_text(disease_raw)

    info = None
    if not disease_df.empty:
        match = disease_df[
            (disease_df["crop_norm"] == crop_norm) &
            (disease_df["disease_norm"] == disease_norm)
        ]
        if not match.empty:
            info = match.iloc[0]

    if info is not None:
        disease_info[label] = {
            "crop_name": str(info["crop_name"]),
            "disease_name": humanize(str(info["disease_name"])),
            "symptoms": str(info["symptoms"]),
            "cause": str(info["cause"]),
            "solution": str(info["solution"]),
            "prevention": str(info["prevention"]),
            "recommendations": build_recommendations(str(info["crop_name"]), str(info["disease_name"])),
        }
    else:
        disease_info[label] = {
            "crop_name": crop_name,
            "disease_name": humanize(disease_raw),
            "symptoms": "Consult agricultural expert",
            "cause": "Environmental / fungal / bacterial / viral factors",
            "solution": "Consult agricultural expert",
            "prevention": "Follow best farming practices",
            "recommendations": build_recommendations(crop_name, disease_raw),
        }

with open(DISEASE_INFO_PATH, "w", encoding="utf-8") as f:
    json.dump(disease_info, f, indent=2, ensure_ascii=False)

print(f"💾 Saved onion_disease_info.json to: {DISEASE_INFO_PATH}")

# ======================
# Build Transfer Learning Model
# ======================
print("\n🏗️ Building MobileNetV2 Transfer Learning model...")

base_model = MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet"
)
base_model.trainable = False

model = Sequential([
    base_model,
    GlobalAveragePooling2D(),
    BatchNormalization(),
    Dense(512, activation="relu"),
    Dropout(0.5),
    Dense(256, activation="relu"),
    Dropout(0.3),
    Dense(num_classes, activation="softmax")
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()

callbacks = [
    EarlyStopping(monitor="val_accuracy", patience=6, restore_best_weights=True, verbose=1),
    ModelCheckpoint(BEST_PATH, monitor="val_accuracy", save_best_only=True, verbose=1),
    ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2, min_lr=1e-7, verbose=1)
]

# ======================
# Train Phase 1 (frozen)
# ======================
print("\n🚀 Phase 1: Training with frozen base...")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=15,
    callbacks=callbacks,
    verbose=1
)

# ======================
# Train Phase 2 (fine-tune)
# ======================
print("\n🔥 Phase 2: Fine-tuning...")
base_model.trainable = True

# Freeze early layers to avoid destroying pretrained features
for layer in base_model.layers[:100]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.fit(
    train_data,
    validation_data=val_data,
    epochs=15,
    callbacks=callbacks,
    verbose=1
)

# Save final model
model.save(MODEL_PATH)
print(f"\n✅ Final model saved to: {MODEL_PATH}")
print(f"✅ Best model saved to : {BEST_PATH}")

# Evaluate
print("\n📈 Final Evaluation:")
train_loss, train_acc = model.evaluate(train_data, verbose=0)
val_loss, val_acc = model.evaluate(val_data, verbose=0)

print(f"   Training Accuracy: {train_acc*100:.2f}%")
print(f"   Validation Accuracy: {val_acc*100:.2f}%")

print("\n🎉 Training completed successfully!")
print("=" * 60)
