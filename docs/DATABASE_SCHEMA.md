# 📊 Database Schema - Govi Sahaya

Complete documentation of MongoDB collections, fields, indexes, and relationships.

---

## 📑 Overview

**Database Name**: `govi_sahaya`

**Total Collections**: 12 Core + 4 Support

**Data Model**: Document-based (MongoDB), normalized with references

---

## 👥 Users Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j1"),
  
  // Authentication
  email: "farmer@example.com",
  password: "$2b$10$hashed_password", // bcrypt hashed
  firebaseUID: "firebase_uid_string",
  isEmailVerified: true,
  emailVerificationToken: null,
  emailVerificationExpires: null,
  
  // Personal Information
  firstName: "Rajesh",
  lastName: "Kumar",
  phone: "+91-9876543210",
  profilePic: "https://s3.amazonaws.com/profile.jpg",
  
  // Location Details
  location: {
    state: "Maharashtra",
    district: "Pune",
    village: "Pirangut",
    latitude: 18.5204,
    longitude: 73.8567,
    timezone: "IST"
  },
  
  // Farm Information
  cropInfo: {
    mainCrops: ["wheat", "cotton", "sugarcane"],
    farmSize: 50, // in acres
    farmType: "mixed", // organic, conventional, mixed
    irrigationType: "drip", // flood, drip, sprinkler
    soilType: "black_soil"
  },
  
  // Account Information
  role: "farmer", // farmer, admin, moderator, expert
  status: "active", // active, inactive, suspended
  accountType: "free", // free, premium, enterprise
  subscriptionExpires: ISODate("2024-12-31"),
  
  // Preferences
  preferences: {
    languagePreference: "en",
    notificationsEnabled: true,
    pushNotificationsEnabled: true,
    emailNewsletterSubscribed: true,
    dataPrivacy: "public" // public, private
  },
  
  // Metadata
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-01-20T14:30:00Z"),
  lastLoginAt: ISODate("2024-01-20T14:30:00Z"),
  lastIPAddress: "192.168.1.1",
  loginAttempts: 0
}
```

### Indexes

```javascript
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ firebaseUID: 1 })
db.users.createIndex({ phone: 1 })
db.users.createIndex({ "location.district": 1 })
db.users.createIndex({ "location.state": 1 })
db.users.createIndex({ createdAt: -1 })
db.users.createIndex({ status: 1 })
db.users.createIndex({ accountType: 1 })
```

### Queries

```javascript
// Find farmer by email
db.users.findOne({ email: "farmer@example.com" })

// Find all farmers in district
db.users.find({ "location.district": "Pune" })

// Get premium users count
db.users.countDocuments({ accountType: "premium" })

// Find verified farmers
db.users.find({ isEmailVerified: true, status: "active" })
```

---

## 📝 Posts Collection (Forum)

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j2"),
  
  // Content
  title: "How to treat wheat powdery mildew?",
  content: "My wheat crop has developed white powder on leaves...",
  images: [
    "https://s3.amazonaws.com/posts/image1.jpg",
    "https://s3.amazonaws.com/posts/image2.jpg"
  ],
  
  // Author & Metadata
  authorId: ObjectId("64e1a2b3c4d5e6f7g8h9i0j1"),
  category: "diseases", // diseases, techniques, market, general
  subcategory: "powdery_mildew",
  tags: ["wheat", "fungal_disease", "organic"],
  
  // Engagement Metrics
  upvotes: 24,
  downvotes: 2,
  upvoters: [ObjectId("..."), ObjectId("...")],
  views: 156,
  viewedBy: [ObjectId("..."), ...],
  
  // Solutions/Answers
  solutions: [
    {
      _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j3"),
      userId: ObjectId("64e1a2b3c4d5e6f7g8h9i0j4"),
      userName: "Sita Singh",
      userProfilePic: "https://s3.amazonaws.com/profile.jpg",
      text: "Apply sulphur spray at 2.5 g/L water every 7 days...",
      images: ["https://s3.amazonaws.com/posts/solution1.jpg"],
      rating: 4.5,
      ratingCount: 18,
      helpfulCount: 22,
      commentCount: 5,
      timestamp: ISODate("2024-01-18T10:30:00Z"),
      isMarkedAsAccepted: true,
      replies: [
        {
          _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j5"),
          userId: ObjectId("64e1a2b3c4d5e6f7g8h9i0j1"),
          userName: "Rajesh Kumar",
          text: "Thanks for the solution! It worked for me...",
          timestamp: ISODate("2024-01-19T10:30:00Z")
        }
      ]
    }
  ],
  
  // Engagement Data
  commentCount: 5,
  lastActivityAt: ISODate("2024-01-20T14:30:00Z"),
  
  // Moderation
  isApproved: true,
  isSpam: false,
  isArchived: false,
  reportCount: 0,
  
  // Metadata
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-01-20T14:30:00Z"),
  expiresAt: null
}
```

### Indexes

```javascript
db.posts.createIndex({ authorId: 1 })
db.posts.createIndex({ category: 1 })
db.posts.createIndex({ tags: 1 })
db.posts.createIndex({ createdAt: -1 })
db.posts.createIndex({ upvotes: -1 })
db.posts.createIndex({ lastActivityAt: -1 })
db.posts.createIndex({ isApproved: 1 })
db.posts.createIndex({ "location.district": 1 })
```

---

## 🌤️ Weather Data Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j6"),
  
  // Location
  location: {
    state: "Maharashtra",
    district: "Pune",
    latitude: 18.5204,
    longitude: 73.8567,
    elevation: 560,
    timezone: "IST"
  },
  
  // Current Weather
  current: {
    timestamp: ISODate("2024-01-20T15:30:00Z"),
    temperature: 28.5,
    feelsLike: 32.1,
    tempMin: 18.3,
    tempMax: 32.5,
    humidity: 65,
    pressure: 1013,
    windSpeed: 12.3,
    windDirection: "NE",
    windGust: 20.5,
    visibility: 10000,
    uvIndex: 6,
    rainfall: 0,
    cloudCover: 25,
    condition: "Partly Cloudy",
    description: "Partly cloudy with 30% chance of rain",
    icon: "02d",
    source: "openweather"
  },
  
  // Forecast (5 days)
  forecast: [
    {
      date: ISODate("2024-01-21T00:00:00Z"),
      daily: {
        tempMax: 32.5,
        tempMin: 18.3,
        feelsLikeMax: 35.1,
        feelsLikeMin: 17.5,
        humidity: 60,
        rainfall: 0,
        snowfall: 0,
        windSpeed: 10,
        uvIndex: 5,
        condition: "Sunny",
        icon: "01d",
        sunrise: ISODate("2024-01-21T06:45:00Z"),
        sunset: ISODate("2024-01-21T18:15:00Z"),
        precipitationProbability: 10
      },
      hourly: [/* hourly data */]
    }
  ],
  
  // Alerts
  alerts: [
    {
      _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j7"),
      type: "high_rainfall", // heat_wave, frost, flood, etc.
      severity: "high", // low, moderate, high, critical
      title: "Heavy Rainfall Alert",
      description: "Heavy rainfall expected: 80-100mm in next 24 hours",
      message: "Heavy rainfall alert: 80-100mm expected in next 24 hours",
      recommendations: [
        "Delay pesticide application",
        "Check irrigation systems",
        "Secure loose crop covers"
      ],
      validFrom: ISODate("2024-01-20T20:00:00Z"),
      validUntil: ISODate("2024-01-21T20:00:00Z"),
      source: "meteorological_dept"
    }
  ],
  
  // Crop Recommendations
  plantingRecommendations: [
    {
      crop: "wheat",
      recommendation: "Ideal conditions for watering. Plan irrigation for next 3 days.",
      confidence: 0.85,
      reasoning: "Current humidity and temperature optimal for wheat growth"
    }
  ],
  
  // Metadata
  lastUpdated: ISODate("2024-01-20T15:30:00Z"),
  nextUpdateAt: ISODate("2024-01-20T16:30:00Z"),
  dataSource: "openweather",
  dataVersion: 2
}
```

### Indexes

```javascript
db.weather.createIndex({ "location.state": 1, "location.district": 1 })
db.weather.createIndex({ "location.latitude": "2dsphere", "location.longitude": "2dsphere" })
db.weather.createIndex({ lastUpdated: -1 })
db.weather.createIndex({ "alerts.severity": 1 })
```

---

## 🤖 ML Detections Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j8"),
  
  // User & Image Info
  userId: ObjectId("64e1a2b3c4d5e6f7g8h9i0j1"),
  imageUrl: "https://s3.amazonaws.com/detections/image123.jpg",
  imageName: "leaf_image_20240120.jpg",
  imageSize: 2048576, // bytes
  imageMimeType: "image/jpeg",
  imageDimensions: { width: 1920, height: 1080 },
  
  // Crop Information
  cropType: "tomato", // optional, user-provided
  cropsDetected: [],
  
  // Disease Detection Results
  disease: {
    name: "Early Blight",
    scientificName: "Alternaria solani",
    aliases: ["Early leaf spot", "Target spot"],
    confidence: 0.92,
    description: "Fungal disease causing brown spots on leaves and stems",
    family: "Ascomycota",
    cause: "fungal"
  },
  
  // Severity Assessment
  severity: "moderate",
  severityScore: 0.65, // 0-1 scale
  affectedAreas: "15-20%", // leaf coverage
  progressionRate: "rapid", // slow, moderate, rapid
  urgencyLevel: "high",
  
  // Treatment Plan
  treatment: {
    immediate: [
      "Remove infected leaves immediately",
      "Improve air circulation",
      "Water at base of plant only"
    ],
    fungicides: [
      {
        _id: ObjectId("..."),
        name: "Chlorothalonil",
        dosage: "2.5 g/L water",
        interval: "7-10 days",
        applicationMethod: "spray",
        duration: "3-4 weeks",
        cost: 250,
        precautions: "Wear protective equipment",
        unavailableRegions: []
      }
    ],
    organic: [
      {
        name: "Bordeaux Mixture",
        composition: "Copper Sulfate 1% + Lime 1%",
        dosage: "5 L per acre",
        application: "Spray every 7 days",
        cost: 150,
        effectiveness: 0.75
      }
    ],
    other: [
      {
        method: "Pruning",
        description: "Remove 30-40% of infected branches",
        frequency: "Weekly until disease controlled"
      }
    ]
  },
  
  // Prevention Measures
  prevention: [
    "Crop rotation (avoid susceptible crops for 2 years)",
    "Use disease-resistant varieties",
    "Maintain proper spacing (2-3 feet)",
    "Avoid overhead irrigation",
    "Remove plant debris after harvest",
    "Sanitize tools between plants"
  ],
  
  // Weather & Environmental Factors
  weatherFactors: {
    optimal_humidity: "90-95%",
    optimal_temperature: "15-25°C",
    rainfall_effect: "Higher risk with heavy rainfall",
    wind_sensitivity: "Spreads quickly in humid conditions",
    soil_moisture: "High risk in waterlogged soil"
  },
  
  // Related Information
  relatedCrops: ["potato", "pepper", "eggplant"],
  relatedDiseases: ["Late Blight", "Leaf Spot"],
  similarDiseases: [
    {
      name: "Late Blight",
      similarity: 0.78,
      differences: "Late Blight affects stems more"
    }
  ],
  
  // Fertilizer Recommendations
  fertilizerRecommendations: [
    {
      type: "Nitrogen",
      reason: "Boost plant immunity",
      dosage: "5-10 kg/acre",
      timing: "Weekly intervals"
    }
  ],
  
  // Model Information
  modelInfo: {
    modelName: "best_model.h5",
    modelVersion: "2.1",
    framework: "TensorFlow",
    trainingDate: ISODate("2023-12-01T00:00:00Z"),
    accuracy: 0.94,
    datasetUsed: "crop_disease_data.csv"
  },
  
  // Metadata
  detectionScore: 0.92,
  confidence: 0.92,
  processingTime: 2345, // milliseconds
  processingTimestamp: ISODate("2024-01-20T14:30:00Z"),
  isVerified: false,
  expertVerification: null,
  userFeedback: null,
  
  // Timestamps
  createdAt: ISODate("2024-01-20T14:30:00Z"),
  updatedAt: ISODate("2024-01-20T14:30:00Z"),
  expiresAt: ISODate("2025-01-20T14:30:00Z") // TTL index
}
```

### Indexes

```javascript
db.detections.createIndex({ userId: 1, createdAt: -1 })
db.detections.createIndex({ cropType: 1 })
db.detections.createIndex({ "disease.name": 1 })
db.detections.createIndex({ confidence: -1 })
db.detections.createIndex({ createdAt: -1 })
db.detections.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 })
```

---

## 📰 News Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0j9"),
  
  // Content
  title: "New government subsidy for organic farming announced",
  summary: "The government announced a new subsidy scheme for organic farmers",
  content: "The government has announced a new subsidy scheme...",
  author: "Ministry of Agriculture",
  source: "Ministry of Agriculture",
  sourceUrl: "https://news-source.com/article",
  
  // Media
  image: "https://s3.amazonaws.com/news/image.jpg",
  imageCaption: "Farmers at subsidy announcement event",
  images: [
    { url: "https://...", caption: "..." }
  ],
  
  // Categorization
  category: "policy", // agriculture, market, weather, policy, research
  subcategory: "subsidy",
  tags: ["subsidy", "organic", "government"],
  keywords: ["organic farming", "government support", "financial assistance"],
  
  // Geographic Relevance
  relevantStates: ["Maharashtra", "Punjab", "Karnataka"],
  relevantRegions: ["North India", "Western India"],
  
  // Engagement
  views: 1250,
  shares: 150,
  comments: 25,
  likes: 450,
  
  // Source Information
  sourceType: "government", // government, news_agency, blog, research
  credibilityScore: 0.95,
  isVerified: true,
  
  // Publication Details
  publishedDate: ISODate("2024-01-20T10:00:00Z"),
  originalPublishDate: ISODate("2024-01-20T08:00:00Z"),
  expiryDate: ISODate("2024-02-20T10:00:00Z"),
  
  // Metadata
  createdAt: ISODate("2024-01-20T10:30:00Z"),
  updatedAt: ISODate("2024-01-20T14:30:00Z"),
  isDraft: false,
  isPublished: true,
  isArchived: false,
  dataSource: "news_api"
}
```

---

## 🛒 Products Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0ja"),
  
  // Product Information
  name: "Premium Hybrid Cotton Seeds COH-48",
  description: "High-yielding, disease-resistant hybrid seeds...",
  sku: "SEEDS-COTTON-COH48",
  
  // Categorization
  category: "seeds", // seeds, fertilizers, tools, pesticides
  subcategory: "hybrid_cotton",
  tags: ["cotton", "hybrid", "high-yield"],
  
  // Pricing
  price: 450,
  originalPrice: 550,
  discountPercentage: 18,
  discountEndDate: ISODate("2024-02-15T00:00:00Z"),
  currency: "INR",
  
  // Images
  image: "https://s3.amazonaws.com/products/product123.jpg",
  images: [
    "https://s3.amazonaws.com/products/product123_1.jpg",
    "https://s3.amazonaws.com/products/product123_2.jpg"
  ],
  
  // Stock Management
  stock: 250,
  minStockLevel: 50,
  maxStockLevel: 1000,
  reorderQuantity: 200,
  
  // Seller Information
  sellerName: "AgriSeeds India",
  sellerId: ObjectId("..."),
  sellerRating: 4.7,
  sellerReviewCount: 342,
  
  // Product Specifications
  specifications: {
    yield: "2000-2200 kg/acre",
    duration: "180-200 days",
    soilType: "Black soil, well-drained",
    waterRequirement: "1200-1600 mm",
    temperature: "20-30°C optimal",
    varieties: ["DCH-32", "DCH-40"],
    purityPercentage: 98.5,
    germinationRate: 96,
    packagingSize: "50 kg bags"
  },
  
  // Ratings & Reviews
  avgRating: 4.5,
  reviewCount: 28,
  reviews: [
    {
      _id: ObjectId("..."),
      userId: ObjectId("..."),
      userName: "Ramesh Kumar",
      rating: 5,
      comment: "Excellent seeds, very good germination rate",
      helpful: 12,
      unhelpful: 1,
      createdAt: ISODate("2024-01-15T10:30:00Z")
    }
  ],
  
  // Shipping
  shippingInfo: {
    estimatedDays: "3-5",
    shippingCost: 50,
    freeShippingAbove: 999,
    domestic: true,
    international: false,
    shippingWeight: 55 // kg
  },
  
  // Related Products
  relatedProducts: [ObjectId("..."), ObjectId("...")],
  byBrand: "AgriSeeds",
  
  // Metadata
  isActive: true,
  isFeatured: true,
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-01-20T14:30:00Z"),
  viewCount: 5420,
  purchaseCount: 234
}
```

### Indexes

```javascript
db.products.createIndex({ category: 1 })
db.products.createIndex({ price: 1 })
db.products.createIndex({ avgRating: -1 })
db.products.createIndex({ "seller.id": 1 })
db.products.createIndex({ tags: 1 })
db.products.createIndex({ name: "text", description: "text" })
```

---

## 🛍️ Orders Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0jb"),
  
  // Order Information
  orderId: "ORDER-2024-00156",
  userId: ObjectId("64e1a2b3c4d5e6f7g8h9i0j1"),
  
  // Items
  items: [
    {
      _id: ObjectId("..."),
      productId: ObjectId("..."),
      productName: "Premium Hybrid Cotton Seeds COH-48",
      sku: "SEEDS-COTTON-COH48",
      quantity: 2,
      price: 450,
      discountedPrice: 369,
      subtotal: 738,
      tax: 133
    }
  ],
  
  // Pricing
  subtotal: 738,
  taxAmount: 133,
  shippingCost: 50,
  discountApplied: 0,
  couponCode: null,
  totalAmount: 921,
  
  // Shipping Address
  shippingAddress: {
    name: "John Doe",
    phone: "+91-9876543210",
    email: "john@example.com",
    address: "Farm House, Village XYZ",
    landmark: "Near School",
    city: "Pune",
    district: "Pune",
    state: "Maharashtra",
    pincode: "411001",
    country: "India"
  },
  
  // Billing Address
  billingAddress: { /* same structure */ },
  sameAsBilling: false,
  
  // Payment Information
  paymentMethod: "card", // card, netbanking, upi, wallet
  paymentStatus: "success", // pending, processing, failed, success, refunded
  paymentId: "PAY-2024-00156",
  transactionId: "RAZORPAY123456",
  paymentDate: ISODate("2024-01-15T14:35:00Z"),
  paymentProof: "https://s3.amazonaws.com/receipts/receipt.pdf",
  
  // Order Status
  orderStatus: "delivered", // pending, confirmed, processing, shipped, delivered, cancelled
  statusHistory: [
    {
      status: "pending",
      timestamp: ISODate("2024-01-15T14:30:00Z"),
      comment: "Order received"
    },
    {
      status: "confirmed",
      timestamp: ISODate("2024-01-15T14:45:00Z"),
      comment: "Payment confirmed"
    }
  ],
  
  // Shipping Tracking
  trackingId: "TRACK-2024-00156",
  trackingProvider: "bluedart",
  trackingUrl: "https://tracking.bluedart.com/TRACK-2024-00156",
  estimatedDeliveryDate: ISODate("2024-01-18T00:00:00Z"),
  actualDeliveryDate: ISODate("2024-01-17T14:30:00Z"),
  deliveryAttempts: 1,
  
  // Return & Refund
  canReturn: false,
  returnDays: 7,
  isReturned: false,
  returnReason: null,
  refundStatus: null,
  
  // Metadata
  createdAt: ISODate("2024-01-15T14:30:00Z"),
  updatedAt: ISODate("2024-01-17T14:30:00Z"),
  cancelledAt: null,
  cancelledBy: null,
  notes: "Customer requested fast delivery",
  internalNotes: "High priority order"
}
```

### Indexes

```javascript
db.orders.createIndex({ userId: 1, createdAt: -1 })
db.orders.createIndex({ orderId: 1 }, { unique: true })
db.orders.createIndex({ paymentStatus: 1 })
db.orders.createIndex({ orderStatus: 1 })
db.orders.createIndex({ createdAt: -1 }, { expireAfterSeconds: 2592000 })
db.orders.createIndex({ trackingId: 1 })
```

---

## 🔔 Notifications Collection

### Schema

```javascript
{
  _id: ObjectId("64e1a2b3c4d5e6f7g8h9i0jc"),
  
  // Recipient
  userId: ObjectId("64e1a2b3c4d5e6f7g8h9i0j1"),
  
  // Notification Content
  type: "weather_alert", // order, forum, weather, system, promotion
  title: "Heavy rainfall alert",
  message: "Heavy rainfall expected in your area today",
  description: "Expected rainfall: 50-75mm, be cautious with irrigation",
  
  // Notification Data
  data: {
    alertId: ObjectId("..."),
    severity: "high",
    actionUrl: "/weather/alerts/123",
    imageUrl: "https://..."
  },
  
  // Status
  read: false,
  readAt: null,
  deleted: false,
  deletedAt: null,
  
  // Priority & Urgency
  priority: "high", // low, normal, high, critical
  urgency: "immediate",
  
  // Delivery
  sentAt: ISODate("2024-01-20T14:30:00Z"),
  channels: ["in-app", "push", "email"],
  deliveredVia: ["in-app", "push"],
  emailSent: false,
  pushSent: true,
  
  // Metadata
  createdAt: ISODate("2024-01-20T14:30:00Z"),
  expiresAt: ISODate("2024-02-20T14:30:00Z"),
  category: "alerts"
}
```

---

## 📊 Statistics & Analytics

### User Activity Tracking

```javascript
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),
  date: ISODate("2024-01-20T00:00:00Z"),
  
  activity: {
    forumPostsCreated: 2,
    forumPostsViewed: 15,
    solutionsProvided: 1,
    cropDetectionsUsed: 2,
    weatherChecks: 8,
    newsRead: 12,
    productsViewed: 25,
    ordersPlaced: 1,
    cartAbandoned: 0
  },
  
  engagement: {
    sessionCount: 5,
    totalSessionTime: 2340, // seconds
    pageViewCount: 87,
    clickCount: 234
  }
}
```

---

## 🔗 Relationships & References

```
Users (1) ─── many ─── Posts (Forum)
   │
   ├── many ─── ML Detections
   ├── many ─── Orders
   ├── many ─── Reviews
   └── many ─── Notifications

Posts (1) ─── many ─── Solutions (Nested in document)
Posts (1) ─── many ─── Comments

Products (1) ─── many ─── Orders (As items)
Products (1) ─── many ─── Reviews

Weather (State + District) ─── many ─── Users (Location reference)

News (1) ─── many ─── Views (User engagement)
```

---

## 🔐 Data Validation Rules

### Users
- Email: Valid email format, unique
- Phone: 10 digits, optional
- Password: Min 8 chars, uppercase, number, special char
- First/Last Name: 2-50 characters

### Posts
- Title: 10-300 characters, required
- Content: 20-10000 characters
- Category: One of allowed categories
- Tags: Max 10 tags

### Products
- Price: Minimum 0, required
- Stock: Integer ≥ 0
- Category: One of allowed categories
- Images: Max 5 images

### Orders
- Items: Min 1 item, max 100 items per order
- Total: Positive number
- Status: Valid status only

---

## 📈 Database Growth Estimates

Based on 100,000 active users:

| Collection | Estimated Documents | Size |
|------------|-------------------|------|
| Users | 100,000 | ~20 MB |
| Posts | 200,000 | ~40 MB |
| Weather | 1,000 | ~2 MB |
| Detections | 500,000 | ~100 MB |
| Products | 10,000 | ~5 MB |
| Orders | 100,000 | ~30 MB |
| News | 50,000 | ~15 MB |
| Notifications | 2,000,000 | ~200 MB |

**Total**: ~412 MB (can grow to GB with more data)

---

## ⚙️ Database Optimization Tips

1. **Indexing**: Create indexes on frequently queried fields
2. **Pagination**: Always paginate results (limit queries)
3. **Projection**: Select only needed fields
4. **Aggregation**: Use aggregation pipeline for complex queries
5. **Sharding**: Consider horizontal scaling for large datasets
6. **TTL Indexes**: Auto-expire old documents
7. **Compression**: Enable compression in MongoDB

---

## 📚 Related Documentation

- [API Reference](./API_REFERENCE.md) - Endpoint documentation
- [Architecture](./ARCHITECTURE.md) - System design
- [MongoDB Documentation](https://docs.mongodb.com/)

---

<div align="center">

**Last Updated**: January 2024
**Status**: Active
**Database Version**: MongoDB 5.0+

</div>
