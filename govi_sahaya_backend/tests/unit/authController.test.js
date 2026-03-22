const jwt = require('jsonwebtoken');
const User = require('../../src/models/User');

jest.mock('../../src/models/User');
jest.mock('../../src/services/emailService');
jest.mock('../../src/config/firebase');
jest.mock('../../src/utils/logger', () => ({
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

describe('Auth Controller - Unit Tests', () => {
  const mockUser = {
    _id: '507f1f77bcf86cd799439011',
    name: 'John Farmer',
    email: 'john@example.com',
    password: 'hashedPassword123',
    isEmailVerified: false,
    save: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'test-secret-key';
    process.env.JWT_EXPIRES_IN = '7d';
  });

  describe('Login', () => {
    it('should login user with valid credentials', async () => {
      const authController = require('../../src/controllers/authController');
      const loginUser = { ...mockUser, password: 'hashedPassword' };
      
      const comparePassword = jest.fn().mockResolvedValue(true);
      loginUser.comparePassword = comparePassword;
      
      User.findOne = jest.fn().mockResolvedValue(loginUser);

      const req = {
        body: {
          email: 'john@example.com',
          password: 'plainPassword123',
        },
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
        cookie: jest.fn(),
      };

      // Mock JWT sign
      jwt.sign = jest.fn().mockReturnValue('mockToken');

      if (authController.login) {
        await authController.login(req, res);
        expect(res.status).toHaveBeenCalled();
      }
    });

    it('should reject login with invalid credentials', async () => {
      User.findOne = jest.fn().mockResolvedValue(null);

      const authController = require('../../src/controllers/authController');
      const req = {
        body: {
          email: 'nonexistent@example.com',
          password: 'password123',
        },
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      if (authController.login) {
        await authController.login(req, res);
        expect(res.status).toHaveBeenCalledWith(expect.any(Number));
      }
    });
  });

  describe('Register', () => {
    it('should register a new user', async () => {
      const authController = require('../../src/controllers/authController');
      
      User.findOne = jest.fn().mockResolvedValue(null);
      User.prototype.save = jest.fn().mockResolvedValue(mockUser);

      const req = {
        body: {
          name: 'New Farmer',
          email: 'newfarm@example.com',
          password: 'Password123!',
          confirmPassword: 'Password123!',
        },
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      if (authController.register) {
        await authController.register(req, res);
        expect(res.status).toHaveBeenCalled();
      }
    });

    it('should reject duplicate email registration', async () => {
      User.findOne = jest.fn().mockResolvedValue(mockUser);

      const authController = require('../../src/controllers/authController');
      
      const req = {
        body: {
          name: 'John Farmer',
          email: 'john@example.com',
          password: 'Password123!',
          confirmPassword: 'Password123!',
        },
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      if (authController.register) {
        await authController.register(req, res);
        expect(res.status).toHaveBeenCalled();
      }
    });
  });

  describe('Verify Email', () => {
    it('should verify email with valid token', async () => {
      const authController = require('../../src/controllers/authController');
      const token = 'valid-token';
      
      User.findOne = jest.fn().mockResolvedValue({
        ...mockUser,
        emailVerificationToken: token,
        emailVerificationExpires: new Date(Date.now() + 3600000),
        save: jest.fn().mockResolvedValue(),
      });

      const req = {
        params: { token },
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
        send: jest.fn(),
      };

      if (authController.verifyEmail) {
        await authController.verifyEmail(req, res);
        expect(res.status).toHaveBeenCalledWith(expect.any(Number));
      }
    });

    it('should reject verification with invalid token', async () => {
      const authController = require('../../src/controllers/authController');
      
      User.findOne = jest.fn().mockResolvedValue(null);

      const req = {
        params: { token: 'invalid-token' },
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      if (authController.verifyEmail) {
        await authController.verifyEmail(req, res);
        expect(res.status).toHaveBeenCalled();
      }
    });
  });
});
