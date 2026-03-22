"""
ML API Service for Govi-Sahaya
Crop Disease Detection using CNN Model
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
import json
import numpy as np
from PIL import Image
import io
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s]: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Create upload folder
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Load model metadata
MODEL_METADATA_PATH = '../govi_sahaya_backend/src/ml/models/model_metadata.json'

try:
    with open(MODEL_METADATA_PATH, 'r') as f:
        MODEL_METADATA = json.load(f)
        CLASS_NAMES = MODEL_METADATA['classes']
        INPUT_SHAPE = tuple(MODEL_METADATA['input_shape'])
        logger.info(f"✅ Loaded model metadata: {len(CLASS_NAMES)} classes")
except Exception as e:
    logger.warning(f"⚠️ Could not load model metadata: {e}")
    CLASS_NAMES = []
    INPUT_SHAPE = (224, 224, 3)

# Global model variable
model = None

def load_model():
    """Load the trained ML model"""
    global model
    
    try:
        import tensorflow as tf
        from tensorflow import keras
        
        model_path = '../govi_sahaya_backend/src/ml/models/onion_disease_model.h5'
        
        if os.path.exists(model_path):
            logger.info(f"📦 Loading model from {model_path}...")
            model = keras.models.load_model(model_path)
            logger.info("✅ Model loaded successfully!")
            return True
        else:
            logger.warning(f"⚠️ Model file not found: {model_path}")
            logger.info("💡 Using mock predictions until model is trained")
            return False
            
    except Exception as e:
        logger.error(f"❌ Error loading model: {e}")
        logger.info("💡 Using mock predictions")
        return False

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def preprocess_image(image_bytes):
    """Preprocess image for model prediction"""
    try:
        # Open image
        img = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to model input size
        img = img.resize((INPUT_SHAPE[0], INPUT_SHAPE[1]))
        
        # Convert to numpy array
        img_array = np.array(img)
        
        # Normalize to [0, 1]
        img_array = img_array.astype('float32') / 255.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
        
    except Exception as e:
        logger.error(f"Error preprocessing image: {e}")
        raise

def get_mock_prediction():
    """Generate mock prediction for testing"""
    if not CLASS_NAMES:
        return {
            'class': 'Onion___Purple_blotch',
            'confidence': 0.85,
            'probabilities': {
                'Onion___Purple_blotch': 0.85,
                'Onion___Healthy_leaves': 0.10,
                'Onion___Downy_mildew': 0.05
            }
        }
    
    # Randomly select a class
    import random
    selected_class = random.choice(CLASS_NAMES)
    confidence = 0.70 + random.random() * 0.25  # 0.70 to 0.95
    
    # Generate mock probabilities
    probabilities = {}
    remaining_prob = 1.0 - confidence
    
    for class_name in CLASS_NAMES[:5]:  # Top 5 classes
        if class_name == selected_class:
            probabilities[class_name] = confidence
        else:
            probabilities[class_name] = remaining_prob / 4
    
    return {
        'class': selected_class,
        'confidence': float(confidence),
        'probabilities': probabilities
    }

def predict_disease(img_array):
    """Predict disease from preprocessed image"""
    global model
    
    if model is None:
        # Return mock prediction
        logger.info("🎭 Generating mock prediction (model not loaded)")
        return get_mock_prediction()
    
    try:
        # Get model predictions
        predictions = model.predict(img_array, verbose=0)
        
        # Get predicted class
        predicted_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_idx])
        predicted_class = CLASS_NAMES[predicted_idx]
        
        # Get top 5 predictions
        top_indices = np.argsort(predictions[0])[-5:][::-1]
        probabilities = {
            CLASS_NAMES[idx]: float(predictions[0][idx])
            for idx in top_indices
        }
        
        return {
            'class': predicted_class,
            'confidence': confidence,
            'probabilities': probabilities
        }
        
    except Exception as e:
        logger.error(f"Error during prediction: {e}")
        return get_mock_prediction()

@app.route('/', methods=['GET'])
def index():
    """Health check endpoint"""
    return jsonify({
        'status': 'online',
        'service': 'Govi-Sahaya ML API',
        'version': '1.0.0',
        'model_loaded': model is not None,
        'num_classes': len(CLASS_NAMES),
        'endpoints': {
            'predict': '/predict',
            'health': '/health',
            'model_info': '/model/info'
        }
    })

@app.route('/health', methods=['GET'])
def health():
    """Detailed health check"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'model_metadata': {
            'num_classes': len(CLASS_NAMES),
            'input_shape': INPUT_SHAPE,
            'classes': CLASS_NAMES[:5] if len(CLASS_NAMES) > 5 else CLASS_NAMES
        }
    })

@app.route('/model/info', methods=['GET'])
def model_info():
    """Get model information"""
    try:
        with open(MODEL_METADATA_PATH, 'r') as f:
            metadata = json.load(f)
        
        return jsonify({
            'success': True,
            'metadata': metadata,
            'model_loaded': model is not None
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/predict', methods=['POST'])
def predict():
    """Predict disease from uploaded image"""
    try:
        # Check if file is in request
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No file uploaded'
            }), 400
        
        file = request.files['file']
        
        # Check if file is selected
        if file.filename == '':
            return jsonify({
                'success': False,
                'error': 'No file selected'
            }), 400
        
        # Check file extension
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': 'Invalid file type. Allowed: png, jpg, jpeg'
            }), 400
        
        # Read image bytes
        image_bytes = file.read()
        
        # Check file size
        if len(image_bytes) > MAX_FILE_SIZE:
            return jsonify({
                'success': False,
                'error': 'File too large. Max size: 16MB'
            }), 400
        
        logger.info(f"📸 Processing image: {file.filename}")
        
        # Preprocess image
        img_array = preprocess_image(image_bytes)
        logger.info("✅ Image preprocessed successfully")
        
        # Predict disease
        prediction = predict_disease(img_array)
        logger.info(f"🎯 Prediction: {prediction['class']} ({prediction['confidence']:.2%})")
        
        return jsonify({
            'success': True,
            **prediction
        })
        
    except Exception as e:
        logger.error(f"❌ Prediction error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/predict/batch', methods=['POST'])
def predict_batch():
    """Predict diseases from multiple images"""
    try:
        if 'files' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No files uploaded'
            }), 400
        
        files = request.files.getlist('files')
        
        if len(files) == 0:
            return jsonify({
                'success': False,
                'error': 'No files selected'
            }), 400
        
        if len(files) > 10:
            return jsonify({
                'success': False,
                'error': 'Maximum 10 files allowed per batch'
            }), 400
        
        results = []
        
        for file in files:
            try:
                if not allowed_file(file.filename):
                    results.append({
                        'filename': file.filename,
                        'success': False,
                        'error': 'Invalid file type'
                    })
                    continue
                
                image_bytes = file.read()
                img_array = preprocess_image(image_bytes)
                prediction = predict_disease(img_array)
                
                results.append({
                    'filename': file.filename,
                    'success': True,
                    **prediction
                })
                
            except Exception as e:
                results.append({
                    'filename': file.filename,
                    'success': False,
                    'error': str(e)
                })
        
        return jsonify({
            'success': True,
            'total': len(files),
            'results': results
        })
        
    except Exception as e:
        logger.error(f"Batch prediction error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.errorhandler(413)
def request_entity_too_large(error):
    """Handle file too large error"""
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum size: 16MB'
    }), 413

@app.errorhandler(500)
def internal_error(error):
    """Handle internal server error"""
    return jsonify({
        'success': False,
        'error': 'Internal server error'
    }), 500

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("🌾 Govi-Sahaya ML API Service")
    logger.info("=" * 60)
    
    # Try to load the model
    model_loaded = load_model()
    
    if not model_loaded:
        logger.warning("⚠️ Model not loaded - using mock predictions")
        logger.info("💡 To train the model, run: python train_model.py")
    
    logger.info("=" * 60)
    logger.info("🚀 Starting Flask server...")
    logger.info("📍 ML API URL: http://localhost:5001")
    logger.info("📍 Health Check: http://localhost:5001/health")
    logger.info("📍 Predict Endpoint: http://localhost:5001/predict")
    logger.info("=" * 60)
    
    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=5001,
        debug=True,
        use_reloader=False  # Disable reloader to prevent double loading
    )
