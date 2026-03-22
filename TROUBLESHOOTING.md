# 🔧 Troubleshooting Guide

Common issues and their solutions.

---

## 💻 Backend Issues

### Issue: "Cannot find module 'express'" or other dependencies missing

**Error Message:**
```
Error: Cannot find module 'express'
at Function.Module._resolveFilename
```

**Solutions:**

1. **Reinstall dependencies**
   ```bash
   cd govi_sahaya_backend
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **Clear npm cache**
   ```bash
   npm cache clean --force
   npm install
   ```

3. **Check Node version**
   ```bash
   node --version  # Should be >= 18.0.0
   npm --version   # Should be >= 9.0.0
   ```

4. **Update npm**
   ```bash
   npm install -g npm@latest
   ```

---

### Issue: "MongoDB connection refused" or "Cannot connect to database"

**Error Messages:**
```
MongooseError: Cannot connect to mongodb
Error: connect ECONNREFUSED 127.0.0.1:27017
```

**Solutions:**

**Option 1: Start Local MongoDB**
```bash
# macOS with Homebrew
brew services start mongodb-community
brew services list  # Verify it's running

# Windows
# Start MongoDB service or run: mongod

# Linux
sudo systemctl start mongodb
sudo systemctl status mongodb
```

**Option 2: Use MongoDB Atlas (Cloud)**
```
1. Go to https://www.mongodb.com/cloud/atlas
2. Create free account
3. Create cluster
4. Get connection string: mongodb+srv://user:password@cluster.mongodb.net/dbname
5. Add to .env file:
   MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/govi_sahaya
6. Whitelist your IP in Atlas
```

**Option 3: Verify Connection String**
```bash
# Test connection
node -e "const mongoose = require('mongoose');
mongoose.connect(process.env.MONGODB_URI).then(() => {
  console.log('✅ Connected to MongoDB');
  process.exit(0);
}).catch(err => {
  console.error('❌ Connection failed:', err);
  process.exit(1);
});"
```

---

### Issue: "Port 5000 is already in use"

**Error Message:**
```
Error: listen EADDRINUSE: address already in use :::5000
```

**Solutions:**

1. **Find and kill the process using port 5000**
   ```bash
   # macOS/Linux
   lsof -i :5000
   kill -9 <PID>
   
   # Windows
   netstat -ano | findstr :5000
   taskkill /PID <PID> /F
   ```

2. **Use a different port**
   ```bash
   # Edit .env file
   PORT=5001
   # OR
   PORT=5002
   ```

3. **Restart the server**
   ```bash
   npm run dev
   ```

---

### Issue: ".env file not found" or variables undefined

**Error Messages:**
```
Cannot read properties of undefined (reading 'JWT_SECRET')
Error: MONGODB_URI is undefined
```

**Solutions:**

1. **Create .env file**
   ```bash
   cd govi_sahaya_backend
   touch .env
   ```

2. **Copy from template**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

3. **Verify .env has all required variables**
   ```env
   NODE_ENV=development
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/govi_sahaya
   JWT_SECRET=your-secret-key
   ```

4. **Restart server**
   ```bash
   npm run dev
   ```

---

### Issue: "Firebase authentication failed"

**Error Messages:**
```
Error: Firebase app initialization failed
Cannot read properties of undefined (reading 'initializeApp')
```

**Solutions:**

1. **Verify Firebase credentials in .env**
   ```env
   FIREBASE_PROJECT_ID=your-actual-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
   ```

2. **Get correct credentials**
   ```
   1. Go to Firebase Console
   2. Project Settings → Service Accounts
   3. Generate New Private Key
   4. Copy JSON content to .env (format properly)
   ```

3. **Handle multiline keys properly**
   ```bash
   # Use \n for newlines in .env
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhk...\n-----END PRIVATE KEY-----\n"
   ```

4. **Test Firebase initialization**
   ```bash
   npm test -- firebase.test.js
   ```

---

### Issue: "Tests failing" or "Jest cannot find test files"

**Error Messages:**
```
No tests found
FAIL  tests/unit/authController.test.js
```

**Solutions:**

1. **Verify jest.config.js exists**
   ```bash
   ls jest.config.js
   cat jest.config.js
   ```

2. **Check test file naming**
   ```bash
   # Should end with .test.js
   ls tests/unit/*.test.js
   ls tests/integration/*.test.js
   ```

3. **Run tests with verbose output**
   ```bash
   npm test -- --verbose
   npm test -- --listTests
   ```

4. **Clear Jest cache**
   ```bash
   npm test -- --clearCache
   ```

---

### Issue: "API endpoints returning 500 errors"

**Error Messages:**
```
{"success":false,"message":"Internal Server Error"}
```

**Solutions:**

1. **Check server logs**
   ```bash
   # Should show error message in console
   # Look for: [Error] or stack trace
   ```

2. **Enable debug logging**
   ```bash
   # Comment out console.log mocking in tests/setup.js temporarily
   # Or add NODE_DEBUG=* before starting
   NODE_DEBUG=* npm run dev
   ```

3. **Test endpoint with curl**
   ```bash
   curl http://localhost:5000/api/health
   curl -X POST http://localhost:5000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}'
   ```

4. **Check request/response**
   - Use Postman
   - Check browser DevTools Network tab
   - Verify request format

---

### Issue: "CORS errors" when frontend tries to access backend

**Error Messages:**
```
Access to XMLHttpRequest at 'http://localhost:5000' from origin 'http://localhost:8081' 
has been blocked by CORS policy
```

**Solutions:**

1. **Check CORS_ORIGIN in .env**
   ```env
   CORS_ORIGIN=http://localhost:3000,http://localhost:8081
   ```

2. **Verify all origins are included**
   ```bash
   # For Flutter on emulator
   CORS_ORIGIN=http://localhost:8081,http://10.0.2.2:5000
   
   # For multiple origins
   CORS_ORIGIN=http://localhost:8081,http://localhost:3000,http://192.168.x.x:5000
   ```

3. **Restart server after changing CORS**
   ```bash
   npm run dev
   ```

---

## 📱 Frontend (Flutter) Issues

### Issue: "flutter: command not found"

**Error Message:**
```
flutter: command not found
-bash: flutter: command not found
```

**Solutions:**

1. **Add Flutter to PATH**
   ```bash
   # Find Flutter installation
   which flutter
   # OR
   find ~ -name flutter -type f 2>/dev/null
   ```

2. **Add to PATH (temporary)**
   ```bash
   export PATH="$PATH:`pwd`/flutter/bin"
   flutter --version
   ```

3. **Add to PATH (permanent)**
   ```bash
   # Edit ~/.bashrc, ~/.zshrc, or ~/.bash_profile
   echo 'export PATH="$PATH:/Users/username/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. **Download Flutter if needed**
   ```bash
   # Go to https://flutter.dev/docs/get-started/install
   # Download appropriate version
   # Extract to ~/flutter
   # Add to PATH
   ```

---

### Issue: "Device not found" or "No emulators/devices detected"

**Error Messages:**
```
No connected devices
List of devices attached:
```

**Solutions:**

1. **List available devices**
   ```bash
   flutter devices
   ```

2. **Launch Android Emulator**
   ```bash
   # List available emulators
   flutter emulators
   
   # Launch emulator
   flutter emulators --launch Pixel_4_API_30
   
   # OR launch from Android Studio
   # Android Studio → Tools → Device Manager
   ```

3. **For physical Android device**
   ```bash
   # Enable USB debugging
   # Settings → Developer Options → USB Debugging
   
   # Connect via USB
   # Verify connection
   flutter devices
   
   # Run app
   flutter run
   ```

4. **For iOS (macOS only)**
   ```bash
   # List simulators
   xcrun simctl list devices
   
   # Launch simulator
   open -a Simulator
   
   # Run app
   flutter run -d iphone
   ```

---

### Issue: "Gradle build failed" or "Android build error"

**Error Messages:**
```
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:compileDebugJava'
```

**Solutions:**

1. **Clean and rebuild**
   ```bash
   cd govi_sahaya_mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check Java version**
   ```bash
   java -version  # Should be compatible with Gradle
   ```

3. **Update Gradle**
   ```bash
   # In android/build.gradle
   # Update gradle version to compatible version
   ```

4. **Check Android SDK**
   ```bash
   flutter doctor -v
   # Install missing components: flutter doctor --android-licenses
   ```

---

### Issue: "Firebase initialization failed on Flutter"

**Error Messages:**
```
PlatformException(ERROR_INVALID_API_KEY, ...)
```

**Solutions:**

1. **Verify google-services.json**
   ```bash
   # Android: android/app/google-services.json
   # Should be valid JSON
   cat android/app/google-services.json | python -m json.tool
   ```

2. **Verify GoogleService-Info.plist**
   ```bash
   # iOS: ios/Runner/GoogleService-Info.plist
   # Check file exists
   ls ios/Runner/GoogleService-Info.plist
   ```

3. **Add Firebase SHA-1 fingerprint to Firebase Console**
   ```bash
   # Get SHA-1 fingerprint
   cd android && ./gradlew signingReport | grep -i "sha1"
   # Go to Firebase Console → Project Settings → Your Android App
   # Add SHA-1 fingerprint
   ```

4. **Regenerate files from Firebase**
   ```bash
   # Delete old files
   # Re-download from Firebase Console
   # Place in correct directories
   # Rebuild app
   ```

---

### Issue: "Hot reload not working"

**Solutions:**

1. **Try hot restart instead**
   ```bash
   # In Flutter console
   R  # Hot reload
   # If not working:
   # Press Ctrl+C and restart
   flutter run
   ```

2. **Check for syntax errors**
   ```bash
   # Dart will compile on save
   # Fix any errors before trying hot reload
   ```

3. **Use full rebuild if needed**
   ```bash
   flutter pub get
   flutter run
   ```

---

### Issue: "iOS build failed" (macOS only)

**Error Messages:**
```
Xcode's output: ...
ld: library not found for -lstdc++.6.0.9
```

**Solutions:**

1. **Update pods**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```

2. **Clean and rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d iphone
   ```

3. **Check Xcode version**
   ```bash
   xcode-select --print-path
   xcode-select --install  # If needed
   ```

---

### Issue: "Pub get failed" or "Dependency resolution failed"

**Error Messages:**
```
Because govi_sahaya depends on firebase_core ^2.0.0 which requires Dart >=3.0.0
  and govi_sahaya.lock requires Dart 2.19.0...
```

**Solutions:**

1. **Update Flutter and Dart**
   ```bash
   flutter upgrade
   ```

2. **Clear pub cache**
   ```bash
   flutter pub cache clean
   flutter pub get
   ```

3. **Check Flutter version**
   ```bash
   flutter --version
   # Should be 3.0.0 or later
   ```

4. **Update pubspec.yaml if needed**
   ```yaml
   environment:
     sdk: '>=3.0.0 <4.0.0'
   ```

---

### Issue: "Widget tests failing"

**Error Messages:**
```
'package:flutter_test/flutter_test.dart' is not available
```

**Solutions:**

1. **Verify flutter_test dependency**
   ```bash
   grep flutter_test pubspec.yaml
   ```

2. **Update pubspec.yaml if missing**
   ```yaml
   dev_dependencies:
     flutter_test:
       sdk: flutter
   ```

3. **Get dependencies**
   ```bash
   flutter pub get
   flutter test
   ```

---

## 🌐 Network/API Issues

### Issue: "API returns 401 Unauthorized"

**Error Message:**
```
{"success":false,"message":"Unauthorized"}
Status Code: 401
```

**Solutions:**

1. **Verify JWT token is included**
   ```bash
   # Check Authorization header is present
   # Format: Authorization: Bearer <token>
   ```

2. **Check token validity**
   ```bash
   # Login first to get fresh token
   # Token might be expired
   ```

3. **Verify token format**
   ```bash
   # Should be valid JWT
   # Check on jwt.io
   ```

---

### Issue: "Network request times out"

**Error Messages:**
```
SocketException: Connection timed out
Timeout waiting for response
```

**Solutions:**

1. **Verify server is running**
   ```bash
   curl http://localhost:5000/api/health
   ```

2. **Check network connectivity**
   ```bash
   ping localhost
   ```

3. **Increase timeout duration**
   ```dart
   // In Dio configuration
   dio.options.connectTimeout = Duration(seconds: 30);
   dio.options.receiveTimeout = Duration(seconds: 30);
   ```

4. **Check firewall settings**
   - Ensure port 5000 is not blocked
   - Check antivirus software

---

### Issue: "SSL certificate errors"

**Error Messages:**
```
CERTIFICATE_VERIFY_FAILED
SSL: CERTIFICATE_VERIFY_FAILED
```

**Solutions:**

1. **For development only:**
   ```dart
   // Disable certificate verification (NOT for production!)
   dio.httpClientAdapter = HttpClientAdapter()
     ..onHttpClientCreate = (client) {
       client.badCertificateCallback =
           (_HttpClientRequest request, String host, int port) => true;
       return client;
     };
   ```

2. **For production:**
   - Use valid SSL certificate
   - Add certificate to system trust store

---

## 🔍 Database Issues

### Issue: "Database connection pooling issues"

**Solutions:**

1. **Check connection string**
   ```bash
   # Should be valid MongoDB URI
   echo $MONGODB_URI
   ```

2. **Restart MongoDB**
   ```bash
   # macOS
   brew services restart mongodb-community
   
   # Windows
   # Restart MongoDB service
   
   # Linux
   sudo systemctl restart mongodb
   ```

3. **Check connection limits**
   ```bash
   # MongoDB default max connections: 100
   # Increase if needed in Atlas settings
   ```

---

### Issue: "Database is locked" (SQLite - Flutter local storage)

**Solutions:**

```dart
// Android/iOS local database issues
// Update sqflite dependency
flutter pub upgrade sqflite

// Clear local database if corrupted
final dbPath = await getDatabasesPath();
await deleteDatabase(join(dbPath, 'govi_sahaya.db'));
```

---

## 🧪 Testing Issues

### Issue: "Tests not running" or "Test framework not found"

**Backend:**
```bash
npm test -- --listTests      # List all tests
npm test -- --testNamePattern="auth"  # Run specific test
npm test -- --coverage       # Generate coverage
```

**Frontend:**
```bash
flutter test                 # List all tests
flutter test --name "login"  # Run specific test
flutter test --coverage      # Generate coverage
```

---

### Issue: "Mock not working in tests"

**Backend:**
```javascript
// Ensure mock is defined before import
jest.mock('../../src/models/User');
const User = require('../../src/models/User');
```

**Frontend:**
```dart
// Use mockito or write custom mocks
class MockWeatherService extends Mock implements WeatherService {}
```

---

## 📊 Performance Issues

### Issue: "App running slowly" or "High memory usage"

**Solutions:**

1. **Profile the app**
   ```bash
   # Flutter DevTools
   flutter pub global run devtools
   ```

2. **Check for memory leaks**
   - Monitor heap size
   - Check for unreleased resources

3. **Optimize database queries**
   - Add indexes
   - Limit result sets
   - Use pagination

---

### Issue: "API responses slow"

**Solutions:**

1. **Add caching**
   ```bash
   # Backend: implement Redis caching
   # Frontend: cache responses locally
   ```

2. **Optimize database queries**
   ```bash
   # Add indexes
   # Remove N+1 queries
   ```

3. **Monitor server performance**
   ```bash
   # Check CPU/memory usage
   # Monitor number of connections
   ```

---

## 🆘 Getting Additional Help

If issue not resolved:

1. **Check Documentation**
   - [README.md](./README.md)
   - [QUICKSTART.md](./QUICKSTART.md)
   - [TESTING.md](./TESTING.md)

2. **Search GitHub Issues**
   - https://github.com/govi-sahaya/govi-sahaya/issues
   - Use specific keywords

3. **Ask Community**
   - GitHub Discussions
   - Stack Overflow (tag: govi-sahaya)
   - Reddit: r/GoviSahaya

4. **Contact Support**
   - Email: support@govisahaya.lk
   - Twitter: @GoviSahaya

---

<div align="center">

**Can't find your issue?** [Create a GitHub issue](https://github.com/govi-sahaya/govi-sahaya/issues/new)

Include:
- Error message
- Steps to reproduce
- Environment details
- Screenshots/logs

</div>
