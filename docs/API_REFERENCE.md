# 📡 API Reference - Govi Sahaya

Complete documentation of all REST API endpoints for the Govi Sahaya backend.

**Base URL**: `http://localhost:5000/api` (development) | `https://api.govisahaya.com/api` (production)

**Authentication**: All endpoints except login/register require JWT token in Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

---

## 📑 Table of Contents

1. [Authentication](#authentication)
2. [Users](#users)
3. [Weather](#weather)
4. [ML Services (Crop Doctor)](#ml-services)
5. [Forum/Community](#forum)
6. [News](#news)
7. [Shop](#shop)
8. [Notifications](#notifications)
9. [Health Check](#health-check)
10. [Error Handling](#error-handling)

---

## 🔐 Authentication

### Register User

**POST** `/auth/register`

Create a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+91-9876543210"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully. Check your email for verification.",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+91-9876543210",
    "isEmailVerified": false,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

**Error (400):**
```json
{
  "success": false,
  "message": "Email already exists",
  "code": "DUPLICATE_EMAIL"
}
```

**Validation Rules:**
- Email: Valid email format
- Password: Min 8 chars, 1 uppercase, 1 number, 1 special char
- Phone: Valid 10-digit format

---

### Login User

**POST** `/auth/login`

Authenticate and get JWT token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "isEmailVerified": true
  },
  "expiresIn": 3600
}
```

**Error (401):**
```json
{
  "success": false,
  "message": "Invalid email or password",
  "code": "INVALID_CREDENTIALS"
}
```

---

### Verify Email

**POST** `/auth/verify-email`

Verify email with OTP code.

**Request Body:**
```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

---

### Refresh Token

**POST** `/auth/refresh-token`

Get new JWT token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

---

### Logout

**POST** `/auth/logout`

Logout and invalidate tokens.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

### Forgot Password

**POST** `/auth/forgot-password`

Request password reset email.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset email sent"
}
```

---

### Reset Password

**POST** `/auth/reset-password`

Reset password with reset token.

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "newPassword": "NewPassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

## 👤 Users

### Get User Profile

**GET** `/users/profile`

Retrieve current user's profile.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+91-9876543210",
    "profilePic": "https://s3.amazonaws.com/user_profiles/123.jpg",
    "location": {
      "state": "Maharashtra",
      "district": "Pune",
      "latitude": 18.5204,
      "longitude": 73.8567
    },
    "cropInfo": {
      "mainCrops": ["wheat", "cotton"],
      "farmSize": 50,
      "farmType": "organic"
    },
    "isEmailVerified": true,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

---

### Update User Profile

**PUT** `/users/profile`

Update user information.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+91-9876543210",
  "location": {
    "state": "Maharashtra",
    "district": "Pune",
    "latitude": 18.5204,
    "longitude": 73.8567
  },
  "cropInfo": {
    "mainCrops": ["wheat", "cotton", "sugarcane"],
    "farmSize": 75,
    "farmType": "organic"
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": { /* updated user object */ }
}
```

---

### Upload Profile Picture

**PUT** `/users/profile-picture`

Upload profile picture.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: multipart/form-data
```

**Form Data:**
```
file: <image file>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile picture updated",
  "profilePic": "https://s3.amazonaws.com/user_profiles/507f1f77bcf86cd799439011.jpg"
}
```

**Constraints:**
- File size: Max 5MB
- Format: PNG, JPG, JPEG
- Dimensions: Min 200x200px

---

### Get User Statistics

**GET** `/users/statistics`

Get user activity statistics.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "statistics": {
    "totalForumPosts": 15,
    "totalComments": 42,
    "totalDetections": 8,
    "totalOrders": 12,
    "wishlistItems": 5,
    "joinedDate": "2024-01-15T10:30:00Z"
  }
}
```

---

## 🌤️ Weather

### Get Weather Data

**GET** `/weather?state=Maharashtra&district=Pune`

Get current weather and forecast data.

**Query Parameters:**
- `state` (required): State name
- `district` (optional): District name
- `latitude` (optional): Latitude coordinate
- `longitude` (optional): Longitude coordinate

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "weather": {
    "location": {
      "state": "Maharashtra",
      "district": "Pune"
    },
    "current": {
      "temp": 28.5,
      "feelsLike": 32.1,
      "humidity": 65,
      "windSpeed": 12.3,
      "windDirection": "NE",
      "rainfall": 0,
      "pressure": 1013,
      "uvIndex": 6,
      "visibility": 10,
      "condition": "Partly Cloudy",
      "description": "Partly cloudy with 30% chance of rain",
      "icon": "02d",
      "timestamp": "2024-01-20T14:30:00Z"
    },
    "forecast": [
      {
        "date": "2024-01-21",
        "daily": {
          "tempMax": 32.5,
          "tempMin": 18.3,
          "humidity": 60,
          "rainfall": 0,
          "condition": "Sunny",
          "windSpeed": 10
        }
      }
    ],
    "alerts": [
      {
        "_id": "507f1f77bcf86cd799439011",
        "type": "heat_wave",
        "severity": "moderate",
        "message": "Heat wave warning: Temperatures may exceed 35°C",
        "startTime": "2024-01-21T08:00:00Z",
        "endTime": "2024-01-25T18:00:00Z"
      }
    ],
    "plantingRecommendations": [
      {
        "crop": "wheat",
        "recommendation": "Ideal conditions for watering. Plan irrigation for next 3 days.",
        "confidence": 0.85
      }
    ]
  }
}
```

---

### Get Weather Alerts

**GET** `/weather/alerts?state=Maharashtra`

Get weather alerts for location.

**Query Parameters:**
- `state` (required): State name
- `district` (optional): District name

**Response (200):**
```json
{
  "success": true,
  "alerts": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "location": { "state": "Maharashtra", "district": "Pune" },
      "type": "high_rainfall",
      "severity": "high",
      "message": "Heavy rainfall alert: 80-100mm expected in next 24 hours",
      "startTime": "2024-01-20T20:00:00Z",
      "endTime": "2024-01-21T20:00:00Z",
      "recommendations": [
        "Delay pesticide application",
        "Check irrigation systems",
        "Secure loose crop covers"
      ]
    }
  ]
}
```

---

### Get Weather History

**GET** `/weather/history?state=Maharashtra&days=7`

Get historical weather data.

**Query Parameters:**
- `state` (required): State name
- `days` (optional, default=7): Number of days

**Response (200):**
```json
{
  "success": true,
  "history": [
    {
      "date": "2024-01-20",
      "tempMax": 30.2,
      "tempMin": 18.5,
      "rainfall": 2.5,
      "humidity": 65,
      "condition": "Partly Cloudy"
    }
  ]
}
```

---

## 🤖 ML Services (Crop Doctor)

### Crop Disease Detection

**POST** `/ml/detect-disease`

Upload crop image for disease detection.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: multipart/form-data
```

**Form Data:**
```
image: <image file>
crop: "tomato" (optional)
```

**Response (200):**
```json
{
  "success": true,
  "detection": {
    "detectionId": "507f1f77bcf86cd799439011",
    "disease": {
      "name": "Early Blight",
      "scientificName": "Alternaria solani",
      "confidence": 0.92,
      "description": "Fungal disease causing brown spots on leaves and stems"
    },
    "severity": "moderate",
    "affectedAreas": "15-20% of leaf coverage",
    "treatment": {
      "immediate": [
        "Remove infected leaves immediately",
        "Improve air circulation",
        "Water at base of plant only"
      ],
      "fungicides": [
        {
          "name": "Chlorothalonil",
          "dosage": "2.5 g/L water",
          "interval": "7-10 days",
          "precautions": "Wear protective equipment"
        }
      ],
      "organic": [
        {
          "name": "Bordeaux Mixture",
          "composition": "Copper Sulfate 1% + Lime 1%",
          "application": "Spray every 7 days"
        }
      ]
    },
    "prevention": [
      "Crop rotation",
      "Use disease-resistant varieties",
      "Maintain proper spacing",
      "Remove plant debris"
    ],
    "relatedCrops": ["potato", "pepper"],
    "weatherFactors": {
      "optimal_humidity": "90-95%",
      "optimal_temperature": "15-25°C",
      "rainfall_effect": "Higher risk with heavy rainfall"
    },
    "timestamp": "2024-01-20T14:30:00Z"
  }
}
```

---

### Get Detection History

**GET** `/ml/detection-history?limit=10`

Get user's past detections.

**Query Parameters:**
- `limit` (optional, default=10): Number of records
- `crop` (optional): Filter by crop type

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "detections": [
    {
      "detectionId": "507f1f77bcf86cd799439011",
      "crop": "tomato",
      "disease": "Early Blight",
      "confidence": 0.92,
      "date": "2024-01-20T14:30:00Z",
      "imageUrl": "https://s3.amazonaws.com/detections/507f1f77bcf86cd799439011.jpg"
    }
  ],
  "totalDetections": 8
}
```

---

### Get Crop Recommendations

**POST** `/ml/crop-recommendation`

Get crop recommendations based on conditions.

**Request Body:**
```json
{
  "state": "Maharashtra",
  "district": "Pune",
  "latitude": 18.5204,
  "longitude": 73.8567,
  "soilType": "black_soil",
  "waterAvailability": "moderate",
  "budget": 50000,
  "farmSize": 50
}
```

**Response (200):**
```json
{
  "success": true,
  "recommendations": [
    {
      "rank": 1,
      "crop": "cotton",
      "suitability": 0.95,
      "reasoning": "Excellent for black soil in this region",
      "profitability": {
        "estimatedYield": "2000 kg/acre",
        "marketPrice": "40-50/kg",
        "estimatedIncome": "80000-100000",
        "estimatedCost": "45000",
        "netProfit": "35000-55000"
      },
      "soilRequirements": "Black soil, well-drained",
      "waterRequirements": "1200-1600 mm annually",
      "growingPeriod": "180-210 days",
      "bestSowingTime": "May-June",
      "harvestTime": "December-January",
      "pestsAndDiseases": ["Bollworms", "Leaf spot"],
      "varieties": [
        {
          "name": "DCH-32",
          "yield": "2000 kg/acre",
          "resistantTo": ["Vertillium wilt", "Leaf curl virus"]
        }
      ]
    }
  ]
}
```

---

## 💬 Forum (Community)

### Get All Posts

**GET** `/forum/posts?category=diseases&page=1&limit=10`

Get forum posts with pagination.

**Query Parameters:**
- `category` (optional): diseases, techniques, market, general
- `page` (optional, default=1): Page number
- `limit` (optional, default=10): Posts per page
- `sort` (optional): recent, trending, top-rated

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "posts": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "title": "How to treat wheat powdery mildew?",
      "content": "My wheat crop has developed white powder on leaves...",
      "category": "diseases",
      "author": {
        "_id": "507f1f77bcf86cd799439012",
        "firstName": "Ram",
        "lastName": "Kumar",
        "profilePic": "https://s3.amazonaws.com/profile.jpg"
      },
      "tags": ["wheat", "powdery_mildew", "fungicide"],
      "upvotes": 24,
      "views": 156,
      "solutions": [
        {
          "solutionId": "507f1f77bcf86cd799439013",
          "author": {
            "_id": "507f1f77bcf86cd799439014",
            "firstName": "Sita",
            "lastName": "Singh"
          },
          "text": "Apply sulphur spray at 2.5 g/L water every 7 days...",
          "rating": 4.5,
          "helpful": 18,
          "timestamp": "2024-01-18T10:30:00Z"
        }
      ],
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-20T14:30:00Z"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalPosts": 47
  }
}
```

---

### Create Forum Post

**POST** `/forum/posts`

Create a new forum post.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "Best practices for organic cotton farming",
  "content": "I recently switched to organic cotton farming...",
  "category": "techniques",
  "tags": ["cotton", "organic", "sustainable"],
  "images": ["url1", "url2"]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Post created successfully",
  "post": {
    "_id": "507f1f77bcf86cd799439011",
    "title": "Best practices for organic cotton farming",
    "content": "I recently switched to organic cotton farming...",
    "category": "techniques",
    "author": { /* current user */ },
    "tags": ["cotton", "organic", "sustainable"],
    "upvotes": 0,
    "views": 0,
    "solutions": [],
    "createdAt": "2024-01-20T14:30:00Z"
  }
}
```

---

### Add Solution to Post

**POST** `/forum/posts/{postId}/solutions`

Add a solution/answer to a post.

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "text": "Try spraying neem oil solution at early morning...",
  "images": ["url1"]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Solution added successfully",
  "solution": {
    "solutionId": "507f1f77bcf86cd799439013",
    "author": { /* current user */ },
    "text": "Try spraying neem oil solution...",
    "images": ["url1"],
    "rating": 0,
    "helpful": 0,
    "timestamp": "2024-01-20T14:30:00Z"
  }
}
```

---

### Get Post Details

**GET** `/forum/posts/{postId}`

Get detailed view of a post with all solutions.

**Response (200):**
```json
{
  "success": true,
  "post": {
    "_id": "507f1f77bcf86cd799439011",
    "title": "How to treat wheat powdery mildew?",
    "content": "My wheat crop has developed white powder on leaves...",
    "category": "diseases",
    "author": { /* author details */ },
    "tags": ["wheat", "powdery_mildew"],
    "upvotes": 24,
    "views": 156,
    "solutions": [
      { /* solutions array */ }
    ],
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-20T14:30:00Z"
  }
}
```

---

### Rate Solution

**POST** `/forum/posts/{postId}/solutions/{solutionId}/rate`

Rate a solution helpful/unhelpful.

**Request Body:**
```json
{
  "rating": 5,
  "helpful": true
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Rating submitted",
  "solution": { /* updated solution */ }
}
```

---

## 📰 News

### Get News Feed

**GET** `/news?category=agriculture&limit=10&page=1`

Get latest agricultural news.

**Query Parameters:**
- `category` (optional): agriculture, market, weather, policy, research
- `limit` (optional, default=10): Posts per page
- `page` (optional, default=1): Page number
- `state` (optional): Filter by state

**Response (200):**
```json
{
  "success": true,
  "news": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "title": "New government subsidy for organic farming announced",
      "content": "The government has announced a new subsidy scheme...",
      "category": "policy",
      "source": "Ministry of Agriculture",
      "image": "https://s3.amazonaws.com/news/507f1f77bcf86cd799439011.jpg",
      "url": "https://news-source.com/article",
      "summary": "New subsidy scheme launched for organic farmers",
      "pubDate": "2024-01-20T10:00:00Z",
      "relevantStates": ["Maharashtra", "Punjab"],
      "tags": ["subsidy", "organic", "government"]
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 15,
    "totalNews": 145
  }
}
```

---

### Get News Details

**GET** `/news/{newsId}`

Get detailed news article.

**Response (200):**
```json
{
  "success": true,
  "news": {
    "_id": "507f1f77bcf86cd799439011",
    "title": "New government subsidy for organic farming announced",
    "content": "The government has announced a new subsidy scheme...",
    "category": "policy",
    "source": "Ministry of Agriculture",
    "image": "https://s3.amazonaws.com/news/507f1f77bcf86cd799439011.jpg",
    "url": "https://news-source.com/article",
    "summary": "New subsidy scheme launched for organic farmers",
    "pubDate": "2024-01-20T10:00:00Z",
    "relatedArticles": [ /* array of related news */ ]
  }
}
```

---

## 🛒 Shop

### Get Products

**GET** `/shop/products?category=seeds&limit=20&page=1`

Get shop products with filters.

**Query Parameters:**
- `category` (optional): seeds, fertilizers, tools, pesticides
- `limit` (optional, default=20): Items per page
- `page` (optional, default=1): Page number
- `minPrice` (optional): Minimum price filter
- `maxPrice` (optional): Maximum price filter
- `search` (optional): Search term
- `sort` (optional): price_asc, price_desc, rating, trending

**Response (200):**
```json
{
  "success": true,
  "products": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "name": "Premium Hybrid Cotton Seeds COH-48",
      "description": "High-yielding, disease-resistant hybrid seeds",
      "category": "seeds",
      "price": 450,
      "originalPrice": 550,
      "discount": 18,
      "stock": 250,
      "rating": 4.5,
      "reviews": 28,
      "image": "https://s3.amazonaws.com/products/507f1f77bcf86cd799439011.jpg",
      "images": ["url1", "url2", "url3"],
      "seller": "AgriSeeds India",
      "specifications": {
        "yield": "2000-2200 kg/acre",
        "duration": "180-200 days",
        "soilType": "Black soil, well-drained",
        "water": "1200-1600 mm"
      },
      "inWishlist": false,
      "inCart": false
    }
  ],
  "filters": {
    "categories": ["seeds", "fertilizers", "tools", "pesticides"],
    "priceRange": { "min": 100, "max": 50000 },
    "ratings": [5, 4, 3, 2, 1]
  },
  "pagination": {
    "currentPage": 1,
    "totalPages": 8,
    "totalProducts": 156
  }
}
```

---

### Get Product Details

**GET** `/shop/products/{productId}`

Get detailed product information.

**Response (200):**
```json
{
  "success": true,
  "product": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "Premium Hybrid Cotton Seeds COH-48",
    "description": "High-yielding, disease-resistant hybrid seeds...",
    "category": "seeds",
    "price": 450,
    "originalPrice": 550,
    "discount": 18,
    "stock": 250,
    "rating": 4.5,
    "reviews": [
      {
        "reviewId": "507f1f77bcf86cd799439012",
        "user": "Ramesh Kumar",
        "rating": 5,
        "comment": "Excellent seeds, very good germination rate",
        "date": "2024-01-15T10:30:00Z"
      }
    ],
    "specifications": { /* detailed specs */ },
    "seller": "AgriSeeds India",
    "shippingInfo": {
      "estimatedDays": "3-5",
      "shippingCost": 50,
      "freeShippingAbove": 999
    },
    "relatedProducts": [ /* array of related products */ ]
  }
}
```

---

### Add to Cart

**POST** `/shop/cart`

Add item to shopping cart.

**Request Body:**
```json
{
  "productId": "507f1f77bcf86cd799439011",
  "quantity": 2
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Product added to cart",
  "cart": {
    "cartId": "507f1f77bcf86cd799439020",
    "items": [
      {
        "productId": "507f1f77bcf86cd799439011",
        "name": "Premium Hybrid Cotton Seeds",
        "price": 450,
        "quantity": 2,
        "total": 900
      }
    ],
    "subtotal": 900,
    "tax": 162,
    "total": 1062
  }
}
```

---

### Get Cart

**GET** `/shop/cart`

Get current shopping cart.

**Response (200):**
```json
{
  "success": true,
  "cart": {
    "cartId": "507f1f77bcf86cd799439020",
    "items": [ /* array of items */ ],
    "subtotal": 900,
    "discount": 0,
    "tax": 162,
    "shippingCost": 50,
    "total": 1112,
    "appliedCoupon": null,
    "lastUpdated": "2024-01-20T14:30:00Z"
  }
}
```

---

### Create Order

**POST** `/shop/orders`

Place an order from cart.

**Request Body:**
```json
{
  "shippingAddress": {
    "name": "John Doe",
    "phone": "+91-9876543210",
    "address": "Farm House, Village XYZ",
    "district": "Pune",
    "state": "Maharashtra",
    "pincode": "411001"
  },
  "paymentMethod": "card",
  "couponCode": "AGRI50"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Order created. Proceed to payment.",
  "order": {
    "orderId": "507f1f77bcf86cd799439030",
    "userId": "507f1f77bcf86cd799439011",
    "items": [ /* order items */ ],
    "totalAmount": 1062,
    "paymentStatus": "pending",
    "orderStatus": "pending",
    "paymentId": null,
    "shippingAddress": { /* address */ },
    "createdAt": "2024-01-20T14:30:00Z"
  }
}
```

---

### Get Orders

**GET** `/shop/orders?status=all&limit=10`

Get user's orders.

**Query Parameters:**
- `status` (optional): pending, processing, shipped, delivered
- `limit` (optional, default=10)
- `page` (optional, default=1)

**Response (200):**
```json
{
  "success": true,
  "orders": [
    {
      "orderId": "507f1f77bcf86cd799439030",
      "items": [ /* items */ ],
      "totalAmount": 1062,
      "paymentStatus": "success",
      "orderStatus": "delivered",
      "trackingId": "TRACK123",
      "deliveredAt": "2024-01-18T10:30:00Z",
      "createdAt": "2024-01-15T14:30:00Z"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 2,
    "totalOrders": 12
  }
}
```

---

## 🔔 Notifications

### Get Notifications

**GET** `/notifications?limit=20&page=1`

Get user notifications.

**Query Parameters:**
- `limit` (optional, default=20)
- `page` (optional, default=1)
- `read` (optional): true/false

**Response (200):**
```json
{
  "success": true,
  "notifications": [
    {
      "notificationId": "507f1f77bcf86cd799439011",
      "type": "weather_alert",
      "title": "Heavy rainfall alert",
      "message": "Heavy rainfall expected in your area today",
      "data": {
        "alertId": "507f1f77bcf86cd799439012",
        "severity": "high"
      },
      "read": false,
      "createdAt": "2024-01-20T14:30:00Z"
    }
  ],
  "unreadCount": 5,
  "pagination": {
    "currentPage": 1,
    "totalPages": 2,
    "totalNotifications": 35
  }
}
```

---

### Mark as Read

**PUT** `/notifications/{notificationId}/read`

Mark notification as read.

**Response (200):**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

### Clear Notifications

**DELETE** `/notifications`

Clear all notifications.

**Query Parameters:**
- `read` (optional, default=true): Clear only read notifications

**Response (200):**
```json
{
  "success": true,
  "message": "Notifications cleared"
}
```

---

## 💚 Health Check

### API Health

**GET** `/health`

Check API server status.

**Response (200):**
```json
{
  "success": true,
  "status": "healthy",
  "message": "API server is running",
  "timestamp": "2024-01-20T14:30:00Z",
  "uptime": 3600,
  "checks": {
    "database": "healthy",
    "cache": "healthy",
    "mlService": "healthy"
  }
}
```

---

### API Status

**GET** `/status`

Get detailed API status.

**Response (200):**
```json
{
  "success": true,
  "api": "Govi Sahaya Backend",
  "version": "1.0.0",
  "environment": "production",
  "status": "operational",
  "services": {
    "database": "healthy",
    "cache": "healthy",
    "mlAPI": "healthy",
    "weather": "healthy",
    "payment": "healthy",
    "email": "healthy"
  },
  "requestCount": 15234,
  "averageResponseTime": 145,
  "lastError": null
}
```

---

## ⚠️ Error Handling

### Error Response Format

All errors follow this standard format:

```json
{
  "success": false,
  "message": "Brief error message",
  "code": "ERROR_CODE",
  "details": "Additional error details (optional)",
  "timestamp": "2024-01-20T14:30:00Z"
}
```

### Common HTTP Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | OK | Successful request |
| 201 | Created | Resource created |
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Invalid/missing JWT token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Email already exists |
| 413 | Payload Too Large | File size exceeded |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Server Error | Internal server error |
| 503 | Service Unavailable | Database down, etc. |

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| INVALID_CREDENTIALS | 401 | Wrong email/password |
| TOKEN_EXPIRED | 401 | JWT token expired |
| INVALID_TOKEN | 401 | Malformed JWT token |
| MISSING_TOKEN | 401 | Authorization header missing |
| DUPLICATE_EMAIL | 409 | Email already registered |
| INVALID_INPUT | 400 | Validation failed |
| FILE_TOO_LARGE | 413 | File exceeds size limit |
| INVALID_FILE_TYPE | 400 | Unsupported file format |
| RESOURCE_NOT_FOUND | 404 | Resource doesn't exist |
| INSUFFICIENT_STOCK | 400 | Product out of stock |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

### Rate Limiting

Endpoints are rate-limited to prevent abuse:

- **Authentication**: 5 requests per 15 minutes per IP
- **General API**: 100 requests per 15 minutes per user
- **File Upload**: 10 requests per hour per user

Rate limit info in response headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 85
X-RateLimit-Reset: 1642684200
```

---

## 🔗 Related Documentation

- [Architecture](./ARCHITECTURE.md) - System design
- [Database Schema](./DATABASE_SCHEMA.md) - Data models
- [TESTING.md](../TESTING.md) - API testing guide

---

<div align="center">

**Last Updated**: January 2024
**API Version**: 1.0.0
**Status**: ✅ Production Ready

</div>
