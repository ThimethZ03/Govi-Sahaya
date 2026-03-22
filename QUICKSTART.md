# ⚡ Quick Start Guide

Get Govi Sahaya up and running in **5 minutes**!

## 🚀 TL;DR (For Impatient Developers)

```bash
# 1. Clone repo
git clone https://github.com/govi-sahaya/govi-sahaya.git && cd Govi-Sahaya

# 2. Backend setup (Terminal 1)
cd govi_sahaya_backend
npm install
cp .env.example .env
npm run dev

# 3. Frontend setup (Terminal 2)
cd govi_sahaya_mobile
flutter pub get
flutter run

# Done! 🎉
```

---

## 📋 Step-by-Step Setup

### Prerequisites Checklist
```
Backend Requirements:
  ☐ Node.js 18+        (Check: node --version)
  ☐ npm 9+             (Check: npm --version)
  ☐ MongoDB            (Local or Atlas)
  ☐ Git                (Check: git --version)

Frontend Requirements:
  ☐ Flutter 3+         (Check: flutter --version)
  ☐ Dart 3+            (Included with Flutter)
  ☐ Android Studio     (For Android emulator)
  ☐ Git                (Check: git --version)
```

### ✅ Installation Checklist

**Step 1: Clone Repository**
```bash
git clone https://github.com/govi-sahaya/govi-sahaya.git
cd Govi-Sahaya
```
Status: ✅ 1 minute

**Step 2: Backend Setup**
```bash
cd govi_sahaya_backend
npm install              # 2-3 minutes
cp .env.example .env     # Create config
# Edit .env with your credentials
npm run dev              # Start server
```
Status: ✅ 5 minutes

**Step 3: Frontend Setup**
```bash
cd govi_sahaya_mobile
flutter pub get          # Get packages (2-3 minutes)
flutter run              # Run app
```
Status: ✅ 5 minutes

**Total Time: ~10 minutes**

---

## 🔧 Common Setup Issues & Solutions

### Issue 1: "Cannot find module 'express'"
**Solution:**
```bash
cd govi_sahaya_backend
rm -rf node_modules package-lock.json
npm install
```

### Issue 2: "MongoDB connection refused"
**Solution - Option A (Local):**
```bash
# macOS
brew services start mongodb-community

# Windows - Start MongoDB service or:
mongod
```

**Solution - Option B (Cloud):**
1. Go to [mongodb.com](https://mongodb.com)
2. Create cluster
3. Get connection string
4. Add to .env: `MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/govi_sahaya`

### Issue 3: "Port 5000 already in use"
**Solution:**
```bash
# Find process using port 5000
lsof -i :5000

# Kill the process (replace PID)
kill -9 <PID>

# Or change port in .env
PORT=5001
```

### Issue 4: "Flutter command not found"
**Solution:**
```bash
# Add Flutter to PATH
export PATH="$PATH:`flutter/bin`"

# Or add to ~/.bashrc or ~/.zshrc permanently
echo 'export PATH="$PATH:`flutter/bin`"' >> ~/.bashrc
```

### Issue 5: "Device not detected"
**Solution:**
```bash
# List available devices
flutter devices

# Launch Android emulator
flutter emulators --launch <emulator_name>

# Or use physical device with USB debugging
```

### Issue 6: "Firebase authentication failed"
**Solution:**
1. Verify `google-services.json` in `android/app/`
2. Verify `GoogleService-Info.plist` in `ios/Runner/`
3. Check Firebase console has correct SHA-1 fingerprint
4. Regenerate files from Firebase console if needed

---

## 📊 Verification Steps

### Backend Server Verification
```bash
# Should see output like:
✅ Server running in development mode on port 5000
📚 API Documentation: http://localhost:5000/api-docs
✅ MongoDB connected successfully
✅ Firebase initialized successfully
```

### Test Backend API
```bash
# In another terminal, test health endpoint
curl http://localhost:5000/api/health

# Expected response:
# {
#   "success": true,
#   "message": "Server is running"
# }
```

### Frontend App Verification
1. App starts with splash screen
2. Transitions to login screen (if not authenticated)
3. Can see home screen (if authenticated)
4. All bottom navigation items clickable
5. Weather data loads successfully

---

## 🎯 Using the App

### First-Time User Walkthrough

1. **Create Account**
   - Click "Sign Up"
   - Enter name, email, password
   - Verify email
   - Login with credentials

2. **Complete Profile**
   - Go to Profile tab
   - Add location, farm details
   - Upload profile photo

3. **Check Weather**
   - Home tab shows weather
   - View detailed forecast
   - Get crop alerts

4. **Use Crop Doctor**
   - Click "Crop Doctor"
   - Take or upload photo
   - Get disease diagnosis
   - View treatment plan

5. **View News & Community**
   - Browse latest agricultural news
   - Join community discussions
   - Share farming tips

6. **Use Shop**
   - Browse products
   - Add to cart
   - Checkout

---

## 🧪 Testing Your Setup

### Run Backend Tests
```bash
cd govi_sahaya_backend
npm test                    # Run all tests
npm test -- --coverage     # With coverage
npm run test:watch        # Watch mode
```

### Run Frontend Tests
```bash
cd govi_sahaya_mobile
flutter test               # Run all tests
flutter test --coverage   # With coverage
```

---

## 📝 Environment Variables Required

### For `.env` file in `govi_sahaya_backend/`:

```env
# Required for development
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://localhost:27017/govi_sahaya
JWT_SECRET=your-secret-key-change-in-production

# Optional but recommended
FIREBASE_PROJECT_ID=your-project-id
CORS_ORIGIN=http://localhost:3000,http://localhost:8081

# For emails (Gmail example)
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# For weather features
OPENWEATHER_API_KEY=get-from-openweathermap.org
```

---

## 🚀 Run Everything at Once

### Using run-all-tests.sh
```bash
bash run-all-tests.sh
```

---

## 💡 Pro Tips

1. **Use VS Code Extensions**
   - REST Client (for API testing)
   - Dart/Flutter (for Flutter development)
   - MongoDB for VS Code

2. **Monitor API Calls**
   - Use browser DevTools Network tab
   - Or Postman application

3. **Debug Flutter App**
   - Use `flutter logs`
   - Use Dart DevTools: `flutter pub global run devtools`

4. **Keep Dependencies Updated**
   ```bash
   npm outdated      # Backend
   flutter pub outdated  # Frontend
   ```

5. **Use .env.example**
   - Keep as template
   - Never commit .env
   - Copy and customize for your setup

---

## 📚 Next Steps

1. **Read Full Documentation**
   - Main: [README.md](./README.md)
   - Testing: [TESTING.md](./TESTING.md)
   - Setup: [TESTING_SETUP.md](./TESTING_SETUP.md)

2. **Explore Codebase**
   - Backend: `govi_sahaya_backend/src/`
   - Frontend: `govi_sahaya_mobile/lib/`

3. **Try Examples**
   - Test API endpoints
   - Create test user
   - Test all features

4. **Start Contributing**
   - Pick an issue
   - Create feature branch
   - Submit pull request

---

<div align="center">

**Questions?** Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

**Want to contribute?** See [CONTRIBUTING.md](./CONTRIBUTING.md)

</div>
