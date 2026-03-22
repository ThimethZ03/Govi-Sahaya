# 📁 Repository Structure & Documentation Map

## 📚 Documentation Files

```
Govi-Sahaya/
├── README.md                          ← START HERE! Main documentation
├── QUICKSTART.md                      ← 5-minute setup guide
├── CONTRIBUTING.md                    ← How to contribute
├── TROUBLESHOOTING.md                 ← Common issues & solutions
├── TESTING.md                         ← Testing guide
├── TEST_QUICK_REFERENCE.md            ← Testing commands
├── TESTING_SETUP.md                   ← Testing setup
├── TESTING_SUMMARY.md                 ← Testing implementation details
├── TEST_EXECUTION_REPORT.md           ← Test report template
├── README_TESTING.md                  ← Testing overview
├── LICENSE                            ← MIT License
├── .gitignore                         ← Git ignore rules
└── docs/                              ← Additional documentation
    ├── ARCHITECTURE.md               ← System architecture
    ├── API_REFERENCE.md              ← API endpoints
    └── DATABASE_SCHEMA.md            ← Database design
```

---

## 📁 Project Root Structure

```
Govi-Sahaya/
│
├── govi_sahaya_backend/                          ← Node.js/Express API
│   ├── src/
│   │   ├── controllers/                          ← Request handlers
│   │   │   ├── authController.js
│   │   │   ├── userController.js
│   │   │   ├── weatherController.js
│   │   │   ├── mlController.js
│   │   │   ├── forumController.js
│   │   │   ├── newsController.js
│   │   │   ├── shopController.js
│   │   │   └── ...
│   │   │
│   │   ├── routes/                               ← API endpoints
│   │   │   ├── authRoutes.js
│   │   │   ├── userRoutes.js
│   │   │   ├── weatherRoutes.js
│   │   │   ├── mlRoutes.js
│   │   │   ├── forumRoutes.js
│   │   │   └── index.js
│   │   │
│   │   ├── models/                               ← MongoDB schemas
│   │   │   ├── User.js
│   │   │   ├── Post.js
│   │   │   ├── WeatherData.js
│   │   │   ├── News.js
│   │   │   └── ...
│   │   │
│   │   ├── services/                             ← Business logic
│   │   │   ├── authService.js
│   │   │   ├── emailService.js
│   │   │   ├── mlService.js
│   │   │   ├── weatherService.js
│   │   │   ├── newsService.js
│   │   │   └── ...
│   │   │
│   │   ├── middleware/                           ← Request middleware
│   │   │   ├── auth.js
│   │   │   ├── errorHandler.js
│   │   │   ├── rateLimiter.js
│   │   │   ├── validation.js
│   │   │   └── uploadMiddleware.js
│   │   │
│   │   ├── utils/                                ← Utility functions
│   │   │   ├── logger.js
│   │   │   ├── validation.js
│   │   │   ├── constants.js
│   │   │   ├── cronJobs.js
│   │   │   └── ...
│   │   │
│   │   ├── config/                               ← Configuration
│   │   │   ├── database.js
│   │   │   ├── firebase.js
│   │   │   ├── constants.js
│   │   │   └── ...
│   │   │
│   │   └── app.js                                ← Express app setup
│   │
│   ├── tests/                                   ← Test files
│   │   ├── unit/
│   │   │   ├── authController.test.js
│   │   │   ├── userController.test.js
│   │   │   ├── weatherService.test.js
│   │   │   ├── utilities.test.js
│   │   │   ├── auth.test.js
│   │   │   ├── ml.test.js
│   │   │   └── weather.test.js
│   │   │
│   │   ├── integration/
│   │   │   ├── api.test.js
│   │   │   └── database.test.js
│   │   │
│   │   ├── fixtures/                           ← Test data
│   │   ├── setup.js                            ← Test environment
│   │   └── ...
│   │
│   ├── scripts/                                 ← Utility scripts
│   │   ├── seedDatabase.js
│   │   ├── trainModel.js
│   │   └── migrateData.js
│   │
│   ├── ml/                                      ← ML integration
│   │   ├── inference/
│   │   │   ├── cropRecommendation.js
│   │   │   └── diseaseDetection.js
│   │   ├── models/
│   │   ├── preprocessing/
│   │   └── uploads/
│   │
│   ├── logs/                                    ← Application logs
│   ├── uploads/                                 ← User uploads
│   │   ├── crop_images/
│   │   ├── forum_posts/
│   │   ├── profile_pictures/
│   │   ├── shop_products/
│   │   └── temp/
│   │
│   ├── package.json                             ← Dependencies
│   ├── jest.config.js                           ← Jest configuration
│   ├── .env.example                             ← Environment template
│   ├── .gitignore                               ← Git ignore
│   ├── server.js                                ← Entry point
│   └── README.md                                ← Backend setup
│
│
├── govi_sahaya_mobile/                          ← Flutter app
│   ├── lib/
│   │   ├── main.dart                            ← App entry point
│   │   │
│   │   ├── config/
│   │   │   ├── theme.dart                       ← App theming
│   │   │   ├── routes.dart                      ← Navigation
│   │   │   └── constants.dart
│   │   │
│   │   ├── core/
│   │   │   ├── network/
│   │   │   │   ├── api_client.dart              ← HTTP client
│   │   │   │   └── interceptors.dart
│   │   │   └── exceptions/
│   │   │       └── exceptions.dart
│   │   │
│   │   ├── data/
│   │   │   └── models.dart                      ← Data structures
│   │   │
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── crop_model.dart
│   │   │   ├── weather_model.dart
│   │   │   ├── post_model.dart
│   │   │   └── ...
│   │   │
│   │   ├── providers/                           ← State management (Provider)
│   │   │   ├── auth_provider.dart
│   │   │   ├── weather_provider.dart
│   │   │   ├── news_provider.dart
│   │   │   ├── ml_provider.dart
│   │   │   ├── forum_provider.dart
│   │   │   ├── shop_provider.dart
│   │   │   ├── profile_provider.dart
│   │   │   ├── notification_provider.dart
│   │   │   └── ...
│   │   │
│   │   ├── screens/                             ← UI screens
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── forgot_password_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── weather/
│   │   │   │   ├── weather_screen.dart
│   │   │   │   └── weather_detail_screen.dart
│   │   │   ├── ai_crop_doctor/
│   │   │   │   ├── crop_doctor_screen.dart
│   │   │   │   └── detection_result_screen.dart
│   │   │   ├── community_forum/
│   │   │   │   ├── forum_screen.dart
│   │   │   │   └── create_post_screen.dart
│   │   │   ├── news/
│   │   │   │   └── news_screen.dart
│   │   │   ├── shop/
│   │   │   │   ├── shop_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── cart_screen.dart
│   │   │   ├── profit_planner/
│   │   │   │   └── profit_planner_screen.dart
│   │   │   ├── profile/
│   │   │   │   ├── profile_screen.dart
│   │   │   │   └── edit_profile_screen.dart
│   │   │   ├── notifications/
│   │   │   │   └── notifications_screen.dart
│   │   │   ├── menu/
│   │   │   │   └── menu_screen.dart
│   │   │   ├── knowledge_hub/
│   │   │   │   └── knowledge_hub_screen.dart
│   │   │   └── safety_assist/
│   │   │       └── safety_assist_screen.dart
│   │   │
│   │   ├── services/                            ← API services
│   │   │   ├── auth_service.dart
│   │   │   ├── weather_service.dart
│   │   │   ├── news_service.dart
│   │   │   ├── ml_service.dart
│   │   │   ├── shop_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── backend_XXX_service.dart
│   │   │   └── ...
│   │   │
│   │   ├── widgets/                             ← Reusable components
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_card.dart
│   │   │   ├── loading_widget.dart
│   │   │   ├── error_widget.dart
│   │   │   ├── bottom_nav_bar.dart
│   │   │   └── ...
│   │   │
│   │   └── utils/
│   │       ├── constants.dart
│   │       ├── helper_functions.dart
│   │       ├── validators.dart
│   │       └── date_formatter.dart
│   │
│   ├── assets/                                  ← App assets
│   │   ├── images/
│   │   │   └── app_icon.png
│   │   ├── icons/
│   │   └── lottie/
│   │
│   ├── android/                                 ← Android config
│   │   ├── app/
│   │   │   ├── google-services.json            ← Firebase (add after setup)
│   │   │   └── build.gradle
│   │   ├── gradle.properties
│   │   └── settings.gradle
│   │
│   ├── ios/                                     ← iOS config
│   │   ├── Runner/
│   │   │   ├── GoogleService-Info.plist        ← Firebase (add after setup)
│   │   │   └── Runner.xcodeproj
│   │   └── Podfile
│   │
│   ├── test/                                   ← Tests
│   │   ├── widget_tests.dart
│   │   ├── unit_tests.dart
│   │   └── integration_tests.dart
│   │
│   ├── pubspec.yaml                            ← Dependencies
│   ├── pubspec.lock                            ← Locked versions
│   ├── analysis_options.yaml                   ← Dart linting
│   └── README.md                               ← Frontend setup
│
│
├── ml_model/                                   ← ML models & training
│   ├── models/
│   │   ├── best_model.h5                       ← Deep learning model
│   │   ├── crop_recommendation_model.pkl       ← ML model
│   │   └── ...
│   ├── preprocessing/                          ← Data preprocessing
│   ├── training/                               ← Training scripts
│   ├── ml_api.py                               ← ML server
│   ├── requirements.txt                        ← Python dependencies
│   ├── generate_onion_info.py                  ← Data generation
│   ├── train_model_enhanced.py                 ← Model training
│   └── crop_disease_data.csv                   ← Training data
│
│
├── assets/
│   └── screenshots/                            ← Screenshot folder
│       ├── login.png
│       ├── register.png
│       ├── home.png
│       ├── weather.png
│       ├── crop_doctor.png
│       ├── forum.png
│       ├── shop.png
│       └── ... (other screenshots)
│
│
├── docs/                                       ← Additional documentation
│   ├── ARCHITECTURE.md                        ← System design
│   ├── API_REFERENCE.md                       ← API endpoints
│   ├── DATABASE_SCHEMA.md                      ← DB design
│   ├── DEPLOYMENT.md                          ← Deployment guide
│   └── CHANGELOG.md                           ← Version history
│
│
├── .github/
│   ├── workflows/                             ← GitHub Actions
│   │   ├── test.yml                          ← Test automation
│   │   └── deploy.yml                        ← Deployment pipeline
│   └── ISSUE_TEMPLATE/                       ← GitHub templates
│       ├── bug_report.md
│       └── feature_request.md
│
│
├── docker-compose.yml                        ← Docker setup
├── Dockerfile                                ← Docker image
├── .gitignore                                ← Git ignore
├── LICENSE                                   ← MIT License
└── README.md                                 ← Main documentation

```

---

## 📖 Documentation Navigation

### For New Developers
1. Start: [README.md](./README.md)
2. Quick setup: [QUICKSTART.md](./QUICKSTART.md)
3. Issues: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
4. Contributing: [CONTRIBUTING.md](./CONTRIBUTING.md)

### For Testing
1. Overview: [TESTING.md](./TESTING.md)
2. Quick ref: [TEST_QUICK_REFERENCE.md](./TEST_QUICK_REFERENCE.md)
3. Setup: [TESTING_SETUP.md](./TESTING_SETUP.md)

### For Architecture
1. System design: [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)
2. API reference: [docs/API_REFERENCE.md](./docs/API_REFERENCE.md)
3. Database schema: [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md)

### For Deployment
1. Deployment guide: [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)
2. Docker setup: [docker-compose.yml](./docker-compose.yml)

---

## 🖼️ Where to Add Screenshots

Create `assets/screenshots/` directory and add:

```
assets/screenshots/
├── login.png                      ← Login screen
├── register.png                   ← Registration screen
├── verification.png               ← Email verification
├── home.png                       ← Home dashboard
├── weather.png                    ← Weather details
├── alerts.png                     ← Weather alerts
├── crop_doctor.png                ← Disease detection interface
├── detection_results.png          ← Detection results
├── treatment.png                  ← Treatment plan
├── forum.png                      ← Forum threads
├── create_thread.png              ← Create post screen
├── discussion.png                 ← Discussion view
├── news.png                       ← News feed
├── shop.png                       ← Product shop
├── cart.png                       ← Shopping cart
├── profit_planner.png             ← Profit calculator
├── profile.png                    ← User profile
├── notifications.png              ← Notifications
└── knowledge_hub.png              ← Knowledge base
```

---

## 🔄 File Relationships

### Backend Data Flow
```
Client Request
    ↓
Express Route (routes/*.js)
    ↓
Middleware (middleware/*.js)
    ↓
Controller (controllers/*.js)
    ↓
Service (services/*.js)
    ↓
Model (models/*.js) → MongoDB
    ↓
Response to Client
```

### Frontend Data Flow
```
Widget (screens/*.dart)
    ↓
Provider (providers/*.dart) [State Management]
    ↓
Service (services/*.dart) [API Calls]
    ↓
API Client → Backend
    ↓
Response → Provider → Widget
```

---

## 🚀 How to Navigate This Repository

### I want to...

**Set up the project**
→ [QUICKSTART.md](./QUICKSTART.md)

**Understand the architecture**
→ [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)

**Work on backend**
→ [govi_sahaya_backend/README.md](./govi_sahaya_backend/README.md)

**Work on frontend**
→ [govi_sahaya_mobile/README.md](./govi_sahaya_mobile/README.md)

**Write tests**
→ [TESTING.md](./TESTING.md)

**Contribute code**
→ [CONTRIBUTING.md](./CONTRIBUTING.md)

**Fix issues**
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

**Deploy the app**
→ [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)

**Understand API**
→ [docs/API_REFERENCE.md](./docs/API_REFERENCE.md)

---

## 📊 Key Files Summary

| File | Purpose | Why Important |
|------|---------|---------------|
| `README.md` | Main documentation | Entry point for all users |
| `QUICKSTART.md` | 5-min setup | Get started quickly |
| `CONTRIBUTING.md` | Contribution guide | How to contribute |
| `TESTING.md` | Testing guide | Ensure code quality |
| `TROUBLESHOOTING.md` | Common issues | Solve problems fast |
| `server.js` | Backend entry point | Start the API server |
| `lib/main.dart` | Frontend entry point | Start the app |
| `package.json` | Dependencies | Run scripts & manage packages |
| `pubspec.yaml` | Flutter deps | Manage Flutter packages |
| `.env.example` | Configuration template | Set up environment |
| `jest.config.js` | Jest config | Run tests |
| `docker-compose.yml` | Docker setup | Run with Docker |

---

<div align="center">

**Need help navigating?** Start with [README.md](./README.md)

</div>
