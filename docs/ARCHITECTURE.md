# 🏗️ System Architecture - Govi Sahaya

## Overview

Govi Sahaya is a comprehensive agricultural technology platform that leverages AI/ML for crop disease detection, real-time weather monitoring, community engagement, and market insights. The system follows a **client-server architecture** with cloud integration.

---

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   GOVI SAHAYA PLATFORM                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  Mobile App      │         │  Web Dashboard   │    │
│  │  (Flutter)       │         │  (Future)        │    │
│  │                  │         │                  │    │
│  │ • Authentication │         │ • Analytics      │    │
│  │ • Weather Data   │         │ • Admin Panel    │    │
│  │ • Crop Doctor    │         │ • Reports        │    │
│  │ • Community      │         │                  │    │
│  │ • Shop           │         │                  │    │
│  └────────┬─────────┘         └────────┬─────────┘    │
│           │                            │                │
│           └────────────┬───────────────┘                │
│                        │                                 │
│                        ▼                                 │
│            ┌──────────────────────┐                    │
│            │  API Gateway / Load  │                    │
│            │    Balancer (nginx)  │                    │
│            └────────────┬─────────┘                    │
│                         │                               │
│                         ▼                               │
│         ┌───────────────────────────────┐              │
│         │   Node.js/Express Backend     │              │
│         │         (API Server)          │              │
│         │                               │              │
│         │  ┌─────────────────────────┐  │              │
│         │  │ Routes & Controllers    │  │              │
│         │  │ • Auth                  │  │              │
│         │  │ • Users                 │  │              │
│         │  │ • Weather               │  │              │
│         │  │ • ML Services           │  │              │
│         │  │ • Forum/Community       │  │              │
│         │  │ • Shop/Products         │  │              │
│         │  │ • News                  │  │              │
│         │  └─────────────────────────┘  │              │
│         │                               │              │
│         │  ┌─────────────────────────┐  │              │
│         │  │ Services Layer          │  │              │
│         │  │ • Business Logic        │  │              │
│         │  │ • Data Processing       │  │              │
│         │  │ • Email Service         │  │              │
│         │  │ • Auth Service          │  │              │
│         │  │ • External API Calls    │  │              │
│         │  └─────────────────────────┘  │              │
│         │                               │              │
│         │  ┌─────────────────────────┐  │              │
│         │  │ Middleware              │  │              │
│         │  │ • Authentication        │  │              │
│         │  │ • Rate Limiting         │  │              │
│         │  │ • Error Handling        │  │              │
│         │  │ • File Upload           │  │              │
│         │  │ • Request Validation    │  │              │
│         │  └─────────────────────────┘  │              │
│         │                               │              │
│         └───────────┬───────────────────┘              │
│                     │                                   │
│     ┌───────────────┼───────────────┬──────────────┐   │
│     │               │               │              │   │
│     ▼               ▼               ▼              ▼   │
│  ┌──────┐      ┌─────────┐    ┌──────────┐   ┌────┐  │
│  │  DB  │      │ ML API  │    │ Firebase │   │ S3 │  │
│  │MongoDB      │ (Python)│    │Services  │   │    │  │
│  │      │      │         │    │          │   │    │  │
│  │ Data │      │Inference│    │Auth/Msgs │   │File│  │
│  │Store │      │         │    │          │   │    │  │
│  └──────┘      └─────────┘    └──────────┘   └────┘  │
│     │              │              │           │      │
└─────┼──────────────┼──────────────┼───────────┼──────┘
      │              │              │           │
      ▼              ▼              ▼           ▼
  ┌─────────────────────────────────────────────────┐
  │      External Services & Data Sources           │
  │                                                  │
  │ • Weather APIs (OpenWeather, Weather.gov)       │
  │ • News APIs (NewsAPI, AgriNews)                 │
  │ • Maps APIs (Google Maps, Mapbox)               │
  │ • Payment Gateway (Razorpay, Stripe)            │
  │ • Email Service (SendGrid, Nodemailer)          │
  │ • SMS Service (Twilio)                          │
  │ • Analytics (Google Analytics, Mixpanel)        │
  │ • Storage (AWS S3, Google Cloud Storage)        │
  └─────────────────────────────────────────────────┘
```

---

## 🔄 Request/Response Flow

### 1. **Authentication Flow**

```
User Input (Login/Register)
    ↓
Mobile App (Flutter)
    ↓
HTTP Request → Backend API
    ↓
Auth Routes → Auth Controller
    ↓
User Middleware (Validation)
    ↓
Auth Service
    ├─ Hash password (bcrypt)
    ├─ Check MongoDB
    ├─ Generate JWT Token
    └─ Send Email Verification
    ↓
Response + JWT Token
    ↓
Mobile App (Store Token)
    ↓
Use Token in Future Requests
```

### 2. **Crop Disease Detection Flow**

```
User Uploads Image
    ↓
Mobile App (Flutter)
    ├─ Compress image
    ├─ Validate format
    └─ Send to Backend
    ↓
ML Routes → ML Controller
    ↓
File Upload Middleware
    ├─ Save image
    └─ Create temp directory
    ↓
ML Service
    ├─ Send to Python ML API
    └─ Inference (diseaseDetection.js)
    ↓
Python Model (TensorFlow/Keras)
    ├─ Preprocess image
    ├─ Load best_model.h5
    └─ Predict disease & confidence
    ↓
Treatment Recommendations
    ├─ Disease identified
    ├─ Fetch from DB
    └─ Fertilizer suggestions
    ↓
Response with Results
    ↓
Display in Mobile App
    ├─ Disease name
    ├─ Confidence score
    ├─ Treatment plan
    └─ Prevention tips
```

### 3. **Weather Data Flow**

```
Scheduled Cron Job (Every 30 mins)
    ↓
Weather Service
    ├─ Call OpenWeather API
    ├─ Get user locations
    └─ Fetch forecast data
    ↓
Data Processing
    ├─ Transform data
    ├─ Calculate alerts
    └─ Store in MongoDB
    ↓
User Requests Weather
    ↓
Mobile App → Weather Routes
    ↓
Weather Controller
    ├─ Get cached data
    ├─ Check location
    └─ Return formatted response
    ↓
Display Weather Dashboard
    ├─ Current conditions
    ├─ 5-day forecast
    ├─ Alerts
    └─ Planting recommendations
```

### 4. **Forum/Community Flow**

```
User Creates Post
    ↓
Mobile App
    ├─ Validate content
    ├─ Add media (optional)
    └─ Send Request
    ↓
Forum Routes → Forum Controller
    ↓
Create Post Service
    ├─ Save to MongoDB
    ├─ Create timestamps
    └─ Update indexes
    ↓
Notify Subscribers
    ├─ Find interested users
    ├─ Create notifications
    └─ Send push notification (Firebase)
    ↓
User Replies
    ├─ Add comment
    ├─ Tag users @mention
    └─ Create notifications
    ↓
Display in Community Feed
    ├─ Thread view
    ├─ Comments
    ├─ Ratings
    └─ User profiles
```

### 5. **Shop/E-commerce Flow**

```
User Browses Products
    ↓
Mobile App → Shop Routes
    ↓
Shop Controller
    ├─ Get all products
    ├─ Filter/Search
    └─ Return with images
    ↓
Add to Cart
    ├─ Store locally or in DB
    └─ Calculate total
    ↓
Checkout
    ├─ Validate inventory
    ├─ Calculate shipping
    └─ Apply coupons
    ↓
Payment Gateway (Razorpay)
    ├─ Initiate payment
    ├─ User confirms
    └─ Webhook callback
    ↓
Order Service
    ├─ Create order
    ├─ Update inventory
    ├─ Send confirmation email
    └─ Notify admin
    ↓
Shipping Tracking
    ├─ Integrate with logistics
    ├─ Track delivery
    └─ Push notifications
```

---

## 🗂️ Component Architecture

### Backend (Node.js/Express)

```
┌────────────────────────────────────────┐
│         Express Application            │
├────────────────────────────────────────┤
│                                        │
│  Presentation Layer (Routes)           │
│  ├─ /api/auth/*                        │
│  ├─ /api/users/*                       │
│  ├─ /api/weather/*                     │
│  ├─ /api/ml/*                          │
│  ├─ /api/forum/*                       │
│  ├─ /api/news/*                        │
│  └─ /api/shop/*                        │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │  Middleware Pipeline             │  │
│  ├─ Request Logging                 │  │
│  ├─ CORS Handler                    │  │
│  ├─ Body Parser                     │  │
│  ├─ Authentication Checker          │  │
│  ├─ Authorization Checker           │  │
│  ├─ Rate Limiter                    │  │
│  ├─ File Upload Handler             │  │
│  └─ Error Handler                   │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Business Logic Layer (Services)       │
│  ├─ userService.js                     │
│  ├─ authService.js                     │
│  ├─ weatherService.js                  │
│  ├─ mlService.js                       │
│  ├─ forumService.js                    │
│  ├─ newsService.js                     │
│  ├─ shopService.js                     │
│  ├─ notificationService.js             │
│  └─ emailService.js                    │
│                                        │
│  Data Access Layer (Models & DB)       │
│  ├─ User Model                         │
│  ├─ Post Model                         │
│  ├─ WeatherData Model                  │
│  ├─ Product Model                      │
│  ├─ Order Model                        │
│  └─ News Model                         │
│                                        │
│  External Service Integration          │
│  ├─ Firebase Admin SDK                 │
│  ├─ MongoDB Driver                     │
│  ├─ Multer (File Upload)               │
│  ├─ Nodemailer (Email)                 │
│  ├─ JWT (Authentication)               │
│  ├─ Axios (HTTP Requests)              │
│  └─ Cron Jobs (Scheduled Tasks)        │
│                                        │
└────────────────────────────────────────┘
```

### Frontend (Flutter)

```
┌──────────────────────────────────────┐
│      Flutter Application             │
├──────────────────────────────────────┤
│                                      │
│  Screens (UI Layer)                  │
│  ├─ Authentication Screens           │
│  │  ├─ Login Screen                  │
│  │  └─ Register Screen               │
│  ├─ Main Navigation                  │
│  │  ├─ Home Screen                   │
│  │  ├─ Weather Screen                │
│  │  ├─ Crop Doctor Screen            │
│  │  ├─ Forum Screen                  │
│  │  ├─ News Screen                   │
│  │  ├─ Shop Screen                   │
│  │  └─ Profile Screen                │
│  └─ Feature Screens                  │
│     ├─ Profit Planner                │
│     ├─ Notifications                 │
│     └─ Safety Assist                 │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  State Management (Provider) │    │
│  ├─ authProvider.dart           │    │
│  ├─ weatherProvider.dart        │    │
│  ├─ mlProvider.dart             │    │
│  ├─ forumProvider.dart          │    │
│  ├─ shopProvider.dart           │    │
│  ├─ newsProvider.dart           │    │
│  └─ profileProvider.dart        │    │
│  └──────────────────────────────┘    │
│                                      │
│  Service Layer (API Calls)           │
│  ├─ authService.dart                 │
│  ├─ weatherService.dart              │
│  ├─ mlService.dart                   │
│  ├─ forumService.dart                │
│  ├─ shopService.dart                 │
│  ├─ newsService.dart                 │
│  └─ notificationService.dart         │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Network Layer               │    │
│  ├─ API Client (Dio)            │    │
│  ├─ Interceptors               │    │
│  ├─ Error Handling             │    │
│  └─ Request/Response Models    │    │
│  └──────────────────────────────┘    │
│                                      │
│  Reusable Widgets                    │
│  ├─ Custom Components               │
│  ├─ Theme & Styling                 │
│  ├─ Common Dialogs                  │
│  └─ Loading Spinners                │
│                                      │
│  Local Storage & Cache               │
│  ├─ SharedPreferences (Settings)     │
│  ├─ Sqflite (Local DB)               │
│  ├─ Hive (Fast Cache)                │
│  └─ Firebase Local Cache             │
│                                      │
│  External Integrations               │
│  ├─ Firebase Auth                    │
│  ├─ Firebase Messaging               │
│  ├─ Google Maps                      │
│  ├─ Image Picker                     │
│  ├─ Geolocator                       │
│  └─ Connectivity Plus                │
│                                      │
└──────────────────────────────────────┘
```

---

## 📦 Data Models & Relationships

### User-Related Models

```
User
├─ _id (ObjectId)
├─ email (String) - Unique
├─ phone (String)
├─ password (String) - Hashed
├─ firstName (String)
├─ lastName (String)
├─ profilePic (String) - URL
├─ location
│  ├─ state (String)
│  ├─ district (String)
│  ├─ latitude (Number)
│  └─ longitude (Number)
├─ cropInfo
│  ├─ mainCrops (Array)
│  ├─ farmSize (Number)
│  └─ farmType (String)
├─ isEmailVerified (Boolean)
├─ firebaseUID (String)
├─ createdAt (Date)
├─ updatedAt (Date)
└─ role (String) - admin/user/moderator
```

### Content Models

```
Post (Forum)
├─ _id (ObjectId)
├─ authorId (ObjectId) → User
├─ title (String)
├─ content (String)
├─ category (String) - diseases/techniques/market/general
├─ tags (Array)
├─ solutions (Array)
│  └─ (Object)
│     ├─ userId → User
│     ├─ text (String)
│     └─ rating (Number)
├─ upvotes (Number)
├─ views (Number)
├─ createdAt (Date)
└─ updatedAt (Date)

News
├─ _id (ObjectId)
├─ title (String)
├─ content (String)
├─ source (String)
├─ category (String) - agriculture/weather/market/policy
├─ image (String) - URL
├─ url (String) - Original source
├─ pubDate (Date)
└─ addedAt (Date)
```

### Transaction Models

```
Order
├─ _id (ObjectId)
├─ userId (ObjectId) → User
├─ items (Array)
│  └─ (Object)
│     ├─ productId (ObjectId) → Product
│     ├─ quantity (Number)
│     ├─ price (Number)
│     └─ discount (Number)
├─ totalAmount (Number)
├─ shippingAddress (Object)
├─ shippingCost (Number)
├─ paymentStatus (String) - pending/success/failed
├─ orderStatus (String) - pending/processing/shipped/delivered
├─ paymentId (String)
├─ trackingId (String)
├─ createdAt (Date)
└─ deliveredAt (Date)

Product
├─ _id (ObjectId)
├─ name (String)
├─ description (String)
├─ category (String) - seeds/fertilizers/tools/etc
├─ price (Number)
├─ stock (Number)
├─ image (String) - URL
├─ rating (Number) - 0-5
├─ reviews (Array)
├─ seller (String)
└─ createdAt (Date)
```

### Weather Models

```
WeatherData
├─ _id (ObjectId)
├─ location (Object)
│  ├─ state (String)
│  ├─ district (String)
│  ├─ latitude (Number)
│  └─ longitude (Number)
├─ current (Object)
│  ├─ temp (Number)
│  ├─ humidity (Number)
│  ├─ windSpeed (Number)
│  ├─ rainfall (Number)
│  ├─ condition (String)
│  └─ timestamp (Date)
├─ forecast (Array) - 5 days
├─ alerts (Array)
│  └─ (Object)
│     ├─ type (String) - flood/drought/cyclone
│     ├─ severity (String) - low/high
│     ├─ message (String)
│     └─ timestamp (Date)
├─ plantingRecommendations (Array)
└─ lastUpdated (Date)
```

---

## 🔐 Security Architecture

### Authentication & Authorization

```
┌────────────────────────────────────────┐
│       Client (Mobile App)              │
└────────────────┬───────────────────────┘
                 │
                 │ 1. Login Request
                 ▼
         ┌──────────────────┐
         │  Auth Routes     │
         │  /api/auth/*     │
         └────────┬─────────┘
                  │
                  │ 2. Validate Input
                  ▼
         ┌──────────────────┐
         │  Auth Service    │
         │  • Check user    │
         │  • Compare pass  │
         │  • Generate JWT  │
         └────────┬─────────┘
                  │
                  │ 3. Return JWT + Refresh Token
                  ▼
         ┌──────────────────┐
         │  Client Storage  │
         │  • localStorage  │
         │  • AsyncStorage  │
         └────────┬─────────┘
                  │
                  │ 4. Use in Headers
                  │    Authorization: Bearer <JWT>
                  ▼
         ┌──────────────────┐
         │  Protected Route │
         │  /api/users/*    │
         └────────┬─────────┘
                  │
                  │ 5. Verify JWT
                  ▼
    ┌─────────────────────────────┐
    │  JWT Verification Middleware │
    │  • Check signature          │
    │  • Verify expiration       │
    │  • Extract userId          │
    └────────┬────────────────────┘
             │
             ├─ Valid? ─→ Proceed
             │
             └─ Invalid? ─→ 401 Unauthorized
                           Return new token pair
                           (Refresh token flow)
```

### Password Security

```
User Registration
    ↓
Password Validation
├─ Min 8 characters
├─ Contains uppercase
├─ Contains number
└─ Contains special char
    ↓
Hash Password (bcrypt)
├─ Salt rounds: 10
└─ Hash stored in DB
    ↓
During Login
├─ Fetch hashed pass
├─ Compare with input (bcrypt)
└─ Generate JWT if match
```

### File Upload Security

```
User Uploads File
    ↓
Multer Middleware
├─ Check MIME type
├─ Limit file size
├─ Check extension
└─ Validate content
    ↓
Store in Safe Location
├─ Generate unique name
├─ Store metadata
└─ Create in uploads/
    ↓
Serve with Security Headers
├─ Content-Disposition
├─ X-Content-Type-Options
└─ Cache-Control
```

---

## 🚀 Scalability & Performance

### Caching Strategy

```
┌─────────────────────────────────────┐
│        Request comes in             │
└──────────────┬──────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Check Redis Cache   │
    └──────┬───────────────┘
           │
    ┌──────┴──────┐
    │             │
   YES           NO
    │             │
    │             ▼
    │    ┌────────────────────┐
    │    │  Query Database    │
    │    │  (MongoDB)         │
    │    └──────┬─────────────┘
    │           │
    │           ▼
    │    ┌────────────────────┐
    │    │  Store in Redis    │
    │    │  (TTL: varies)     │
    │    └──────┬─────────────┘
    │           │
    └───┬───────┘
        │
        ▼
    Return to Client

Redis Keys Pattern:
├─ user:{userId} → 1 hour TTL
├─ weather:{location} → 30 min TTL
├─ products:list → 6 hours TTL
├─ news:latest → 2 hours TTL
└─ forum:posts:{id} → 1 hour TTL
```

### Database Optimization

```
MongoDB Indexes
├─ Users
│  ├─ email (unique)
│  ├─ firebaseUID
│  └─ location.state
├─ Posts
│  ├─ authorId
│  ├─ category
│  └─ createdAt (descending)
├─ Products
│  ├─ category
│  ├─ price range
│  └─ rating
└─ Orders
   ├─ userId
   ├─ paymentStatus
   └─ createdAt (TTL: 30 days)

Query Optimization
├─ Use projections
├─ Pagination (limit, offset)
├─ Aggregation pipeline
└─ Connection pooling
```

---

## 🌐 External Integrations

### APIs & Services Used

```
Weather Data
└─ OpenWeather API
   ├─ Current weather
   ├─ 5-day forecast
   └─ Alerts

News & Content
└─ NewsAPI
   ├─ Agricultural news
   └─ Market trends

Maps & Location
└─ Google Maps API
   ├─ Geocoding
   ├─ Distance matrix
   └─ Place autocomplete

Authentication
└─ Firebase
   ├─ Email/password auth
   ├─ Social login
   └─ User management

Messaging
└─ Firebase Cloud Messaging
   ├─ Push notifications
   ├─ Topics
   └─ Message scheduling

Payment
└─ Razorpay / Stripe
   ├─ Payment processing
   ├─ Refunds
   └─ Subscriptions

Email Service
└─ NodeMailer / SendGrid
   ├─ Transactional emails
   ├─ Newsletters
   └─ Verification

File Storage
└─ AWS S3 / Azure Blob
   ├─ Image CDN
   ├─ Video storage
   └─ Backup
```

---

## 📊 Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter | Cross-platform mobile app |
| **Backend** | Node.js/Express | REST API server |
| **Database** | MongoDB | NoSQL document store |
| **Cache** | Redis | Session & data cache |
| **Auth** | JWT + Firebase | Authentication |
| **ML** | Python/TensorFlow | Disease detection |
| **Deployment** | Docker | Containerization |
| **Hosting** | AWS/Azure/GCP | Cloud infrastructure |
| **Testing** | Jest/Flutter Test | Quality assurance |
| **Monitoring** | Sentry/DataDog | Error tracking |

---

## 🔄 Deployment Architecture

```
┌──────────────────────────────────┐
│      GitHub Repository           │
│  (Source Code Management)        │
└────────────┬─────────────────────┘
             │
             │ Push Code
             ▼
     ┌──────────────────┐
     │  GitHub Actions  │
     │  (CI/CD Pipeline)│
     ├────────────────┤
     │ • Run Tests    │
     │ • Build App    │
     │ • Push Image   │
     └────────┬───────┘
              │
              ▼
     ┌──────────────────┐
     │  Docker Registry │
     │  (DockerHub)     │
     └────────┬───────┘
              │
              ▼
    ┌────────────────────┐
    │  Cloud Deployment  │
    │  Options:          │
    ├─ AWS ECS/Lambda    │
    ├─ Google Cloud Run  │
    ├─ Azure Container   │
    └─ Kubernetes        │
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
┌─────────┐    ┌──────────┐
│Frontend │    │ Backend  │
│(Flutter)│    │ (Node.js)│
└─────────┘    └──────────┘
    │                │
    └────────┬───────┘
             │
         Users Access
```

---

## 📈 Monitoring & Logging

```
┌─────────────────────────────────┐
│   Application Monitoring        │
├─────────────────────────────────┤
│                                 │
│  Error Tracking (Sentry)        │
│  ├─ Real-time alerts            │
│  ├─ Error grouping              │
│  └─ Stack traces                │
│                                 │
│  Performance Monitoring         │
│  ├─ Response times              │
│  ├─ CPU/Memory usage            │
│  ├─ Database queries            │
│  └─ API latency                 │
│                                 │
│  Logging (Winston/Morgan)       │
│  ├─ Request logs                │
│  ├─ Application logs            │
│  ├─ Database logs               │
│  └─ Security logs               │
│                                 │
│  Analytics (Google Analytics)   │
│  ├─ User engagement             │
│  ├─ Feature usage               │
│  ├─ Conversion rates            │
│  └─ User journeys               │
│                                 │
│  Uptime Monitoring              │
│  ├─ Ping checks                 │
│  ├─ API health                  │
│  ├─ Database health             │
│  └─ Alerts                      │
│                                 │
└─────────────────────────────────┘
```

---

## 🎯 Key Architectural Decisions

### 1. **Microservices vs Monolith**
- **Decision**: Monolithic backend with service-oriented architecture
- **Reason**: Easier to manage for team size, simpler deployment, shared database
- **Future**: Can refactor to microservices if scalability demands increase

### 2. **Real-time Communication**
- **Decision**: REST API with polling for updates
- **Future**: WebSocket implementation for real-time features (forum notifications, live weather alerts)

### 3. **File Storage**
- **Decision**: Cloud storage (S3/Azure) with reference in database
- **Reason**: Scalability, backup, CDN benefits, easy sharing

### 4. **Authentication**
- **Decision**: JWT + Firebase for identity management
- **Reason**: Stateless auth, mobile-friendly, social login integration

### 5. **Database Choice**
- **Decision**: MongoDB (NoSQL) instead of SQL
- **Reason**: Flexible schema, excellent for document storage, natural fit for JSON data

---

## 🔗 Related Documentation

- [API Reference](./API_REFERENCE.md) - Detailed API endpoints
- [Database Schema](./DATABASE_SCHEMA.md) - Data model details
- [Deployment Guide](./DEPLOYMENT.md) - How to deploy
- [Testing Strategy](../TESTING.md) - Testing approach

---

<div align="center">

**Last Updated**: 2024
**Status**: Active Development
**Contributors**: [Add your name here]

</div>
