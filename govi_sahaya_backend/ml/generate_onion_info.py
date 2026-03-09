import csv
import json

CSV_PATH = "crop_disease_data.csv"              # <-- put your csv filename here
OUT_PATH = "models/onion_disease_info.json"

# map CSV disease_name -> model class name format
# Example CSV: Purple_Blotch  -> Onion___Purple_Blotch
def to_model_key(disease_name: str):
    # Keep underscores same as model
    return f"Onion___{disease_name.strip()}"

data = {}

with open(CSV_PATH, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        crop = (row.get("crop_name") or "").strip()
        if crop.lower() != "onion":
            continue

        disease = (row.get("disease_name") or "").strip()
        if not disease:
            continue

        key = to_model_key(disease)

        data[key] = {
            "crop_name": crop,
            "disease_name": disease.replace("_", " "),
            "symptoms": (row.get("symptoms") or "").strip(),
            "cause": (row.get("cause") or "").strip(),
            "solution": (row.get("solution") or "").strip(),
            "prevention": (row.get("prevention") or "").strip(),
        }

with open(OUT_PATH, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"✅ Saved {len(data)} onion diseases to {OUT_PATH}")
