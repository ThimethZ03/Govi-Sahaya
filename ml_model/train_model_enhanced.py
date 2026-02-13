import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout, BatchNormalization
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from tensorflow.keras.applications import MobileNetV2
import os
import json
import pandas as pd


print(f"TensorFlow version: {tf.__version__}")


# Configuration
DATA_DIR = 'dataset/'
CSV_FILE = 'crop_disease_data.csv'
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 30


print("🌿 Govi Sahaya - Enhanced Model Training")
print("=" * 60)


# Check if dataset exists
if not os.path.exists(DATA_DIR):
    print(f"❌ Error: Dataset directory '{DATA_DIR}' not found!")
    print("Please create a 'dataset' folder with disease subfolders")
    exit(1)


# Load CSV data
if os.path.exists(CSV_FILE):
    print("\n📊 Loading disease information from CSV...")
    disease_df = pd.read_csv(CSV_FILE)
    print(f"✅ Loaded {len(disease_df)} disease records")
else:
    print(f"⚠️ Warning: CSV file '{CSV_FILE}' not found. Creating empty dataframe.")
    disease_df = pd.DataFrame(columns=['crop_name', 'disease_name', 'symptoms', 'cause', 'solution', 'prevention'])


# Data Augmentation
datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=40,
    width_shift_range=0.3,
    height_shift_range=0.3,
    shear_range=0.3,
    zoom_range=0.3,
    horizontal_flip=True,
    vertical_flip=True,
    fill_mode='nearest',
    validation_split=0.2
)


# Load Training Data
print("\n📂 Loading training data...")
try:
    train_data = datagen.flow_from_directory(
        DATA_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training',
        shuffle=True
    )
except Exception as e:
    print(f"❌ Error loading training data: {e}")
    print("\nMake sure your dataset folder structure is:")
    print("dataset/")
    print("  ├── Tomato___Healthy/")
    print("  ├── Tomato___Early_blight/")
    print("  └── ...")
    exit(1)


# Load Validation Data
print("📂 Loading validation data...")
val_data = datagen.flow_from_directory(
    DATA_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation',
    shuffle=False
)


# Get class labels
class_labels = list(train_data.class_indices.keys())
num_classes = len(class_labels)


print(f"\n✅ Found {num_classes} disease classes:")
for i, label in enumerate(class_labels):
    print(f"   {i+1}. {label}")


# Create metadata mapping
print("\n📝 Creating disease metadata...")
metadata = {}
for label in class_labels:
    parts = label.split('___')
    if len(parts) == 2:
        crop_name, disease_name = parts
    else:
        crop_name = "Unknown"
        disease_name = label
    
    disease_name_cleaned = disease_name.replace('_', ' ')
    
    # Try to find in CSV
    if not disease_df.empty:
        match = disease_df[
            (disease_df['crop_name'].str.lower() == crop_name.lower()) &
            (disease_df['disease_name'].str.lower() == disease_name_cleaned.lower())
        ]
        
        if not match.empty:
            info = match.iloc[0]
            metadata[label] = {
                'crop_name': str(info['crop_name']),
                'disease_name': str(info['disease_name']),
                'symptoms': str(info['symptoms']),
                'cause': str(info['cause']),
                'solution': str(info['solution']),
                'prevention': str(info['prevention'])
            }
            continue
    
    # Default metadata if not found in CSV
    metadata[label] = {
        'crop_name': crop_name,
        'disease_name': disease_name_cleaned,
        'symptoms': 'Consult agricultural expert for symptoms',
        'cause': 'Various factors including environmental conditions',
        'solution': 'Consult agricultural expert for treatment',
        'prevention': 'Follow best farming practices'
    }


# Save metadata
os.makedirs('output', exist_ok=True)

with open('output/class_labels.json', 'w') as f:
    json.dump(class_labels, f, indent=2)

with open('output/disease_metadata.json', 'w') as f:
    json.dump(metadata, f, indent=2)

print("💾 Metadata saved to output/ folder")


# Build Transfer Learning Model
print("\n🏗️ Building MobileNetV2 Transfer Learning model...")

base_model = MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'
)

base_model.trainable = False


model = Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    BatchNormalization(),
    Dense(512, activation='relu'),
    Dropout(0.5),
    BatchNormalization(),
    Dense(256, activation='relu'),
    Dropout(0.4),
    Dense(num_classes, activation='softmax')
])


# Compile
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)


print("\n📊 Model Architecture:")
model.summary()


# Callbacks
callbacks = [
    EarlyStopping(
        monitor='val_accuracy',
        patience=7,
        restore_best_weights=True,
        verbose=1
    ),
    ModelCheckpoint(
        'output/best_model.h5',
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=3,
        min_lr=1e-7,
        verbose=1
    )
]


# Train Phase 1
print("\n🚀 Phase 1: Training with frozen base...")
print("=" * 60)

history1 = model.fit(
    train_data,
    validation_data=val_data,
    epochs=15,
    callbacks=callbacks,
    verbose=1
)


# Fine-tuning Phase 2
print("\n🔥 Phase 2: Fine-tuning...")
base_model.trainable = True

for layer in base_model.layers[:100]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

history2 = model.fit(
    train_data,
    validation_data=val_data,
    epochs=15,
    callbacks=callbacks,
    verbose=1
)


# Save final model
model.save('output/govi_sahaya_model.h5')
print("\n✅ Model saved to output/govi_sahaya_model.h5")


# Convert to TFLite
print("\n📱 Converting to TFLite for mobile...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open('output/govi_sahaya_model.tflite', 'wb') as f:
    f.write(tflite_model)
print("✅ TFLite model saved to output/govi_sahaya_model.tflite")


# Evaluate
print("\n📈 Final Evaluation:")
train_loss, train_acc = model.evaluate(train_data, verbose=0)
val_loss, val_acc = model.evaluate(val_data, verbose=0)

print(f"   Training Accuracy: {train_acc*100:.2f}%")
print(f"   Validation Accuracy: {val_acc*100:.2f}%")

print("\n🎉 Training completed successfully!")
print("=" * 60)
print("\n📁 Output files:")
print("   - output/govi_sahaya_model.h5")
print("   - output/best_model.h5")
print("   - output/govi_sahaya_model.tflite")
print("   - output/class_labels.json")
print("   - output/disease_metadata.json")
