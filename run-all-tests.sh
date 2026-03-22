#!/bin/bash

# Govi Sahaya - Complete Test Suite Runner
# This script runs all tests for both backend and frontend

echo "🧪 Govi Sahaya - Complete Test Suite"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backend Tests
echo -e "${YELLOW}📦 Running Backend Tests...${NC}"
cd govi_sahaya_backend

if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

echo "Running backend unit tests..."
npm test -- tests/unit --verbose

echo ""
echo "Running backend integration tests..."
npm test -- tests/integration --verbose

echo ""
echo "Generating coverage report..."
npm test -- --coverage

echo -e "${GREEN}✅ Backend tests completed!${NC}"
echo ""

# Frontend Tests
cd ../govi_sahaya_mobile

echo -e "${YELLOW}📱 Running Frontend Tests...${NC}"

if [ ! -d "pubspec.lock" ]; then
    echo "Getting Flutter dependencies..."
    flutter pub get
fi

echo "Running widget tests..."
flutter test test/widget_tests.dart

echo ""
echo "Running unit tests..."
flutter test test/unit_tests.dart

echo ""
echo "Running integration tests..."
flutter test test/integration_tests.dart

echo ""
echo "Generating coverage report..."
flutter test --coverage

echo -e "${GREEN}✅ Frontend tests completed!${NC}"
echo ""

# Summary
echo ""
echo -e "${GREEN}🎉 All Tests Completed!${NC}"
echo "===================================="
echo ""
echo "📊 Coverage Reports:"
echo "   Backend: coverage/lcov-report/index.html"
echo "   Frontend: coverage/lcov.info (use genhtml to view)"
echo ""
echo "📈 Next Steps:"
echo "   1. Review coverage reports"
echo "   2. Fix any failing tests"
echo "   3. Merge to main branch"
echo ""
