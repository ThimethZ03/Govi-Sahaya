const request = require('supertest');
const mongoose = require('mongoose');
const User = require('../../src/models/User');

// Mock the middleware
jest.mock('../../src/middleware/auth', () => ({
  protect: (req, res, next) => {
    req.user = { id: '507f1f77bcf86cd799439011' };
    next();
  },
}));

jest.mock('../../src/middleware/uploadMiddleware', () => ({
  deleteImage: jest.fn(),
}));

jest.mock('../../src/utils/logger', () => ({
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

describe('User Controller - Unit Tests', () => {
  const mockUser = {
    _id: '507f1f77bcf86cd799439011',
    name: 'John Farmer',
    email: 'john@example.com',
    phone: '0771234567',
    location: {
      district: 'Colombo',
      province: 'Western',
    },
    farmDetails: {
      farmSize: 10,
      farmSizeUnit: 'acres',
      mainCrops: ['rice', 'corn'],
    },
  };

  beforeAll(async () => {
    // Mock db if needed
  });

  afterAll(async () => {
    // Cleanup if needed
  });

  describe('getProfile', () => {
    it('should fetch user profile successfully', async () => {
      User.findById = jest.fn().mockResolvedValue(mockUser);

      const userController = require('../../src/controllers/userController');
      const req = {
        user: { id: mockUser._id },
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await userController.getProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: mockUser,
      });
    });

    it('should return 404 if user not found', async () => {
      User.findById = jest.fn().mockResolvedValue(null);

      const userController = require('../../src/controllers/userController');
      const req = {
        user: { id: '507f1f77bcf86cd799439011' },
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await userController.getProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'User not found',
      });
    });

    it('should handle database errors', async () => {
      const error = new Error('Database connection failed');
      User.findById = jest.fn().mockRejectedValue(error);

      const userController = require('../../src/controllers/userController');
      const req = {
        user: { id: '507f1f77bcf86cd799439011' },
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await userController.getProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Failed to fetch profile',
      });
    });
  });

  describe('updateProfile', () => {
    it('should update user profile successfully', async () => {
      const updateData = {
        name: 'Updated Name',
        phone: '0779999999',
        location: {
          district: 'Galle',
          province: 'Southern',
        },
      };

      const savedUser = { ...mockUser, ...updateData };
      const userWithSave = { ...mockUser, save: jest.fn().mockResolvedValue() };

      User.findById = jest.fn()
        .mockResolvedValueOnce(userWithSave)
        .mockResolvedValueOnce(savedUser);

      const userController = require('../../src/controllers/userController');
      const req = {
        user: { id: mockUser._id },
        body: updateData,
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await userController.updateProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Profile updated successfully',
        })
      );
    });

    it('should handle missing user', async () => {
      User.findById = jest.fn().mockResolvedValue(null);

      const userController = require('../../src/controllers/userController');
      const req = {
        user: { id: '507f1f77bcf86cd799439011' },
        body: { name: 'Test' },
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await userController.updateProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
    });
  });
});
