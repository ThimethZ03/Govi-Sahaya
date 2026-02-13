const crypto = require('crypto');

// Generate random string
exports.generateRandomString = (length = 10) => {
  return crypto.randomBytes(length).toString('hex').substring(0, length);
};

// Generate random number
exports.generateRandomNumber = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Generate UUID
exports.generateUUID = () => {
  return crypto.randomUUID();
};

// Capitalize first letter
exports.capitalizeFirstLetter = (str) => {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
};

// Capitalize words
exports.capitalizeWords = (str) => {
  if (!str) return '';
  return str
    .split(' ')
    .map((word) => exports.capitalizeFirstLetter(word))
    .join(' ');
};

// Convert to slug
exports.toSlug = (str) => {
  return str
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/--+/g, '-')
    .trim();
};

// Truncate string
exports.truncateString = (str, maxLength, suffix = '...') => {
  if (!str || str.length <= maxLength) return str;
  return str.substring(0, maxLength - suffix.length) + suffix;
};

// Remove duplicates from array
exports.removeDuplicates = (arr) => {
  return [...new Set(arr)];
};

// Shuffle array
exports.shuffleArray = (arr) => {
  const shuffled = [...arr];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
};

// Chunk array
exports.chunkArray = (arr, size) => {
  const chunks = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
};

// Deep clone object
exports.deepClone = (obj) => {
  return JSON.parse(JSON.stringify(obj));
};

// Merge objects
exports.mergeObjects = (...objects) => {
  return Object.assign({}, ...objects);
};

// Pick keys from object
exports.pickKeys = (obj, keys) => {
  const result = {};
  keys.forEach((key) => {
    if (obj.hasOwnProperty(key)) {
      result[key] = obj[key];
    }
  });
  return result;
};

// Omit keys from object
exports.omitKeys = (obj, keys) => {
  const result = { ...obj };
  keys.forEach((key) => {
    delete result[key];
  });
  return result;
};

// Calculate percentage
exports.calculatePercentage = (value, total) => {
  if (total === 0) return 0;
  return ((value / total) * 100).toFixed(2);
};

// Calculate percentage change
exports.calculatePercentageChange = (oldValue, newValue) => {
  if (oldValue === 0) return 0;
  return (((newValue - oldValue) / oldValue) * 100).toFixed(2);
};

// Format currency (LKR)
exports.formatCurrency = (amount, currency = 'LKR') => {
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: currency,
  }).format(amount);
};

// Format number with commas
exports.formatNumber = (num) => {
  return new Intl.NumberFormat('en-US').format(num);
};

// Parse query string
exports.parseQueryString = (queryString) => {
  const params = new URLSearchParams(queryString);
  const result = {};
  for (const [key, value] of params) {
    result[key] = value;
  }
  return result;
};

// Build query string
exports.buildQueryString = (params) => {
  return new URLSearchParams(params).toString();
};

// Sleep/delay function
exports.sleep = (ms) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

// Retry function
exports.retry = async (fn, maxAttempts = 3, delay = 1000) => {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxAttempts) throw error;
      await exports.sleep(delay);
    }
  }
};

// Debounce function
exports.debounce = (func, wait) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};

// Throttle function
exports.throttle = (func, limit) => {
  let inThrottle;
  return function (...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
};

// Get file extension
exports.getFileExtension = (filename) => {
  return filename.split('.').pop().toLowerCase();
};

// Get file name without extension
exports.getFileNameWithoutExtension = (filename) => {
  return filename.substring(0, filename.lastIndexOf('.')) || filename;
};

// Convert bytes to human readable format
exports.formatBytes = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
};

// Calculate distance between two coordinates (Haversine formula)
exports.calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Radius of Earth in kilometers
  const dLat = exports.toRadians(lat2 - lat1);
  const dLon = exports.toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(exports.toRadians(lat1)) *
      Math.cos(exports.toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return distance.toFixed(2); // in kilometers
};

// Convert degrees to radians
exports.toRadians = (degrees) => {
  return (degrees * Math.PI) / 180;
};

// Convert radians to degrees
exports.toDegrees = (radians) => {
  return (radians * 180) / Math.PI;
};

// Check if string is JSON
exports.isJSON = (str) => {
  try {
    JSON.parse(str);
    return true;
  } catch (e) {
    return false;
  }
};

// Generate pagination metadata
exports.getPaginationMeta = (page, limit, total) => {
  const totalPages = Math.ceil(total / limit);
  const hasNextPage = page < totalPages;
  const hasPrevPage = page > 1;

  return {
    currentPage: page,
    totalPages,
    totalItems: total,
    itemsPerPage: limit,
    hasNextPage,
    hasPrevPage,
    nextPage: hasNextPage ? page + 1 : null,
    prevPage: hasPrevPage ? page - 1 : null,
  };
};

// Extract numbers from string
exports.extractNumbers = (str) => {
  const numbers = str.match(/\d+/g);
  return numbers ? numbers.map(Number) : [];
};

// Remove special characters
exports.removeSpecialCharacters = (str) => {
  return str.replace(/[^a-zA-Z0-9 ]/g, '');
};

// Check if object is empty
exports.isEmptyObject = (obj) => {
  return Object.keys(obj).length === 0;
};

// Get random item from array
exports.getRandomItem = (arr) => {
  return arr[Math.floor(Math.random() * arr.length)];
};

// Sort array of objects by key
exports.sortByKey = (arr, key, order = 'asc') => {
  return arr.sort((a, b) => {
    if (order === 'asc') {
      return a[key] > b[key] ? 1 : -1;
    } else {
      return a[key] < b[key] ? 1 : -1;
    }
  });
};

// Group array of objects by key
exports.groupBy = (arr, key) => {
  return arr.reduce((result, item) => {
    const group = item[key];
    if (!result[group]) {
      result[group] = [];
    }
    result[group].push(item);
    return result;
  }, {});
};

// Calculate average
exports.calculateAverage = (numbers) => {
  if (numbers.length === 0) return 0;
  const sum = numbers.reduce((acc, num) => acc + num, 0);
  return sum / numbers.length;
};

// Find min and max in array
exports.findMinMax = (numbers) => {
  return {
    min: Math.min(...numbers),
    max: Math.max(...numbers),
  };
};

// Mask email
exports.maskEmail = (email) => {
  const [username, domain] = email.split('@');
  const maskedUsername =
    username.substring(0, 2) + '*'.repeat(username.length - 2);
  return `${maskedUsername}@${domain}`;
};

// Mask phone number
exports.maskPhone = (phone) => {
  const visibleDigits = 4;
  const masked = '*'.repeat(phone.length - visibleDigits);
  return masked + phone.slice(-visibleDigits);
};

// Generate OTP
exports.generateOTP = (length = 6) => {
  const digits = '0123456789';
  let otp = '';
  for (let i = 0; i < length; i++) {
    otp += digits[Math.floor(Math.random() * digits.length)];
  }
  return otp;
};

// Hash string (SHA-256)
exports.hashString = (str) => {
  return crypto.createHash('sha256').update(str).digest('hex');
};

// Encrypt string
exports.encryptString = (text, key) => {
  const cipher = crypto.createCipher('aes-256-cbc', key);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
};

// Decrypt string
exports.decryptString = (encrypted, key) => {
  const decipher = crypto.createDecipher('aes-256-cbc', key);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
};
