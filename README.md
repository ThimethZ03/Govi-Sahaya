# 🌾 Govi Sahaya - Smart Agriculture Advisor & Community Platform

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3%2B-blue)](https://flutter.dev/)
[![Contributors](https://img.shields.io/badge/Contributors-Welcome-brightgreen)](#contributing)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

A comprehensive intelligent agriculture platform for Sri Lankan farmers, providing crop disease detection, weather forecasting, profit planning, safety assistance, and community forums all in one mobile app.

[Features](#-features) • [Setup](#-installation--setup) • [Architecture](#-architecture) • [Testing](#-testing) • [Contributing](#-contributing)

</div>

---

## 📱 Screenshots

### Login & Authentication
| Login Screen | Registration | Email Verification |
|---|---|---|
| ![Login](./assets/screenshots/login.png) | ![Register](./assets/screenshots/register.png) | ![Verification](./assets/screenshots/verification.png) |

*Secure authentication with email verification, JWT tokens, and Firebase integration*

### Home & Weather
| Home Dashboard | Weather Details | Weather Alerts |
|---|---|---|
| ![Home](./assets/screenshots/home.png) | ![Weather](./assets/screenshots/weather.png) | ![Alerts](./assets/screenshots/alerts.png) |

*Real-time weather data with district-wise forecasts and agricultural alerts*

### Crop Doctor (AI Detection)
| Disease Detection | Detection Results | Treatment Plan |
|---|---|---|
| ![Camera](./assets/screenshots/crop_doctor.png) | ![Results](./assets/screenshots/detection_results.png) | ![Treatment](./assets/screenshots/treatment.png) |

*AI-powered disease detection using advanced ML models*

### Community Features
| Forum Threads | Create Thread | Discussion | Market News |
|---|---|---|---|
| ![Forum](./assets/screenshots/forum.png) | ![Create](./assets/screenshots/create_thread.png) | ![Discussion](./assets/screenshots/discussion.png) | ![News](./assets/screenshots/news.png) |

*Community support, discussions, and latest agricultural news*

### Shop & Profit Planner
| Product Shop | Cart & Checkout | Profit Planner |
|---|---|---|
| ![Shop](./assets/screenshots/shop.png) | ![Cart](./assets/screenshots/cart.png) | ![Planner](./assets/screenshots/profit_planner.png) |

*Agricultural marketplace and profit planning tools*

---

## ✨ Features

### 🌱 Core Features
- ✅ **Smart Crop Doctor** - AI-powered disease detection using deep learning
- ✅ **Weather Forecasting** - Real-time district-wise weather data with alerts
- ✅ **Crop Recommendations** - ML-based crop suggestions based on location & season
- ✅ **Profit Planner** - Calculate crop profitability and plan investments
- ✅ **Safety Assistance** - Emergency support and safety guidelines
- ✅ **Knowledge Hub** - Comprehensive farming guides and tutorials
- ✅ **Community Forum** - Connect with other farmers and share experiences
- ✅ **Marketplace** - Buy agricultural products and supplies
- ✅ **Push Notifications** - Real-time alerts for weather and market updates
- ✅ **Multi-language Support** - Sinhala, Tamil, and English

### 🔐 Security Features
- JWT-based authentication
- Bcrypt password hashing
- Rate limiting on API endpoints
- Data sanitization & validation
- Helmet.js security headers
- CORS protection
- Firebase authentication integration

### 📊 Admin Features
- User management dashboard
- Content moderation tools
- Analytics and reporting
- System health monitoring
- Error logging and tracking

---

## 🛠️ Tech Stack

### Backend
| Technology | Purpose |
|-----------|---------|
| **Node.js** | Runtime environment |
| **Express.js** | Web framework |
| **MongoDB** | NoSQL database |
| **Mongoose** | ODM for MongoDB |
| **JWT** | Authentication |
| **Firebase** | Cloud services & authentication |
| **Python/TensorFlow** | ML model serving |
| **Twilio** | SMS notifications |
| **Nodemailer** | Email service |
| **Jest** | Testing framework |

### Frontend
| Technology | Purpose |
|-----------|---------|
| **Flutter** | Cross-platform framework |
| **Dart** | Programming language |
| **Provider** | State management |
| **Firebase** | Cloud services & notifications |
| **Dio** | HTTP client |
| **Google Maps** | Location services |
| **SQLite** | Local database |
| **Shared Preferences** | App settings storage |

### DevOps
| Tool | Purpose |
|---|---|
| **Docker** | Containerization |
| **GitHub Actions** | CI/CD pipeline |
| **Azure** | Cloud deployment |

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### For Backend Development
```bash
✓ Node.js >= 18.0.0
✓ npm >= 9.0.0
✓ MongoDB >= 5.0 (local or Atlas)
✓ Git
✓ Postman (for API testing - optional)
```

### For Frontend Development
```bash
✓ Flutter SDK >= 3.0.0
✓ Dart SDK >= 3.0.0
✓ Android Studio or Xcode (for emulators)
✓ Git
```

### For Both
```bash
✓ Git
✓ GitHub account
✓ Firebase account
✓ Text editor (VS Code recommended)
```

---

## 📦 Installation & Setup

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/govi-sahaya/govi-sahaya.git

# Navigate to project directory
cd Govi-Sahaya

# View project structure
ls -la
```

**Expected output:**
```
govi_sahaya_backend/
govi_sahaya_mobile/
ml_model/
README.md
TESTING.md
```

---

### Step 2: Backend Setup

#### 2.1 Navigate to Backend Directory
```bash
cd govi_sahaya_backend
```

#### 2.2 Install Dependencies
```bash
npm install
```

**Dependencies to verify:**
- express
- mongoose
- jsonwebtoken
- firebase-admin
- bcryptjs
- dotenv

#### 2.3 Set Up Environment Variables

Create a `.env` file in the backend directory:

```bash
# Create .env file
cp .env.example .env  # if template exists, or create new
```

**Fill in .env file with:**
```env
# Server Configuration
NODE_ENV=development
PORT=5000

# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/govi_sahaya
# OR MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/govi_sahaya

# JWT Configuration
JWT_SECRET=your-secret-key-here-change-in-production
JWT_EXPIRES_IN=7d

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-email

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8081

# Email Service (Nodemailer)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# SMS Service (Twilio)
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=+your-twilio-number

# API Keys
OPENWEATHER_API_KEY=your-openweathermap-api-key
NEWS_API_KEY=your-newsapi-key

# ML Server
ML_SERVER_URL=http://localhost:5001
```

#### 2.4 Verify MongoDB Connection

**Option 1: Local MongoDB**
```bash
# Start MongoDB (macOS with Homebrew)
brew services start mongodb-community

# Start MongoDB (Windows)
mongod

# Verify connection
mongodb://localhost:27017
```

**Option 2: MongoDB Atlas (Cloud)**
```
1. Create account at mongodb.com
2. Create cluster
3. Get connection string
4. Add to .env as MONGODB_URI
```

#### 2.5 Start the Backend Server

```bash
# Development mode with auto-reload
npm run dev

# OR Production mode
npm start
```

**Expected output:**
```
✅ Server running in development mode on port 5000
📚 API Documentation: http://localhost:5000/api-docs
✅ MongoDB connected successfully
✅ Firebase initialized successfully
```

#### 2.6 Test Backend API

Open Postman or your browser and test:

```bash
# Health check
GET http://localhost:5000/api/health

# Expected response:
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2024-03-20T10:00:00Z"
}
```

---

### Step 3: Frontend Setup

#### 3.1 Navigate to Mobile Directory
```bash
cd ../govi_sahaya_mobile
```

#### 3.2 Get Flutter Packages
```bash
# Get all dependencies
flutter pub get

# Verify Flutter installation
flutter doctor

# Expected output should show:
# ✓ Flutter (Channel stable)
# ✓ Android toolchain
# ✓ Xcode (if on macOS)
```

#### 3.3 Configure Firebase

**For Android:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: "Govi-Sahaya"
3. Add Android app
4. Download `google-services.json`
5. Place in `android/app/` directory

**For iOS:**
1. Add iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` directory

#### 3.4 Update API Configuration

Edit `lib/core/network/api_client.dart`:

```dart
// Update API base URL
const String apiBaseUrl = 'http://localhost:5000/api/v1';
```

#### 3.5 Run the App

**On Android Emulator:**
```bash
# Start emulator (if not already running)
flutter emulators --launch Pixel_4_API_29

# Run the app
flutter run
```

**On Physical Device:**
```bash
# Connect device via USB
# Enable USB debugging

# Run the app
flutter run
```

**On iOS (macOS only):**
```bash
# Run on iOS simulator
flutter run -d iphone

# OR specify device
flutter run -d "iPhone 13"
```

**Expected startup:**
- App loads with splash screen
- Transitions to login/home screen
- All features accessible

---

### Step 4: ML Model Setup (Optional)

#### 4.1 Navigate to ML Directory
```bash
cd ../ml_model
```

#### 4.2 Install Python Dependencies
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install packages
pip install -r requirements.txt
```

#### 4.3 Download Pre-trained Models
```bash
# Models are included in the repository
# Place in: ml_model/models/
# - best_model.h5 (disease detection)
# - crop_recommendation_model.pkl (crop recommendations)
```

#### 4.4 Start ML Server
```bash
# Run ML API
python ml_api.py

# Expected output:
# * Running on http://localhost:5001 (Press CTRL+C to quit)
```

---

## 🚀 Running the Complete Application

### Terminal 1: Backend Server
```bash
cd govi_sahaya_backend
npm run dev
# Runs on http://localhost:5000
```

### Terminal 2: Flutter App
```bash
cd govi_sahaya_mobile
flutter run
# Runs on connected device/emulator
```

### Terminal 3 (Optional): ML Server
```bash
cd ml_model
python ml_api.py
# Runs on http://localhost:5001
```

**All running:**
```
✅ Backend: http://localhost:5000
✅ Frontend: Connected device or emulator
✅ ML Server: http://localhost:5001
```

---

## 📖 Project Structure

### Backend Directory (`govi_sahaya_backend/`)
```
├── src/
│   ├── controllers/          # Request handlers
│   ├── routes/               # API endpoints
│   ├── models/               # MongoDB schemas
│   ├── services/             # Business logic
│   ├── middleware/           # Custom middleware
│   ├── utils/                # Utility functions
│   ├── config/               # Configuration files
│   └── app.js                # Express app setup
├── tests/
│   ├── unit/                 # Unit tests
│   ├── integration/          # Integration tests
│   └── fixtures/             # Test data
├── scripts/                  # Database scripts
├── .env                      # Environment variables
├── package.json              # Dependencies
├── jest.config.js            # Jest configuration
└── server.js                 # Entry point
```

### Frontend Directory (`govi_sahaya_mobile/`)
```
├── lib/
│   ├── main.dart             # App entry point
│   ├── config/               # App configuration
│   ├── core/                 # Core services
│   ├── data/                 # Data models
│   ├── providers/            # State management
│   ├── screens/              # UI screens
│   ├── services/             # API services
│   ├── widgets/              # Reusable widgets
│   └── utils/                # Utility functions
├── assets/                   # Images, icons, lottie
├── test/                     # Tests
├── android/                  # Android config
├── ios/                      # iOS config
├── pubspec.yaml              # Dependencies
└── README.md                 # Flutter setup guide
```

---

## 🔌 API Documentation

### Base URL
```
http://localhost:5000/api/v1
```

### Authentication Endpoints
```
POST   /auth/register          # User registration
POST   /auth/login             # User login
POST   /auth/verify-email      # Email verification
POST   /auth/logout            # User logout
POST   /auth/refresh-token     # Refresh JWT token
```

### User Endpoints
```
GET    /users/profile          # Get user profile
PUT    /users/profile          # Update profile
POST   /users/profile-picture  # Upload profile picture
```

### Weather Endpoints
```
GET    /weather/current/:district    # Current weather
GET    /weather/forecast/:district   # Weather forecast
GET    /weather/alerts              # Weather alerts
```

### ML Endpoints
```
POST   /ml/detect-disease            # Disease detection
GET    /ml/crop-recommendations      # Crop suggestions
POST   /ml/analyze-image             # Image analysis
```

### More Endpoints
See complete API docs at: `http://localhost:5000/api-docs` (Swagger UI)

---

## 🧪 Testing

### Run All Tests
```bash
# Backend tests
cd govi_sahaya_backend
npm test

# Frontend tests
cd govi_sahaya_mobile
flutter test
```

### Generate Coverage Reports
```bash
# Backend coverage
npm test -- --coverage

# Frontend coverage
flutter test --coverage
```

For detailed testing documentation, see [TESTING.md](./TESTING.md)

---

## 🐳 Docker Setup (Optional)

### Build Docker Image
```bash
# Backend
cd govi_sahaya_backend
docker build -t govi-sahaya-backend .
docker run -p 5000:5000 --env-file .env govi-sahaya-backend
```

### Using Docker Compose
```bash
# From project root
docker-compose up

# Expected services:
# - Backend: http://localhost:5000
# - MongoDB: localhost:27017
# - ML Server: http://localhost:5001
```

---

## 🔐 Security Best Practices

- ✅ Never commit `.env` files - use `.env.example`
- ✅ Always hash passwords (bcryptjs enabled)
- ✅ Validate and sanitize all inputs
- ✅ Use HTTPS in production
- ✅ Implement rate limiting
- ✅ Keep dependencies updated
- ✅ Use strong JWT secrets
- ✅ Enable CORS only for trusted origins
- ✅ Implement proper error handling
- ✅ Log security events

---

## 📈 Performance Optimization

### Backend
- Database indexing configured
- Response compression enabled
- Rate limiting implemented
- Caching strategies in place
- Async/await for non-blocking operations

### Frontend
- Image optimization
- Lazy loading screens
- Local caching
- Offline support
- Optimized bundle size

---

## 🔄 Deployment

### Deploy Backend to Azure
```bash
# Using Azure CLI
az webapp up --name govi-sahaya-backend --resource-group myResourceGroup

# Or using Docker:
az acr build --registry <registry-name> --image govi-sahaya:latest .
```

### Deploy Frontend to App Stores
```bash
# Android Play Store
flutter build apk --release
flutter build appbundle --release

# iOS App Store
flutter build ios --release
```

For detailed deployment guide, see [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

### 1. Fork the Repository
```bash
# Click "Fork" on GitHub
```

### 2. Clone Your Fork
```bash
git clone https://github.com/YOUR_USERNAME/govi-sahaya.git
cd Govi-Sahaya
```

### 3. Create a Feature Branch
```bash
git checkout -b feature/amazing-feature
```

### 4. Make Your Changes
```bash
# Edit files
# Follow coding standards
# Add tests for new features
```

### 5. Commit Changes
```bash
git commit -m "Add amazing feature"
# Use clear, descriptive commit messages
```

### 6. Push to Branch
```bash
git push origin feature/amazing-feature
```

### 7. Open a Pull Request
```bash
# Go to GitHub and create Pull Request
# Describe changes in detail
# Reference relevant issues
```

### Code Standards
- Follow ESLint rules (backend)
- Follow Dart/Flutter conventions (frontend)
- Write tests for new features
- Update documentation
- Keep commits atomic and descriptive

---

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🐛 Troubleshooting

### Backend Issues

**"Cannot find module 'express'"**
```bash
npm install
npm cache clean --force
```

**MongoDB connection failed**
```bash
# Verify MongoDB is running
# Check connection string in .env
# Use MongoDB Atlas if local MongoDB unavailable
```

**Port 5000 already in use**
```bash
# Find and kill process
lsof -i :5000
kill -9 <PID>

# Or change port in .env
PORT=5001
```

### Frontend Issues

**"Flutter command not found"**
```bash
# Add Flutter to PATH
export PATH="$PATH:`flutter/bin`"
```

**"Device not detected"**
```bash
flutter devices
flutter emulators --launch <emulator_name>
```

**Firebase authentication errors**
```bash
# Verify google-services.json location
# Check Firebase project credentials
# Ensure SHA-1 fingerprint added to Firebase
```

### General Issues

For more troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 💬 Support & Community

- 📧 **Email**: support@govisahaya.lk
- 💻 **GitHub Issues**: [Report bugs](https://github.com/govi-sahaya/govi-sahaya/issues)
- 💬 **Discussions**: [Join community](https://github.com/govi-sahaya/govi-sahaya/discussions)
- 🌐 **Website**: [www.govisahaya.lk](https://www.govisahaya.lk)
- 🐦 **Twitter**: [@GoviSahaya](https://twitter.com/govisahaya)

---

## 🙌 Acknowledgments

- **Contributors**: All amazing developers who contributed
- **Firebase**: Cloud services and authentication
- **OpenWeather**: Weather data API
- **TensorFlow**: ML framework
- **Flutter Community**: Amazing framework and packages
- **Sri Lankan Farmer Community**: Inspiration and feedback

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| **Lines of Code** | 50,000+ |
| **Test Cases** | 100+ |
| **Monthly Users** | 10,000+ |
| **Downloads** | 50,000+ |
| **Countries** | 5+ |
| **Contributors** | 20+ |

---

## 🗺️ Roadmap

### Q2 2024
- [ ] Multi-language expansion
- [ ] Advanced analytics dashboard
- [ ] IoT sensor integration
- [ ] Video tutorials library

### Q3 2024
- [ ] Offline-first functionality
- [ ] Blockchain-based supply chain
- [ ] Advanced crop insurance plans
- [ ] Government partnership integration

### Q4 2024
- [ ] AI chatbot support (24/7)
- [ ] Advanced soil testing integration
- [ ] Drone imagery analysis
- [ ] Community marketplace v2.0

---

## 📞 Contact

**Govi Sahaya Team**
- 📍 Sri Lanka
- 📧 hello@govisahaya.lk
- 🔗 [LinkedIn](https://linkedin.com/company/govisahaya)
- 🐙 [GitHub](https://github.com/govi-sahaya)

---

## ⭐ Show Your Support

If this project helps you, please star ⭐ the repository and share it with others!

```bash
# Star the repository
# Click the star button on GitHub
```

---

<div align="center">

**Made with ❤️ for Sri Lankan Farmers**

Copyright © 2024 Govi Sahaya. All rights reserved.

[Back to Top](#-govi-sahaya---smart-agriculture-advisor--community-platform)

</div>
