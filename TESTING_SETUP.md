# Testing Setup - Installation Guide

## Prerequisites

### Backend Requirements
- Node.js >= 18.0.0
- npm >= 9.0.0
- MongoDB (optional for local testing)

### Frontend Requirements
- Flutter SDK >= 3.0.0
- Dart SDK (included with Flutter)
- Supported platforms: Android, iOS, Web, Windows, macOS, Linux

---

## Backend Setup

### 1. Install Dependencies
```bash
cd govi_sahaya_backend
npm install
```

### 2. Verify Jest is Installed
```bash
npm list jest
# Should show: jest@^29.7.0
```

### 3. Verify Test Scripts
```bash
npm run
# Should show:
# test - jest --coverage
# test:watch - jest --watch
```

### 4. Run Basic Test
```bash
npm test 2>&1 | head -50
```

---

## Frontend Setup

### 1. Get Flutter Packages
```bash
cd govi_sahaya_mobile
flutter pub get
```

### 2. Verify Flutter is Configured
```bash
flutter doctor
# Should show green ✓ for platforms you want to test
```

### 3. Check Test Packages
```bash
flutter pub list # Look for flutter_test
```

### 4. Run Basic Test
```bash
flutter test --version
flutter test test/widget_tests.dart --dry-run
```

---

## Test Configuration Files

### Backend Configuration
**File**: `jest.config.js`
- Test environment: node
- Coverage directory: coverage/
- Test timeout: 10 seconds
- Setup file: tests/setup.js

**File**: `tests/setup.js`
- Sets NODE_ENV=test
- Configures test environment variables
- Mocks console methods

### Frontend Configuration
No special configuration file needed - uses Flutter defaults.

---

## Troubleshooting Installation

### Backend Issues

#### "Cannot find module 'jest'"
```bash
npm install
npm install --save-dev jest
```

#### "Tests not found"
```bash
npm test -- --listTests
```

#### "Port already in use"
Change the test database port in `tests/setup.js`

### Frontend Issues

#### "pub get failed"
```bash
flutter pub cache clean
flutter pub get
```

#### "Flutter command not found"
Add Flutter to PATH:
```bash
export PATH="$PATH:`flutter/bin`"
```

#### "dart:ffi' not found"
```bash
flutter clean
flutter pub get
```

---

## CI/CD Environment Setup

### GitHub Actions - Backend
```yaml
- name: Install dependencies
  run: cd govi_sahaya_backend && npm ci

- name: Run tests
  run: cd govi_sahaya_backend && npm test
```

### GitHub Actions - Frontend
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.0.0'

- name: Get dependencies
  run: cd govi_sahaya_mobile && flutter pub get

- name: Run tests
  run: cd govi_sahaya_mobile && flutter test
```

---

## Docker Setup (Optional)

### Backend Testing in Docker
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY govi_sahaya_backend/ .
RUN npm ci
RUN npm test -- --coverage
```

### Frontend Testing in Docker
```dockerfile
FROM cirrusci/flutter:latest

WORKDIR /app
COPY govi_sahaya_mobile/ .
RUN flutter pub get
RUN flutter test --coverage
```

---

## Performance Tuning

### Backend
```bash
# Run tests in parallel
npm test -- --maxWorkers=4

# Run tests sequentially
npm test -- --maxWorkers=1

# Run with less memory
npm test -- --forceExit
```

### Frontend
```bash
# Run tests without coverage (faster)
flutter test

# Run single test file first
flutter test test/widget_tests.dart
```

---

## Continuous Integration Setup

### Enable Code Coverage
**Backend**:
```bash
npm test -- --coverage --collectCoverageFrom="src/**/*.js"
```

**Frontend**:
```bash
flutter test --coverage
```

### Coverage Thresholds
Create `.nycrc.json` for backend:
```json
{
  "watermarks": {
    "lines": [70, 90],
    "functions": [70, 90],
    "branches": [70, 90],
    "statements": [70, 90]
  }
}
```

---

## Additional Resources

### Testing Documentation
- [Jest Docs](https://jestjs.io/docs/getting-started)
- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Dart Testing](https://dart.dev/guides/testing)

### Package Documentation
- [Supertest (API Testing)](https://github.com/visionmedia/supertest)
- [Mockito](https://pub.dev/packages/mockito)

---

## Verification Checklist

- [ ] Backend: `npm test` runs without errors
- [ ] Frontend: `flutter test` runs without errors
- [ ] Both test suites complete in < 2 minutes
- [ ] Coverage reports are generated
- [ ] All mock files are in place
- [ ] Environment variables are configured
- [ ] Test database is configured (if needed)

---

## Support

For setup issues:
1. Check Node.js/Flutter versions
2. Clear caches: `npm cache clean --force` or `flutter pub cache clean`
3. Reinstall dependencies
4. Check the troubleshooting section above

---

**Last Updated**: March 2024
**Maintained by**: Govi Sahaya Team
