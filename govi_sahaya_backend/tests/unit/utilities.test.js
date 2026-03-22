const mongoose = require('mongoose');

jest.mock('../../src/utils/logger', () => ({
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

describe('Utility Functions - Unit Tests', () => {
  describe('Validation Utilities', () => {
    it('should validate email format correctly', () => {
      const validateEmail = (email) => {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
      };

      expect(validateEmail('user@example.com')).toBe(true);
      expect(validateEmail('invalid-email')).toBe(false);
      expect(validateEmail('user@domain')).toBe(false);
      expect(validateEmail('')).toBe(false);
    });

    it('should validate phone number format', () => {
      const validatePhone = (phone) => {
        const phoneRegex = /^[0-9]{10}$/;
        return phoneRegex.test(phone.replace(/\D/g, ''));
      };

      expect(validatePhone('0771234567')).toBe(true);
      expect(validatePhone('071-123-4567')).toBe(true);
      expect(validatePhone('123')).toBe(false);
    });

    it('should validate password strength', () => {
      const validatePassword = (password) => {
        // Min 8 chars, at least one uppercase, one lowercase, one number, one special char
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
        return passwordRegex.test(password);
      };

      expect(validatePassword('ValidPass123!')).toBe(true);
      expect(validatePassword('weakpass')).toBe(false);
      expect(validatePassword('NoNumbers!')).toBe(false);
      expect(validatePassword('noupppercase1!')).toBe(false);
    });
  });

  describe('Data Sanitization', () => {
    it('should sanitize user input', () => {
      const sanitizeInput = (input) => {
        if (typeof input !== 'string') return input;
        return input
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .trim();
      };

      expect(sanitizeInput('<script>alert("xss")</script>')).toBe('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
      expect(sanitizeInput('  normal text  ')).toBe('normal text');
    });

    it('should remove sensitive data from objects', () => {
      const removeSensitiveData = (obj) => {
        const clone = { ...obj };
        delete clone.password;
        delete clone.token;
        delete clone.refreshToken;
        return clone;
      };

      const userObj = {
        id: '123',
        name: 'John',
        password: 'secret123',
        token: 'jwt-token',
      };

      const sanitized = removeSensitiveData(userObj);
      expect(sanitized.password).toBeUndefined();
      expect(sanitized.token).toBeUndefined();
      expect(sanitized.name).toBe('John');
    });
  });

  describe('Date Utilities', () => {
    it('should format date correctly', () => {
      const formatDate = (date) => {
        return new Date(date).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
          day: 'numeric',
        });
      };

      const testDate = new Date('2024-03-20');
      const formatted = formatDate(testDate);
      expect(formatted).toContain('2024');
      expect(formatted).toContain('Mar');
      expect(formatted).toContain('20');
    });

    it('should calculate days between dates', () => {
      const daysBetween = (date1, date2) => {
        const d1 = new Date(date1);
        const d2 = new Date(date2);
        const diffTime = Math.abs(d2 - d1);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
      };

      const date1 = new Date('2024-03-20');
      const date2 = new Date('2024-03-27');
      expect(daysBetween(date1, date2)).toBe(7);
    });

    it('should check if date is in past', () => {
      const isPastDate = (date) => {
        return new Date(date) < new Date();
      };

      expect(isPastDate(new Date(Date.now() - 86400000))).toBe(true);
      expect(isPastDate(new Date(Date.now() + 86400000))).toBe(false);
    });
  });

  describe('Array Utilities', () => {
    it('should remove duplicates from array', () => {
      const removeDuplicates = (arr) => {
        return [...new Set(arr)];
      };

      expect(removeDuplicates([1, 2, 2, 3, 3, 3])).toEqual([1, 2, 3]);
      expect(removeDuplicates(['a', 'b', 'a'])).toEqual(['a', 'b']);
    });

    it('should filter array by condition', () => {
      const users = [
        { id: 1, active: true },
        { id: 2, active: false },
        { id: 3, active: true },
      ];

      const activeUsers = users.filter(u => u.active);
      expect(activeUsers).toHaveLength(2);
      expect(activeUsers[0].id).toBe(1);
    });

    it('should chunk array into smaller arrays', () => {
      const chunkArray = (arr, size) => {
        return Array.from({ length: Math.ceil(arr.length / size) }, (_, i) =>
          arr.slice(i * size, i * size + size)
        );
      };

      const result = chunkArray([1, 2, 3, 4, 5, 6, 7], 3);
      expect(result).toEqual([[1, 2, 3], [4, 5, 6], [7]]);
    });
  });

  describe('Math Utilities', () => {
    it('should calculate percentage', () => {
      const calculatePercentage = (value, total) => {
        return (value / total) * 100;
      };

      expect(calculatePercentage(25, 100)).toBe(25);
      expect(calculatePercentage(1, 3)).toBeCloseTo(33.33, 1);
    });

    it('should round numbers correctly', () => {
      const roundToDecimal = (num, decimals) => {
        return Math.round(num * Math.pow(10, decimals)) / Math.pow(10, decimals);
      };

      expect(roundToDecimal(3.14159, 2)).toBe(3.14);
      expect(roundToDecimal(10.555, 1)).toBe(10.6);
    });
  });

  describe('MongoDB Utilities', () => {
    it('should validate MongoDB ObjectId', () => {
      const isValidObjectId = (id) => {
        return mongoose.Types.ObjectId.isValid(id);
      };

      expect(isValidObjectId('507f1f77bcf86cd799439011')).toBe(true);
      expect(isValidObjectId('invalid-id')).toBe(false);
    });

    it('should generate new ObjectId', () => {
      const generateObjectId = () => {
        return new mongoose.Types.ObjectId();
      };

      const id = generateObjectId();
      expect(id).toBeDefined();
      expect(id.toString()).toMatch(/^[a-f0-9]{24}$/);
    });
  });
});
