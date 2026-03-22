# 🌾 AI Crop Doctor - Feature Implementation

## Overview
AI Crop Doctor is an intelligent crop disease detection system that uses machine learning to identify crop diseases from images and provide treatment recommendations.

---

## 🎯 Features Implemented

### 1. **ML Model Training** ✅
- **Location**: `ml_model/train_model_enhanced.py`
- **Architecture**: MobileNetV2 with transfer learning
- **Capabilities**:
  - Train on crop disease dataset
  - Automatic model checkpoint saving
  - Early stopping to prevent overfitting
  - Learning rate reduction on plateau
  - Export to backend-compatible format

### 2. **Backend API Endpoints** ✅

#### ML Disease Detection
- **Route**: `POST /api/v1/ml/detect-disease`
- **Purpose**: Predict disease from crop image
- **Auth**: Required (Bearer token)
- **Request**: Multipart form-data with image
- **Response**: Disease prediction with confidence score

#### Crop Doctor Detection & History
- **Route**: `POST /api/v1/crop-doctor/detect`
- **Purpose**: Save detection result to database
- **Route**: `GET /api/v1/crop-doctor/history`
- **Purpose**: Retrieve user's detection history
- **Route**: `GET /api/v1/crop-doctor/:id`
- **Purpose**: Get specific detection details
- **Route**: `PUT /api/v1/crop-doctor/:id/feedback`
- **Purpose**: Submit feedback for model improvement

### 3. **Database Models** ✅

#### Disease Model
```javascript
{
  name: String (required, unique),
  scientificName: String,
  category: String (enum: potato, tomato, pumpkin, onion, general),
  description: String,
  symptoms: [String],
  causes: [String],
  severity: String (enum: low, moderate, high, critical),
  affectedCrops: [String],
  treatment: {
    organic: [String],
    chemical: [String],
    preventive: [String]
  }
}
```

#### CropDoctor Model (Detection Records)
```javascript
{
  user: ObjectId (ref: User),
  image: {
    url: String,
    publicId: String,
    size: Number,
    mimeType: String
  },
  predictions: [{
    disease: ObjectId,
    diseaseName: String,
    confidence: Number,
    severity: String
  }],
  topPrediction: {
    disease: ObjectId,
    diseaseName: String,
    confidence: Number,
    severity: String
  },
  cropType: String,
  location: {
    district: String,
    city: String,
    coordinates: { latitude, longitude }
  },
  userFeedback: {
    isAccurate: Boolean,
    actualDisease: String,
    comments: String,
    rating: Number
  }
}
```

### 4. **Flutter Mobile UI** ✅

#### Screens
- **`crop_upload_screen.dart`**: Image upload/capture interface
  - Camera and gallery picker integration
  - Image preview
  - Analysis trigger button
  
- **`crop_doctor_screen.dart`**: Results & history display
  - Disease diagnosis results
  - Treatment recommendations (organic & chemical)
  - Confidence score visualization
  - Disease history timeline
  - Multi-language support

#### Services & Providers
- **`ml_service.dart`**: Backend API integration
  - Image upload handling
  - Response normalization
  - Error handling
  
- **`crop_doctor_service.dart`**: History & detection tracking
  - Save detection results
  - Retrieve user history
  - Feedback submission
  
- **`ml_provider.dart`**: State management
  - Disease prediction state
  - Loading states
  - Error handling

#### Models
- **`disease_model.dart`**: Disease data structure
  - Fields: id, name, description, cause, solution, prevention
  - fromJson factory method for API response parsing
  - Safe type conversion & fallback values

---

## 🛠️ Technology Stack

### Backend
- **Framework**: Node.js + Express.js
- **Database**: MongoDB + Mongoose
- **ML Service**: Python Flask (separate service)
- **File Upload**: In-memory with Cloudinary integration
- **Authentication**: JWT Bearer tokens

### ML/AI
- **Framework**: TensorFlow/Keras
- **Model**: MobileNetV2 (pretrained, fine-tuned)
- **Input Size**: 224x224 pixels
- **Batch Processing**: Batch size 32
- **Optimization**: Adam optimizer with learning rate scheduling

### Frontend
- **Framework**: Flutter
- **State Management**: Provider package
- **HTTP Client**: Dio
- **Image Handling**: image_picker, Image package
- **Localization**: i18n support (English, Sinhala, Tamil)

---

## 📁 File Structure

```
govi_sahaya_backend/
├── ml/
│   ├── crop_disease_data.csv
│   ├── ml_api.py (Flask API server)
│   ├── models/ (trained model files)
│   ├── inference/
│   ├── preprocessing/
│   └── uploads/
├── src/
│   ├── models/
│   │   ├── Disease.js
│   │   └── CropDoctor.js
│   ├── routes/
│   │   ├── mlRoutes.js
│   │   └── cropDoctorRoutes.js
│   └── controllers/
│       ├── mlController.js
│       └── cropDoctorController.js

govi_sahaya_mobile/
└── lib/
    ├── screens/ai_crop_doctor/
    │   ├── crop_doctor_screen.dart
    │   └── crop_upload_screen.dart
    ├── services/
    │   ├── ml_service.dart
    │   └── crop_doctor_service.dart
    ├── providers/
    │   ├── ml_provider.dart
    │   └── ...
    └── models/
        └── disease_model.dart

ml_model/
├── train_model_enhanced.py
├── crop_disease_data.csv
└── requirements.txt
```

---

## 🚀 API Flow

### Disease Detection Flow
```
1. User selects/captures image in Flutter app
   ↓
2. Image sent to backend: POST /api/v1/ml/detect-disease
   ↓
3. Backend receives image, writes to temp file
   ↓
4. Call ML service (Python): detectDisease(image_path)
   ↓
5. ML returns: { predictions: [...], diseaseDetails: {...} }
   ↓
6. Backend processes response, creates CropDoctor record
   ↓
7. Backend returns to Flutter:
   {
     success: true,
     data: {
       id, name, description, cause, solution, prevention,
       confidence, risk_level, organic_treatment, chemical_treatment
     }
   }
   ↓
8. Flutter displays results with treatment recommendations
```

---

## 🔐 Security Features

✅ **Authentication**: JWT-based token validation on all protected endpoints
✅ **File Validation**: Image size limits, MIME type checking
✅ **Error Handling**: Safe error messages without exposing system details
✅ **Data Privacy**: User-specific history isolation
✅ **Timeout Protection**: Connection timeouts on API calls (15-30 seconds)

---

## 📊 Model Performance Considerations

- **Input Size**: 224x224 (optimized for MobileNetV2)
- **Inference Time**: ~1-3 seconds per image
- **Model Size**: ~40MB (lightweight for mobile)
- **Accuracy**: Tested on crop disease dataset
- **Confidence Threshold**: Predictions with confidence > 50% recommended

---

## 🧪 Testing Recommendations

### Backend Testing
```bash
# Test health endpoint
curl http://localhost:5000/api/v1/ml/health

# Test disease detection
curl -X POST http://localhost:5000/api/v1/ml/detect-disease \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@crop_image.jpg"

# Get detection history
curl http://localhost:5000/api/v1/crop-doctor/history \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Frontend Testing
- Test with various crop images
- Test error scenarios (no image, network error, timeout)
- Verify multi-language UI text
- Test offline handling

---

## 📝 Future Enhancements

- [ ] Support for multiple disease predictions
- [ ] Real-time model updates
- [ ] Community feedback integration
- [ ] Advanced analytics dashboard
- [ ] Crop-specific model variants
- [ ] Integrated pest management API

---

## 👨‍💻 Developer Notes

### To Run ML Model Training
```bash
cd ml_model
python train_model_enhanced.py
```

### To Start ML API Server (if separate)
```bash
cd govi_sahaya_backend/ml
python ml_api.py
```

### To Test Backend Endpoints
```bash
cd govi_sahaya_backend
npm test -- cropDoctorController.test.js
```

### To Run Flutter App
```bash
cd govi_sahaya_mobile
flutter pub get
flutter run
```

---

## 📋 Checklist for Viva/Presentation

- [x] ML model training complete
- [x] Backend API endpoints tested
- [x] Flutter UI screens implemented
- [x] Database models created
- [x] Authentication integrated
- [x] Multi-language support added
- [x] Error handling implemented
- [x] Documentation complete

---

## 📞 Support & Contact

For questions or issues related to this feature, refer to:
- Backend: `govi_sahaya_backend/README.md`
- Mobile: `govi_sahaya_mobile/README.md`
- ML: `ml_model/requirements.txt`
