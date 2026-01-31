const { REGEX } = require('../config/constants');

// Validate email
exports.isValidEmail = (email) => {
  return REGEX.EMAIL.test(email);
};

// Validate phone number (Sri Lankan)
exports.isValidPhone = (phone) => {
  return REGEX.PHONE_LK.test(phone);
};

// Validate password strength
exports.isValidPassword = (password) => {
  return REGEX.PASSWORD.test(password);
};

// Validate URL
exports.isValidURL = (url) => {
  return REGEX.URL.test(url);
};

// Validate MongoDB ObjectId
exports.isValidObjectId = (id) => {
  const objectIdPattern = /^[0-9a-fA-F]{24}$/;
  return objectIdPattern.test(id);
};

// Validate date
exports.isValidDate = (date) => {
  const dateObj = new Date(date);
  return dateObj instanceof Date && !isNaN(dateObj);
};

// Validate date range
exports.isValidDateRange = (startDate, endDate) => {
  const start = new Date(startDate);
  const end = new Date(endDate);
  return start <= end;
};

// Validate number range
exports.isInRange = (value, min, max) => {
  const num = Number(value);
  return !isNaN(num) && num >= min && num <= max;
};

// Validate required fields
exports.hasRequiredFields = (obj, requiredFields) => {
  const missingFields = [];
  
  for (const field of requiredFields) {
    if (obj[field] === undefined || obj[field] === null || obj[field] === '') {
      missingFields.push(field);
    }
  }
  
  return {
    isValid: missingFields.length === 0,
    missingFields,
  };
};

// Validate file type
exports.isValidFileType = (filename, allowedTypes) => {
  const ext = filename.split('.').pop().toLowerCase();
  return allowedTypes.includes(ext);
};

// Validate file size
exports.isValidFileSize = (size, maxSize) => {
  return size <= maxSize;
};

// Validate image dimensions
exports.isValidImageDimensions = (width, height, minWidth, minHeight, maxWidth, maxHeight) => {
  return (
    width >= minWidth &&
    height >= minHeight &&
    width <= maxWidth &&
    height <= maxHeight
  );
};

// Validate coordinates
exports.isValidCoordinates = (latitude, longitude) => {
  const lat = Number(latitude);
  const lon = Number(longitude);
  
  return (
    !isNaN(lat) &&
    !isNaN(lon) &&
    lat >= -90 &&
    lat <= 90 &&
    lon >= -180 &&
    lon <= 180
  );
};

// Validate postal code (Sri Lankan)
exports.isValidPostalCode = (postalCode) => {
  const postalCodePattern = /^[0-9]{5}$/;
  return postalCodePattern.test(postalCode);
};

// Validate NIC (Sri Lankan National Identity Card)
exports.isValidNIC = (nic) => {
  // Old format: 9 digits + V/X
  const oldFormat = /^[0-9]{9}[vVxX]$/;
  // New format: 12 digits
  const newFormat = /^[0-9]{12}$/;
  
  return oldFormat.test(nic) || newFormat.test(nic);
};

// Validate price
exports.isValidPrice = (price) => {
  const num = Number(price);
  return !isNaN(num) && num >= 0;
};

// Validate quantity
exports.isValidQuantity = (quantity) => {
  const num = Number(quantity);
  return Number.isInteger(num) && num > 0;
};

// Validate rating
exports.isValidRating = (rating) => {
  const num = Number(rating);
  return Number.isInteger(num) && num >= 1 && num <= 5;
};

// Validate hex color
exports.isValidHexColor = (color) => {
  const hexPattern = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;
  return hexPattern.test(color);
};

// Sanitize string (remove HTML tags)
exports.sanitizeString = (str) => {
  return str.replace(/<[^>]*>?/gm, '').trim();
};

// Validate username
exports.isValidUsername = (username) => {
  const usernamePattern = /^[a-zA-Z0-9_]{3,20}$/;
  return usernamePattern.test(username);
};

// Validate slug
exports.isValidSlug = (slug) => {
  const slugPattern = /^[a-z0-9-]+$/;
  return slugPattern.test(slug);
};

// Validate credit card number (Luhn algorithm)
exports.isValidCreditCard = (cardNumber) => {
  const cleaned = cardNumber.replace(/\D/g, '');
  
  if (cleaned.length < 13 || cleaned.length > 19) {
    return false;
  }
  
  let sum = 0;
  let isEven = false;
  
  for (let i = cleaned.length - 1; i >= 0; i--) {
    let digit = parseInt(cleaned[i]);
    
    if (isEven) {
      digit *= 2;
      if (digit > 9) {
        digit -= 9;
      }
    }
    
    sum += digit;
    isEven = !isEeven;
  }
  
  return sum % 10 === 0;
};

// Validate IPv4 address
exports.isValidIPv4 = (ip) => {
  const ipv4Pattern = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
  return ipv4Pattern.test(ip);
};

// Validate JSON string
exports.isValidJSON = (str) => {
  try {
    JSON.parse(str);
    return true;
  } catch (e) {
    return false;
  }
};

// Validate age (must be 18+)
exports.isValidAge = (birthDate) => {
  const today = new Date();
  const birth = new Date(birthDate);
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  
  return age >= 18;
};

// Validate array length
exports.isValidArrayLength = (arr, min, max) => {
  return Array.isArray(arr) && arr.length >= min && arr.length <= max;
};

// Validate string length
exports.isValidStringLength = (str, min, max) => {
  return typeof str === 'string' && str.length >= min && str.length <= max;
};

// Check if value is empty
exports.isEmpty = (value) => {
  if (value === null || value === undefined) return true;
  if (typeof value === 'string') return value.trim().length === 0;
  if (Array.isArray(value)) return value.length === 0;
  if (typeof value === 'object') return Object.keys(value).length === 0;
  return false;
};

// Validate enum value
exports.isValidEnum = (value, enumArray) => {
  return enumArray.includes(value);
};
