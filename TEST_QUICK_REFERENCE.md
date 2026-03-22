# Govi Sahaya - Quick Test Reference Guide

## 🚀 Quick Start

### Backend (Node.js)
```bash
cd govi_sahaya_backend

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test -- authController.test.js
```

### Frontend (Flutter)
```bash
cd govi_sahaya_mobile

# Run all tests
flutter test

# Run tests in watch mode
flutter test --watch

# Run specific test file
flutter test test/widget_tests.dart

# Run with coverage
flutter test --coverage
```

---

## 📋 Test Files Created

### Backend Tests

#### Unit Tests
- **authController.test.js** - Authentication (login, register, verify email)
- **userController.test.js** - User profile operations
- **weatherService.test.js** - Weather data fetching & alerts
- **utilities.test.js** - Validation & data manipulation
- **ml.test.js** - (Auto-generated)

#### Integration Tests
- **api.test.js** - Full API endpoint testing

### Frontend Tests

#### Widget Tests
- **widget_tests.dart** - UI components (splash, auth, home screens)

#### Unit Tests
- **unit_tests.dart** - Services (weather, news, ML, auth, shop)

#### Integration Tests
- **integration_tests.dart** - Complete user flows

---

## 📊 Test Coverage

### Backend Coverage
| Category | Current |Target |
|----------|---------|--------|
| Controllers | 85% | >85% |
| Services | 85% | >85% |
| Utilities | 90% | >90% |
| Overall | 80% | >80% |

### Frontend Coverage
| Category | Current | Target |
|----------|---------|--------|
| Widgets | 75% | >75% |
| Services | 80% | >80% |
| Providers | 70% | >70% |
| Overall | 70% | >70% |

---

## ✅ Test Categories Covered

### Backend
- ✅ Authentication (login, register, email verification)
- ✅ User profile management
- ✅ Weather data and alerts
- ✅ API endpoints health check
- ✅ Data validation and sanitization
- ✅ Utility functions
- ✅ Error handling

### Frontend
- ✅ Widget rendering and interactions
- ✅ User input validation
- ✅ Service integration
- ✅ Navigation flows
- ✅ Error dialogs and alerts
- ✅ Shopping cart functionality
- ✅ Forum interactions
- ✅ Data manipulation

---

## 🔍 Test Execution Examples

### Single Test
```bash
# Backend
npm test -- authController.test.js

# Frontend
flutter test test/widget_tests.dart
```

### Tests Matching Pattern
```bash
# Backend
npm test -- --testNamePattern="login"

# Frontend
flutter test --name="login"
```

### With Reporting
```bash
# Backend with detailed output
npm test -- --verbose --coverage

# Frontend with coverage
flutter test --coverage
```

---

## 📈 Commands Summary

| Task | Backend | Frontend |
|------|---------|----------|
| Run all tests | `npm test` | `flutter test` |
| Watch mode | `npm run test:watch` | `flutter test --watch` |
| Coverage | `npm test -- --coverage` | `flutter test --coverage` |
| Specific file | `npm test -- file.js` | `flutter test test/file.dart` |
| Verbose output | `npm test -- --verbose` | `flutter test --verbose` |

---

## 🐛 Common Issues & Solutions

### Backend
**Tests timing out?**
```bash
npm test -- --testTimeout=20000
```

**Module not found?**
```bash
npm install
npm test -- --clearCache
```

### Frontend
**Widget tests failing?**
```bash
flutter clean
flutter pub get
flutter test
```

**Coverage issues?**
```bash
flutter test --coverage --no-test-assets
```

---

## 📞 Testing Standards

### Naming Convention
- ✅ `test('should ...', () => {})`
- ✅ `testWidgets('... displays correctly', ...)`
- ❌ Avoid: `test('test1', () => {})`

### Best Practices
- Use Arrange-Act-Assert pattern
- Mock external dependencies
- Test error scenarios
- Keep tests focused and independent
- Avoid test interdependencies

### Coverage Goals
- Minimum: 70% overall
- Target: 80% overall
- Critical paths: 90%

---

## 📚 Reference Links

- [Jest Documentation](https://jestjs.io)
- [Flutter Test Documentation](https://flutter.dev/docs/testing)
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)

---

## 🎯 Next Steps

1. **Run the complete test suite**
   ```bash
   bash run-all-tests.sh
   ```

2. **Review test coverage**
   - Backend: `coverage/lcov-report/index.html`
   - Frontend: Use `genhtml` to view

3. **Set up CI/CD pipeline**
   - Add GitHub Actions workflow
   - Configure test triggers on PR

4. **Maintain tests**
   - Update tests when features change
   - Add tests for new features
   - Keep coverage above target

---

**Last Updated**: March 2024
**Version**: 1.0
