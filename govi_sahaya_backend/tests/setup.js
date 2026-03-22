// Setup file for Jest tests
process.env.NODE_ENV = 'test';
process.env.MONGODB_URI = 'mongodb://localhost:27017/govi_sahaya_test';
process.env.JWT_SECRET = 'test-secret-key-for-testing-only';
process.env.JWT_EXPIRE = '7d';
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.FIREBASE_PRIVATE_KEY = 'test-key';
process.env.FIREBASE_CLIENT_EMAIL = 'test@test.com';
process.env.CORS_ORIGIN = 'http://localhost:3000,http://localhost:8081';

// Global timeout
jest.setTimeout(10000);

// Mock console methods to reduce noise in tests
global.console.log = jest.fn();
global.console.warn = jest.fn();
